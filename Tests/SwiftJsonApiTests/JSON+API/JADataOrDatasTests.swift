//
//  JADataOrDatasTests.swift
//
//  Created by Oueway Forest on 11/25/25.
//

import XCTest
@testable import SwiftJsonApi

final class JADataOrDatasTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        MockDatum.register(as: "mock")
    }
    
    func testInitWithSingleData() {
        let singleData = MockDatum(id: "1")
        let dataOrDatas = JADataOrDatas(data: singleData)
        
        XCTAssertEqual(dataOrDatas.array.count, 1)
        XCTAssertEqual(dataOrDatas.array.first?.id, "1")
    }
    
    func testInitWithArray() {
        let data = [
            MockDatum(id: "1"),
            MockDatum(id: "2"),
            MockDatum(id: "3")
        ]
        let dataOrDatas = JADataOrDatas(datas: data)
        
        XCTAssertEqual(dataOrDatas.array.count, 3)
        XCTAssertEqual(dataOrDatas.array[0].id, "1")
        XCTAssertEqual(dataOrDatas.array[1].id, "2")
        XCTAssertEqual(dataOrDatas.array[2].id, "3")
    }
    
    func testEncodeToJSON() throws {
        let singleData = MockDatum(id: "1")
        let dataOrDatas = JADataOrDatas(data: singleData)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encoded = try encoder.encode(dataOrDatas)
        
        XCTAssertNotNil(encoded)
        XCTAssertFalse(encoded.isEmpty)
    }
    
    func testEncodeArrayToJSON() throws {
        let data = [
            MockDatum(id: "1"),
            MockDatum(id: "2")
        ]
        let dataOrDatas = JADataOrDatas(datas: data)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encoded = try encoder.encode(dataOrDatas)
        
        XCTAssertNotNil(encoded)
        XCTAssertFalse(encoded.isEmpty)
    }
}

