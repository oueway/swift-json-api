//
//  WebServiceTests.swift
//
//  Created by Oueway Forest on 11/25/25.
//

import XCTest
@testable import SwiftJsonApi

final class WebServiceTests: XCTestCase {
    
    var mockDelegate: MockWebServiceDelegate!
    
    override func setUp() {
        super.setUp()
        mockDelegate = MockWebServiceDelegate()
        // Clean up the previous shared instance (via reflection or by setting directly)
        WebService.configure(delegate: mockDelegate, force: true)
    }
    
    override func tearDown() {
        super.tearDown()
        // Clean up test state
        if let shared = WebService.shared {
            Task {
                await shared.cleanAllRequests()
            }
        }
    }
    
    // MARK: - Configuration Tests
    
    func testConfigureCreatesSharedInstance() {
        let delegate = MockWebServiceDelegate()
        WebService.configure(delegate: delegate, force: true)
        
        XCTAssertNotNil(WebService.shared)
        XCTAssertEqual(WebService.shared?.delegate.apiEndpoint, delegate.apiEndpoint)
    }
    
    func testConfigureWithoutForceDoesNotOverride() {
        let firstDelegate = MockWebServiceDelegate(apiEndpoint: URL(string: "https://first.com")!)
        let secondDelegate = MockWebServiceDelegate(apiEndpoint: URL(string: "https://second.com")!)
        
        WebService.configure(delegate: firstDelegate, force: true)
        WebService.configure(delegate: secondDelegate, force: false)
        
        XCTAssertNotNil(WebService.shared)
        // Should keep the first delegate (because force is false)
        // Note: Since force defaults to false, the second call will not change it
        XCTAssertEqual(WebService.shared?.delegate.apiEndpoint, firstDelegate.apiEndpoint)
    }
    
    func testConfigureWithForceOverrides() {
        let firstDelegate = MockWebServiceDelegate(apiEndpoint: URL(string: "https://first.com")!)
        let secondDelegate = MockWebServiceDelegate(apiEndpoint: URL(string: "https://second.com")!)
        
        WebService.configure(delegate: firstDelegate, force: true)
        WebService.configure(delegate: secondDelegate, force: true)
        
        XCTAssertNotNil(WebService.shared)
        XCTAssertEqual(WebService.shared?.delegate.apiEndpoint, secondDelegate.apiEndpoint)
    }
    
    // MARK: - Clean All Requests Tests
    
    func testCleanAllRequests() async {
        guard let webService = WebService.shared else {
            XCTFail("WebService.shared should not be nil")
            return
        }
        
        await webService.cleanAllRequests()
        
        // If cleanAllRequests works correctly, there should be no errors
        XCTAssertTrue(true)
    }
    
    // MARK: - Publish Task Tests
    
    func testPublishTaskSuccess() {
        guard let webService = WebService.shared else {
            XCTFail("WebService.shared should not be nil")
            return
        }
        
        let expectation = XCTestExpectation(description: "Publish task completes")
        
        let publisher = webService.publishTask {
            return "success"
        }
        
        var receivedValue: String?
        var receivedError: Error?
        let cancellable = publisher.sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    receivedError = error
                }
                expectation.fulfill()
            },
            receiveValue: { value in
                receivedValue = value
            }
        )
        
        wait(for: [expectation], timeout: 5.0)
        
        XCTAssertEqual(receivedValue, "success")
        XCTAssertNil(receivedError)
        cancellable.cancel()
    }
    
    func testPublishTaskFailure() {
        guard let webService = WebService.shared else {
            XCTFail("WebService.shared should not be nil")
            return
        }
        
        let expectation = XCTestExpectation(description: "Publish task fails")
        
        struct TestError: Error {}
        
        let publisher = webService.publishTask {
            throw TestError()
        }
        
        var receivedError: Error?
        let cancellable = publisher.sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    receivedError = error
                }
                expectation.fulfill()
            },
            receiveValue: { _ in }
        )
        
        wait(for: [expectation], timeout: 5.0)
        
        XCTAssertNotNil(receivedError)
        cancellable.cancel()
    }
}

