//
//  ResourceProtocolTests.swift
//
//  Created by Oueway Forest on 11/28/25.
//

import XCTest
@testable import SwiftJsonApi

final class ResourceProtocolTests: XCTestCase {

    struct RestResource: Decodable, ResourceProtocol, Equatable {
        typealias FilterItem = EmptyFilterItem

        static var resourcePath: String? = "/rest"

        let id: String
        let name: String
    }

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(MockURLProtocol.self)
        let delegate = MockWebServiceDelegate()
        WebService.configure(delegate: delegate, force: true)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        super.tearDown()
    }

    func testGetByIDDecodesSingleResponse() async throws {
        let expected = RestResource(id: "1", name: "Test")
        let responseDict: [String: Any] = ["id": expected.id, "name": expected.name]
        let responseJSON = try JSONSerialization.data(withJSONObject: responseDict, options: [])

        let url = URL(string: "https://api.example.com/rest/1")!

        MockURLProtocol.requestHandler = { request in
            // Ensure method is GET and URL matches
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/rest/1")
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return (response, responseJSON)
        }

        let response: SimpleSingleResponse<RestResource> = try await RestResource.get(byID: "1")
        XCTAssertEqual(response.item, expected)
    }

    func testPostSendsBodyAndQueryFilters() async throws {
        struct Payload: Codable, Equatable { let name: String }
        let payload = Payload(name: "Hello")
        let returned = RestResource(id: "2", name: "Hello")
        let responseDict: [String: Any] = ["id": returned.id, "name": returned.name]
        let responseJSON = try JSONSerialization.data(withJSONObject: responseDict, options: [])

        let url = URL(string: "https://api.example.com/rest")!

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), URLRequest.ContentType.json.rawValue)
            // Body should match the encoded payload
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
            if let data = bodyData, let decoded = try? JSONDecoder.iso8601Standard.decode(Payload.self, from: data) {
                XCTAssertEqual(decoded, payload)
            } else {
                XCTFail("Expected non-nil request body. Headers: \(request.allHTTPHeaderFields ?? [:])")
            }
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return (response, responseJSON)
        }

        let result: SimpleSingleResponse<RestResource> = try await RestResource.post(request: payload)
        XCTAssertEqual(result.item, returned)
    }

    func testPutPathIncludesID() async throws {
        struct Payload: Encodable { let name: String }
        let payload = Payload(name: "Updated")
        let returned = RestResource(id: "3", name: "Updated")
        let responseDict: [String: Any] = ["id": returned.id, "name": returned.name]
        let responseJSON = try JSONSerialization.data(withJSONObject: responseDict, options: [])

        let url = URL(string: "https://api.example.com/rest/3")!

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "PUT")
            XCTAssertEqual(request.url?.path, "/rest/3")
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return (response, responseJSON)
        }

        let result: SimpleSingleResponse<RestResource> = try await RestResource.put(request: payload, id: "3")
        XCTAssertEqual(result.item?.name, returned.name)
    }

    func testDeleteReturnsTrueOn200() async throws {
        let url = URL(string: "https://api.example.com/rest/4")!

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "DELETE")
            let response = HTTPURLResponse(url: url, statusCode: 204, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        let result = try await RestResource.delete(byID: "4")
        XCTAssertTrue(result)
    }
}
