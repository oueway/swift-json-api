//
//  JARelationshipTests.swift
//
//  Created by Oueway Forest on 11/25/25.
//

import XCTest
@testable import SwiftJsonApi

final class JARelationshipTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        MockDatum.register(as: "mock")
    }
    
    // MARK: - Initialization Tests
    
    func testEmptyRelationship() {
        let relationship = JARelationship<MockDatum>.empty
        
        XCTAssertNil(relationship.data)
        XCTAssertNil(relationship.links)
        XCTAssertNil(relationship.datums)
    }
    
    func testInitWithDataAndLinks() {
        let data = JARelationship<MockDatum>._Data(id: "1", type: "mock")
        let dataOrDatas = JADataOrDatas(data: data)
        let links = JARelationship<MockDatum>.Links(linksSelf: "https://api.example.com/mock/1/relationships/related", related: "https://api.example.com/mock/1/related")
        
        let relationship = JARelationship<MockDatum>(
            data: dataOrDatas,
            links: links,
            datums: nil
        )
        
        XCTAssertNotNil(relationship.data)
        XCTAssertNotNil(relationship.links)
        XCTAssertEqual(relationship.links?.linksSelf, "https://api.example.com/mock/1/relationships/related")
        XCTAssertEqual(relationship.links?.related, "https://api.example.com/mock/1/related")
        XCTAssertNil(relationship.datums)
    }
    
    func testInitWithDatums() {
        let datum1 = MockDatum(id: "1")
        let datum2 = MockDatum(id: "2")
        let datums = [datum1, datum2]
        
        let relationship = JARelationship<MockDatum>(
            data: nil,
            links: nil,
            datums: datums
        )
        
        XCTAssertNil(relationship.data)
        XCTAssertNil(relationship.links)
        XCTAssertNotNil(relationship.datums)
        XCTAssertEqual(relationship.datums?.count, 2)
        XCTAssertEqual(relationship.datums?[0].id, "1")
        XCTAssertEqual(relationship.datums?[1].id, "2")
    }
    
    // MARK: - Resolve Relationship Tests
    
    func testResolveRelationshipFromIncludes() {
        let data = JARelationship<MockDatum>._Data(id: "1", type: "mock")
        let dataOrDatas = JADataOrDatas(data: data)
        
        let relationship = JARelationship<MockDatum>(
            data: dataOrDatas,
            links: nil,
            datums: nil
        )
        
        let includedDatum = MockDatum(id: "1", attributes: MockDatum.Attributes(name: "resolved", value: 200))
        let includes: [String: [JAAnyDatum]] = ["mock": [includedDatum]]
        
        let resolved = relationship.resolved(fromIncludes: includes)
        
        XCTAssertNotNil(resolved)
        XCTAssertEqual(resolved?.datums?.count, 1)
        XCTAssertEqual(resolved?.datums?.first?.id, "1")
        XCTAssertEqual(resolved?.datums?.first?.attributes.name, "resolved")
    }
    
    func testResolveRelationshipWithNoMatchingIncludes() {
        let data = JARelationship<MockDatum>._Data(id: "1", type: "mock")
        let dataOrDatas = JADataOrDatas(data: data)
        
        let relationship = JARelationship<MockDatum>(
            data: dataOrDatas,
            links: nil,
            datums: nil
        )
        
        let includes: [String: [JAAnyDatum]] = ["mock": []]
        
        let resolved = relationship.resolved(fromIncludes: includes)
        
        XCTAssertNil(resolved)
    }
    
    func testResolveRelationshipWithDifferentType() {
        let data = JARelationship<MockDatum>._Data(id: "1", type: "mock")
        let dataOrDatas = JADataOrDatas(data: data)
        
        let relationship = JARelationship<MockDatum>(
            data: dataOrDatas,
            links: nil,
            datums: nil
        )
        
        let includes: [String: [JAAnyDatum]] = ["other": []]
        
        let resolved = relationship.resolved(fromIncludes: includes)
        
        XCTAssertNil(resolved)
    }
    
    func testResolveRelationshipWithMultipleIncludes() {
        let data1 = JARelationship<MockDatum>._Data(id: "1", type: "mock")
        let data2 = JARelationship<MockDatum>._Data(id: "2", type: "mock")
        let dataOrDatas = JADataOrDatas(datas: [data1, data2])
        
        let relationship = JARelationship<MockDatum>(
            data: dataOrDatas,
            links: nil,
            datums: nil
        )
        
        let includedDatum1 = MockDatum(id: "1")
        let includedDatum2 = MockDatum(id: "2")
        let includes: [String: [JAAnyDatum]] = ["mock": [includedDatum1, includedDatum2]]
        
        let resolved = relationship.resolved(fromIncludes: includes)
        
        XCTAssertNotNil(resolved)
        XCTAssertEqual(resolved?.datums?.count, 2)
    }
    
    func testResolveRelationshipPreservesDataAndLinks() {
        let data = JARelationship<MockDatum>._Data(id: "1", type: "mock")
        let dataOrDatas = JADataOrDatas(data: data)
        let links = JARelationship<MockDatum>.Links(linksSelf: "https://api.example.com/self", related: "https://api.example.com/related")
        
        let relationship = JARelationship<MockDatum>(
            data: dataOrDatas,
            links: links,
            datums: nil
        )
        
        let includedDatum = MockDatum(id: "1")
        let includes: [String: [JAAnyDatum]] = ["mock": [includedDatum]]
        
        let resolved = relationship.resolved(fromIncludes: includes)
        
        XCTAssertNotNil(resolved)
        XCTAssertEqual(resolved?.data?.array.first?.id, "1")
        XCTAssertEqual(resolved?.links?.linksSelf, "https://api.example.com/self")
        XCTAssertEqual(resolved?.links?.related, "https://api.example.com/related")
    }
}

