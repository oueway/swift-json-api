//
//  ListProtocolTests.swift
//
//  Created by Oueway Forest on 11/28/25.
//

@testable import SwiftJsonApi
import XCTest

final class ListProtocolTests: XCTestCase {
    enum Filter: FilterItemProtocol {
        case assignee(String)
        enum Key: String, CaseIterable, StringRawRepresentable {
            case assignee
            var rawValue: String { "assignee" }
            init?(_ rawValue: String) { self = .assignee }
        }
    }

    struct Resource: Decodable, ListProtocol, Equatable {
        typealias FilterItem = Filter
        static var resourcePath: String? = "/tasks"
        // keep defaults: supportPagination true, filterMethod .query

        let id: String
        let title: String
    }

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        super.tearDown()
    }

    func testListQueryAddsFilterAsQueryItems() async throws {
        let delegate = MockWebServiceDelegate(paginationParams: nil)
        WebService.configure(delegate: delegate, force: true)

        let item = Resource(id: "1", title: "One")
        let responseDict = [["id": item.id, "title": item.title]]
        let responseJSON = try JSONSerialization.data(withJSONObject: responseDict, options: [])

        let url = URL(string: "https://api.example.com/tasks")!

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            // Query should contain a query item with name = filter[assignee] and value = octocat
            let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            let items = components?.queryItems ?? []
            XCTAssertTrue(items.contains(where: { $0.name.contains("assignee") && $0.value == "octocat" }))
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return (response, responseJSON)
        }

        let filters: [Filter] = [.assignee("octocat")]
        let result: SimpleListResponse<Resource> = try await Resource.list(filters: filters)
        XCTAssertEqual(result.items.first?.id, item.id)
    }

    func testListAddsPaginationWhenSupportEnabledAndParamsAvailable() async throws {
        let delegate = MockWebServiceDelegate(paginationParams: PaginationParams.offsetLimit)
        WebService.configure(delegate: delegate, force: true)

        let item = Resource(id: "1", title: "Alpha")
        let responseDict = [["id": item.id, "title": item.title]]
        let responseJSON = try JSONSerialization.data(withJSONObject: responseDict, options: [])

        let url = URL(string: "https://api.example.com/tasks")!

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            // should contain offset & limit when pagination is enabled
            XCTAssertTrue(request.url?.query?.contains("offset=2") ?? false)
            XCTAssertTrue(request.url?.query?.contains("limit=10") ?? false)
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return (response, responseJSON)
        }

        let result: SimpleListResponse<Resource> = try await Resource.list(filters: nil, pageIndex: 2, pageSize: 10)
        XCTAssertEqual(result.items.count, 1)
    }

    func testPostFormFilterEncodesFormBody() async throws {
        struct PostResource: Decodable, ListProtocol, Equatable {
            typealias FilterItem = Filter
            static var resourcePath: String? = "/tasks"
            static var filterMethod: ListFilterMethod { .postForm }

            let id: String
            let title: String
        }

        let delegate = MockWebServiceDelegate(paginationParams: nil)
        WebService.configure(delegate: delegate, force: true)

        let item = PostResource(id: "1", title: "FormTest")
        let responseDict = [["id": item.id, "title": item.title]]
        let responseJSON = try JSONSerialization.data(withJSONObject: responseDict, options: [])

        let url = URL(string: "https://api.example.com/tasks")!
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), URLRequest.ContentType.formUrlEncoded.rawValue)
            // Body may be in httpBody or stream
            var bodyString: String? = nil
            if let body = request.httpBody {
                bodyString = String(data: body, encoding: .utf8)
            } else if let stream = request.httpBodyStream {
                stream.open()
                let bufferSize = 1024
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
                var data = Data()
                while stream.hasBytesAvailable {
                    let read = stream.read(buffer, maxLength: bufferSize)
                    if read <= 0 { break }
                    data.append(buffer, count: read)
                }
                buffer.deallocate()
                stream.close()
                bodyString = String(data: data, encoding: .utf8)
            }
            XCTAssertNotNil(bodyString)
            // decode the body as query items so we can assert key/value pairs safely
            let queryComponents = URLComponents(string: "?\(bodyString!)")
            let bodyItems = queryComponents?.queryItems ?? []
            XCTAssertTrue(bodyItems.contains(where: { $0.name.contains("assignee") && $0.value == "octocat" }))
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseJSON)
        }

        let result: SimpleListResponse<PostResource> = try await PostResource.list(filters: [.assignee("octocat")])
        XCTAssertEqual(result.items.first?.id, item.id)
    }

    func testPostJsonEncodesJsonBody() async throws {
        struct JsonResource: Decodable, ListProtocol, Equatable {
            typealias FilterItem = Filter
            static var resourcePath: String? = "/tasks"
            static var filterMethod: ListFilterMethod { .postJson }

            let id: String
            let title: String
        }

        let delegate = MockWebServiceDelegate(paginationParams: nil)
        WebService.configure(delegate: delegate, force: true)

        let item = JsonResource(id: "1", title: "JsonTest")
        let responseDict = [["id": item.id, "title": item.title]]
        let responseJSON = try JSONSerialization.data(withJSONObject: responseDict, options: [])

        let url = URL(string: "https://api.example.com/tasks")!
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), URLRequest.ContentType.json.rawValue)

            var bodyData: Data?
            if let body = request.httpBody {
                bodyData = body
            } else if let stream = request.httpBodyStream {
                stream.open()
                let bufferSize = 1024
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
                var data = Data()
                while stream.hasBytesAvailable {
                    let read = stream.read(buffer, maxLength: bufferSize)
                    if read <= 0 { break }
                    data.append(buffer, count: read)
                }
                buffer.deallocate()
                stream.close()
                bodyData = data
            }
            if let data = bodyData, let obj = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] {
                XCTAssertTrue(obj.keys.contains(where: { $0.contains("assignee") }))
            } else {
                XCTFail("Expected body")
            }

            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseJSON)
        }

        let result: SimpleListResponse<JsonResource> = try await JsonResource.list(filters: [.assignee("octocat")])
        XCTAssertEqual(result.items.first?.id, item.id)
    }
}
