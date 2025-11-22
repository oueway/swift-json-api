//
//  MyErrorTests.swift
//
//  Created by Oueway Forest on 11/25/25.
//

import XCTest
@testable import SwiftJsonApi

final class MyErrorTests: XCTestCase {
    
    // MARK: - Error Description Tests
    
    func testUserSwitchedErrorDescription() {
        let error = MyError.userSwitched
        XCTAssertEqual(error.errorDescription, "User Changed.")
    }
    
    func testUnknownErrorDescription() {
        let error = MyError.unknown
        XCTAssertEqual(error.errorDescription, "Unknown error.")
    }
    
    func testLocalErrorDescription() {
        let message = "Local error message"
        let error = MyError.local(message)
        XCTAssertEqual(error.errorDescription, message)
    }
    
    func testAppErrorDescription() {
        let message = "App error message"
        let error = MyError.app(message)
        XCTAssertEqual(error.errorDescription, "App Error: \(message)")
    }
    
    func testStorageErrorDescription() {
        let message = "Storage error message"
        let error = MyError.storage(message)
        XCTAssertEqual(error.errorDescription, "Storage Error: \(message)")
    }
    
    func testServerErrorDescription() {
        let message = "Server error message"
        let error = MyError.server(message)
        XCTAssertEqual(error.errorDescription, "Server Error: \(message)")
    }
    
    func testUnderlayerErrorDescription() {
        let underlyingError = NSError(domain: "test", code: 123, userInfo: [NSLocalizedDescriptionKey: "Underlying error"])
        let error = MyError.underlayer(underlyingError)
        
        XCTAssertEqual(error.errorDescription, underlyingError.localizedDescription)
    }
    
    func testUnderlayersErrorDescription() {
        let error1 = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error 1"])
        let error2 = NSError(domain: "test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Error 2"])
        let error = MyError.underlayers([error1, error2])
        
        let description = error.errorDescription ?? ""
        XCTAssertTrue(description.contains("Error 1"))
        XCTAssertTrue(description.contains("Error 2"))
    }
    
    func testUnderlayerWithCodeErrorDescription() {
        let nsError = NSError(code: 404, message: "Not found")
        let error = MyError.underlayerWithCode(nsError)
        
        let description = error.errorDescription ?? ""
        XCTAssertTrue(description.contains("404"))
        XCTAssertTrue(description.contains("Not found"))
    }
    
    // MARK: - Failure Reason Tests
    
    func testFailureReasonForUnderlayerError() {
        let underlyingError = NSError(
            domain: "test",
            code: 123,
            userInfo: [
                NSLocalizedFailureReasonErrorKey: "Failure reason"
            ]
        )
        let error = MyError.underlayer(underlyingError)
        
        XCTAssertEqual(error.failureReason, "Failure reason")
    }
    
    func testFailureReasonForNonUnderlayerError() {
        let error = MyError.local("Test error")
        XCTAssertEqual(error.failureReason, "Test error")
    }
    
    // MARK: - Static Error Tests
    
    func testEncodeRequestFailure() {
        let error = MyError.encodeRequestFailure
        XCTAssertEqual(error.errorDescription, "App Error: Can not encode your request.")
    }
    
    // MARK: - NSError Extension Tests
    
    func testNSErrorInitWithHTTPURLResponse() {
        let url = URL(string: "https://api.example.com/test")!
        let response = HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)
        let nsError = NSError(httpUrlResponse: response, message: "Not found")
        
        XCTAssertEqual(nsError.code, 404)
        XCTAssertTrue(nsError.localizedDescription.contains("https://api.example.com/test"))
        XCTAssertTrue(nsError.localizedDescription.contains("Not found"))
    }
    
    func testNSErrorInitWithCode() {
        let nsError = NSError(code: 500, message: "Internal server error")
        
        XCTAssertEqual(nsError.code, 500)
        XCTAssertEqual(nsError.localizedDescription, "Internal server error")
    }
    
    func testNSErrorInitWithNilCode() {
        let nsError = NSError(code: nil, message: "Error message")
        
        XCTAssertEqual(nsError.code, -1)
        XCTAssertEqual(nsError.localizedDescription, "Error message")
    }
}

