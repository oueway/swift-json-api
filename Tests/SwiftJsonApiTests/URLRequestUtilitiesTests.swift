//
//  URLRequestUtilitiesTests.swift
//
//  Created by Oueway Forest on 11/25/25.
//

import XCTest
@testable import SwiftJsonApi

final class URLRequestUtilitiesTests: XCTestCase {
    
    var mockDelegate: MockWebServiceDelegate!
    
    override func setUp() {
        super.setUp()
        mockDelegate = MockWebServiceDelegate()
        WebService.configure(delegate: mockDelegate, force: true)
    }
    
    // MARK: - URL Creation Tests
    
    func testURLFromPath() {
        let url = URL.urlFromPath("/test/path")
        
        XCTAssertNotNil(url)
        XCTAssertTrue(url.absoluteString.contains("/test/path"))
        XCTAssertTrue(url.absoluteString.contains(mockDelegate.apiEndpoint.absoluteString))
    }
    
    func testURLFromPathWithQueryItems() {
        let queryItems = [
            URLQueryItem(name: "filter", value: "test"),
            URLQueryItem(name: "page", value: "1")
        ]
        let url = URL.urlFromPath("/test/path", queryItems: queryItems)
        
        XCTAssertNotNil(url)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        XCTAssertNotNil(components?.queryItems)
        XCTAssertTrue(components?.queryItems?.contains(where: { $0.name == "filter" && $0.value == "test" }) ?? false)
        XCTAssertTrue(components?.queryItems?.contains(where: { $0.name == "page" && $0.value == "1" }) ?? false)
    }
    
    func testURLFromPathWithNilQueryItems() {
        let url = URL.urlFromPath("/test/path", queryItems: nil)
        
        XCTAssertNotNil(url)
    }
    
    // MARK: - URLRequest Creation Tests
    
    func testGetRequest() {
        let url = URL(string: "https://api.example.com/test")!
        let request = URLRequest.get(from: url)
        
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url, url)
        XCTAssertNotNil(request.value(forHTTPHeaderField: "Authorization"))
        XCTAssertNotNil(request.value(forHTTPHeaderField: "Accept"))
    }
    
    func testPostRequest() {
        let url = URL(string: "https://api.example.com/test")!
        let data = "test data".data(using: .utf8)!
        let request = URLRequest.post(to: url, data: data)
        
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.httpBody, data)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json;charset=UTF-8")
    }
    
    func testPutRequest() {
        let url = URL(string: "https://api.example.com/test")!
        let data = "test data".data(using: .utf8)!
        let request = URLRequest.put(to: url, data: data)
        
        XCTAssertEqual(request.httpMethod, "PUT")
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.httpBody, data)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json;charset=UTF-8")
    }
    
    func testDeleteRequest() {
        let url = URL(string: "https://api.example.com/test")!
        let request = URLRequest.delete(from: url)
        
        XCTAssertEqual(request.httpMethod, "DELETE")
        XCTAssertEqual(request.url, url)
    }
    
    func testPostRequestWithFormUrlEncoded() {
        let url = URL(string: "https://api.example.com/test")!
        let data = "test=data".data(using: .utf8)!
        let request = URLRequest.post(to: url, data: data, contentType: .formUrlEncoded)
        
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded")
    }
    
    func testPostRequestWithCustomAuthorization() {
        let url = URL(string: "https://api.example.com/test")!
        let data = Data()
        let request = URLRequest.post(to: url, data: data, authorization: "Bearer custom-token")
        
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer custom-token")
    }
    
    // MARK: - Unique ID Tests
    
    func testUniqueIDWithoutBody() {
        let url = URL(string: "https://api.example.com/test")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpBody = nil
        
        let uniqueID = request.uniqueID
        
        XCTAssertEqual(uniqueID, url.absoluteString)
    }
    
    func testUniqueIDWithBody() {
        let url = URL(string: "https://api.example.com/test")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let body = "test body".data(using: .utf8)!
        request.httpBody = body
        
        let uniqueID = request.uniqueID
        
        XCTAssertTrue(uniqueID.hasPrefix(url.absoluteString))
        XCTAssertTrue(uniqueID.count > url.absoluteString.count) // 应该包含 MD5 hash
    }
    
    func testUniqueIDWithDifferentBodies() {
        let url = URL(string: "https://api.example.com/test")!
        
        var request1 = URLRequest(url: url)
        request1.httpBody = "body1".data(using: .utf8)!
        
        var request2 = URLRequest(url: url)
        request2.httpBody = "body2".data(using: .utf8)!
        
        let uniqueID1 = request1.uniqueID
        let uniqueID2 = request2.uniqueID
        
        XCTAssertNotEqual(uniqueID1, uniqueID2)
    }
    
    // MARK: - Form Data Tests
    
    func testFormDataWithQueryItems() throws {
        let queryItems = [
            URLQueryItem(name: "key1", value: "value1"),
            URLQueryItem(name: "key2", value: "value2")
        ]
        
        let formData = try URLRequest.formData(withQueryItems: queryItems)
        
        XCTAssertNotNil(formData)
        XCTAssertFalse(formData.isEmpty)
        let formString = String(data: formData, encoding: .utf8)
        XCTAssertNotNil(formString)
        XCTAssertTrue(formString!.contains("key1=value1"))
        XCTAssertTrue(formString!.contains("key2=value2"))
    }
}

