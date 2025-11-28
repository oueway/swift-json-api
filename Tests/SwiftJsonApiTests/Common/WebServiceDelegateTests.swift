import XCTest
@testable import SwiftJsonApi

// MARK: - Test API Error type
struct SimpleApiError: Error, Decodable, Equatable {
    let message: String
}

final class WebServiceDelegateTests: XCTestCase {

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        super.tearDown()
    }

    func testPaginationParamsPresets() {
        XCTAssertEqual(PaginationParams.offsetLimit.indexKey, "offset")
        XCTAssertEqual(PaginationParams.offsetLimit.sizeKey, "limit")

        XCTAssertEqual(PaginationParams.cursorLimit.indexKey, "cursor")
        XCTAssertEqual(PaginationParams.cursorLimit.sizeKey, "limit")

        XCTAssertEqual(PaginationParams.indexSize.indexKey, "index")
        XCTAssertEqual(PaginationParams.indexSize.sizeKey, "size")

        XCTAssertEqual(PaginationParams.pageIndexSize.indexKey, "page")
        XCTAssertEqual(PaginationParams.pageIndexSize.sizeKey, "size")

        XCTAssertEqual(PaginationParams.default.indexKey, PaginationParams.offsetLimit.indexKey)
        XCTAssertEqual(PaginationParams.default.sizeKey, PaginationParams.offsetLimit.sizeKey)
    }

    func testURLRequestIncludesAdditionalHeadersAndAuthorization() {
        let delegate = MockWebServiceDelegate(
            apiEndpoint: URL(string: "https://api.example.com/")!,
            accessToken: "abc123",
            isTokenExpired: false,
            paginationParams: nil,
            additionalHeaders: ["X-Custom": "custom-value", "Authorization": "Bearer override"],
            apiErrorType: JAError.self
        )

        WebService.configure(delegate: delegate, force: true)

        let url = URL(string: "https://api.example.com/tasks")!
        let request = URLRequest.get(from: url)

        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Custom"), "custom-value")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer override")
        // Default Accept header should match ContentType.json.rawValue
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), URLRequest.ContentType.json.rawValue)
    }

    func testApiErrorTypeDecodingFromHttpError() async throws {
        let delegate = MockWebServiceDelegate(
            apiEndpoint: URL(string: "https://api.example.com/")!,
            accessToken: "token",
            isTokenExpired: false,
            paginationParams: nil,
            additionalHeaders: nil,
            apiErrorType: SimpleApiError.self
        )

        WebService.configure(delegate: delegate, force: true)

        // Prepare a stubbed 400 response with a SimpleApiError payload
        let url = URL(string: "https://api.example.com/err")!
        let _ = try JSONEncoder().encode(["message": "Bad request"]) // wrong: we want a single object

        // Use a readable JSON (SimpleApiError uses "message" key)
        let data = try JSONSerialization.data(withJSONObject: ["message": "Oops"], options: [])

        // Setup the protocol to return a 400 response for that URL
        MockURLProtocol.requestHandler = { request in
            guard request.url == url else {
                return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data())
            }

            let response = HTTPURLResponse(url: url, statusCode: 400, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return (response, data)
        }

        let request = URLRequest.get(from: url)

        do {
            _ = try await WebService.shared?.booleanTask(with: request)
            XCTFail("Expected error to be thrown")
        } catch {
            guard let jsonError = error as? MyError else {
                XCTFail("Expected MyError, got: \(error)")
                return
            }

            switch jsonError {
            case .underlayer(let underlying):
                // underlying should be SimpleApiError
                XCTAssertTrue(type(of: underlying) == SimpleApiError.self || underlying is SimpleApiError)
            default:
                XCTFail("Expected underlayer MyError, got: \(jsonError)")
            }
        }
    }
}

// MARK: - Mock URL Protocol

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        // Intercept all requests
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Handler is not set")
        }

        let (response, data) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        // No-op
    }
}
