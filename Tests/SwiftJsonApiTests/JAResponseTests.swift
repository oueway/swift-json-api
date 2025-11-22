//
//  JAResponseTests.swift
//
//  Created by Oueway Forest on 11/25/25.
//

import XCTest
@testable import SwiftJsonApi

final class JAResponseTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testEmptyResponse() {
        let response = JAResponse<MockDatum>.empty
        
        XCTAssertEqual(response.datums.count, 0)
        XCTAssertNil(response.included)
        XCTAssertNotNil(response.links)
        XCTAssertNil(response.meta)
    }
    
    func testInitWithData() {
        let datum = MockDatum(id: "1")
        let response = JAResponse(data: [datum], included: nil, links: nil, meta: nil)
        
        XCTAssertEqual(response.datums.count, 1)
        XCTAssertEqual(response.datums.first?.id, "1")
        XCTAssertNil(response.included)
        XCTAssertNil(response.links)
        XCTAssertNil(response.meta)
    }
    
    func testDatumsComputedProperty() {
        let data = [
            MockDatum(id: "1"),
            MockDatum(id: "2"),
            MockDatum(id: "3")
        ]
        let response = JAResponse(data: data, included: nil, links: nil, meta: nil)
        
        XCTAssertEqual(response.datums.count, 3)
        XCTAssertEqual(response.datums.map { $0.id }, ["1", "2", "3"])
    }
    
    // MARK: - Links Tests
    
    func testLinksEmpty() {
        let links = JAResponse<MockDatum>.Links.empty
        
        XCTAssertNil(links.linksSelf)
        XCTAssertNil(links.related)
        XCTAssertNil(links.first)
        XCTAssertNil(links.last)
        XCTAssertNil(links.next)
        XCTAssertNil(links.prev)
    }
    
    func testLinksInit() {
        let links = JAResponse<MockDatum>.Links(
            linksSelf: "https://api.example.com/mock",
            related: "https://api.example.com/related",
            first: "https://api.example.com/mock?page=1",
            last: "https://api.example.com/mock?page=10",
            next: "https://api.example.com/mock?page=2",
            prev: nil
        )
        
        XCTAssertEqual(links.linksSelf, "https://api.example.com/mock")
        XCTAssertEqual(links.related, "https://api.example.com/related")
        XCTAssertEqual(links.first, "https://api.example.com/mock?page=1")
        XCTAssertEqual(links.last, "https://api.example.com/mock?page=10")
        XCTAssertEqual(links.next, "https://api.example.com/mock?page=2")
        XCTAssertNil(links.prev)
    }
    
    // MARK: - Meta Tests
    
    func testMetaInit() {
        let meta = JAResponse<MockDatum>.Meta(totalResourceCount: 100)
        
        XCTAssertEqual(meta.totalResourceCount, 100)
    }
    
    // MARK: - Next Page Request Tests
    
    func testNextPageRequestWithValidURL() {
        let links = JAResponse<MockDatum>.Links(
            linksSelf: nil,
            related: nil,
            first: nil,
            last: nil,
            next: "https://api.example.com/mock?page=2",
            prev: nil
        )
        let response = JAResponse<MockDatum>(
            data: [],
            included: nil,
            links: links,
            meta: nil
        )
        
        let nextPageRequest = response.nextPageRequest
        
        XCTAssertNotNil(nextPageRequest)
        XCTAssertEqual(nextPageRequest?.url?.absoluteString, "https://api.example.com/mock?page=2")
        XCTAssertEqual(nextPageRequest?.httpMethod, "GET")
    }
    
    func testNextPageRequestWithNilNext() {
        let links = JAResponse<MockDatum>.Links.empty
        let response = JAResponse<MockDatum>(
            data: [],
            included: nil,
            links: links,
            meta: nil
        )
        
        let nextPageRequest = response.nextPageRequest
        
        XCTAssertNil(nextPageRequest)
    }
    
    func testNextPageRequestWithInvalidURL() {
        let links = JAResponse<MockDatum>.Links(
            linksSelf: nil,
            related: nil,
            first: nil,
            last: nil,
            next: "invalid-url",
            prev: nil
        )
        let response = JAResponse<MockDatum>(
            data: [],
            included: nil,
            links: links,
            meta: nil
        )
        
        let nextPageRequest = response.nextPageRequest
        
        XCTAssertNil(nextPageRequest)
    }
    
    // MARK: - Appending Tests
    
    func testAppendingResponses() {
        let firstDatum = MockDatum(id: "1")
        let secondDatum = MockDatum(id: "2")
        
        let firstResponse = JAResponse<MockDatum>(
            data: [firstDatum],
            included: nil,
            links: JAResponse.Links(
                linksSelf: "https://api.example.com/mock?page=1",
                related: nil,
                first: "https://api.example.com/mock?page=1",
                last: nil,
                next: "https://api.example.com/mock?page=2",
                prev: nil
            ),
            meta: JAResponse.Meta(totalResourceCount: 10)
        )
        
        let secondResponse = JAResponse<MockDatum>(
            data: [secondDatum],
            included: nil,
            links: JAResponse.Links(
                linksSelf: "https://api.example.com/mock?page=2",
                related: nil,
                first: nil,
                last: "https://api.example.com/mock?page=10",
                next: "https://api.example.com/mock?page=3",
                prev: "https://api.example.com/mock?page=1"
            ),
            meta: JAResponse.Meta(totalResourceCount: 10)
        )
        
        let appendedResponse = firstResponse.appending(secondResponse)
        
        XCTAssertEqual(appendedResponse.datums.count, 2)
        XCTAssertEqual(appendedResponse.datums[0].id, "1")
        XCTAssertEqual(appendedResponse.datums[1].id, "2")
        XCTAssertEqual(appendedResponse.links?.first, "https://api.example.com/mock?page=1")
        XCTAssertEqual(appendedResponse.links?.last, "https://api.example.com/mock?page=10")
        XCTAssertEqual(appendedResponse.links?.next, "https://api.example.com/mock?page=3")
        XCTAssertEqual(appendedResponse.links?.prev, nil)
        XCTAssertEqual(appendedResponse.meta?.totalResourceCount, 10)
    }
    
    func testAppendingWithIncludedResources() {
        // 注册 MockDatum 类型以便创建 JADynamicDatum
        MockDatum.register(as: "mock")
        
        let firstDatum = MockDatum(id: "1")
        let firstIncluded = try! JSONDecoder().decode(
            JADynamicDatum.self,
            from: JSONTestData.singleDatumJSON.data(using: .utf8)!
        )
        
        let secondDatum = MockDatum(id: "2")
        let secondIncluded = try! JSONDecoder().decode(
            JADynamicDatum.self,
            from: JSONTestData.singleDatumJSON.data(using: .utf8)!
        )
        
        let firstResponse = JAResponse<MockDatum>(
            data: [firstDatum],
            included: [firstIncluded],
            links: nil,
            meta: nil
        )
        
        let secondResponse = JAResponse<MockDatum>(
            data: [secondDatum],
            included: [secondIncluded],
            links: nil,
            meta: nil
        )
        
        let appendedResponse = firstResponse.appending(secondResponse)
        
        XCTAssertEqual(appendedResponse.datums.count, 2)
        XCTAssertNotNil(appendedResponse.included)
        XCTAssertEqual(appendedResponse.included?.count, 2)
    }
    
    func testAppendingWithNilIncludedInFirst() {
        MockDatum.register(as: "mock")
        
        let firstDatum = MockDatum(id: "1")
        let secondDatum = MockDatum(id: "2")
        let secondIncluded = try! JSONDecoder().decode(
            JADynamicDatum.self,
            from: JSONTestData.singleDatumJSON.data(using: .utf8)!
        )
        
        let firstResponse = JAResponse<MockDatum>(
            data: [firstDatum],
            included: nil,
            links: nil,
            meta: nil
        )
        
        let secondResponse = JAResponse<MockDatum>(
            data: [secondDatum],
            included: [secondIncluded],
            links: nil,
            meta: nil
        )
        
        let appendedResponse = firstResponse.appending(secondResponse)
        
        XCTAssertEqual(appendedResponse.datums.count, 2)
        XCTAssertNotNil(appendedResponse.included)
        XCTAssertEqual(appendedResponse.included?.count, 1)
    }
    
    func testAppendingWithNilIncludedInSecond() {
        MockDatum.register(as: "mock")
        
        let firstDatum = MockDatum(id: "1")
        let firstIncluded = try! JSONDecoder().decode(
            JADynamicDatum.self,
            from: JSONTestData.singleDatumJSON.data(using: .utf8)!
        )
        let secondDatum = MockDatum(id: "2")
        
        let firstResponse = JAResponse<MockDatum>(
            data: [firstDatum],
            included: [firstIncluded],
            links: nil,
            meta: nil
        )
        
        let secondResponse = JAResponse<MockDatum>(
            data: [secondDatum],
            included: nil,
            links: nil,
            meta: nil
        )
        
        let appendedResponse = firstResponse.appending(secondResponse)
        
        XCTAssertEqual(appendedResponse.datums.count, 2)
        XCTAssertNotNil(appendedResponse.included)
        XCTAssertEqual(appendedResponse.included?.count, 1)
    }
    
    // MARK: - Mapped Includes Tests
    
    func testMappedIncludes() {
        MockDatum.register(as: "mock")
        
        let included1 = try! JSONDecoder().decode(
            JADynamicDatum.self,
            from: JSONTestData.singleDatumJSON.data(using: .utf8)!
        )
        
        let response = JAResponse<MockDatum>(
            data: [],
            included: [included1],
            links: nil,
            meta: nil
        )
        
        let mappedIncludes = response.mappedIncludes
        
        XCTAssertNotNil(mappedIncludes)
        XCTAssertEqual(mappedIncludes?["mock"]?.count, 1)
    }
    
    func testMappedIncludesWithNil() {
        let response = JAResponse<MockDatum>(
            data: [],
            included: nil,
            links: nil,
            meta: nil
        )
        
        let mappedIncludes = response.mappedIncludes
        
        XCTAssertNil(mappedIncludes)
    }
}

