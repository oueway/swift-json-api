//
//  JAFilterItemProtocolTests.swift
//
//  Created by Oueway Forest on 11/25/25.
//

import XCTest
@testable import SwiftJsonApi

// MARK: - Test Filter Items

enum TestFilterItem: JAFilterItemProtocol {
    case name(String)
    case age(Int)
    case active(Bool)
    
    enum Key: String, JAFilterItemProtocol.KeyProtocol {
        case name
        case age
        case active
    }
}

enum TestFilterItemWithCustomKey: JAFilterItemProtocol {
    case search(String)
    case dateRange(startDate: Date, endDate: Date)
    
    enum Key: String, JAFilterItemProtocol.KeyProtocol {
        case search = "search.keyword"
        case dateRangeStartDate = "startDate"
        case dateRangeEndDate = "endDate"
    }
}

enum TestFilterItemWithEnumValue: JAFilterItemProtocol {
    case status(Status)
    
    enum Status: String, FilterItemEnumValue {
        case active = "Active"
        case inactive = "Inactive"
    }
    
    enum Key: String, JAFilterItemProtocol.KeyProtocol {
        case status
    }
}

final class JAFilterItemProtocolTests: XCTestCase {
    
    // MARK: - Basic Filter Item Tests
    
    func testStringFilterItem() {
        let filter = TestFilterItem.name("test")
        let queries = filter.queries
        
        XCTAssertEqual(queries.count, 1)
        XCTAssertEqual(queries.first?.name, "filter[name]")
        XCTAssertEqual(queries.first?.value, "test")
    }
    
    func testIntFilterItem() {
        let filter = TestFilterItem.age(25)
        let queries = filter.queries
        
        XCTAssertEqual(queries.count, 1)
        XCTAssertEqual(queries.first?.name, "filter[age]")
        XCTAssertEqual(queries.first?.value, "25")
    }
    
    func testBoolFilterItem() {
        let filter = TestFilterItem.active(true)
        let queries = filter.queries
        
        XCTAssertEqual(queries.count, 1)
        XCTAssertEqual(queries.first?.name, "filter[active]")
        XCTAssertEqual(queries.first?.value, "true")
    }
    
    // MARK: - Custom Key Tests
    
    func testFilterItemWithCustomKey() {
        let filter = TestFilterItemWithCustomKey.search("keyword")
        let queries = filter.queries
        
        XCTAssertEqual(queries.count, 1)
        XCTAssertEqual(queries.first?.name, "filter[search.keyword]")
        XCTAssertEqual(queries.first?.value, "keyword")
    }
    
    // MARK: - Multiple Parameters Tests
    
    func testFilterItemWithMultipleParameters() {
        let startDate = Date(timeIntervalSince1970: 1609459200) // 2021-01-01
        let endDate = Date(timeIntervalSince1970: 1612137600)   // 2021-02-01
        
        let filter = TestFilterItemWithCustomKey.dateRange(startDate: startDate, endDate: endDate)
        let queries = filter.queries
        
        XCTAssertEqual(queries.count, 2)
        
        let startQuery = queries.first { $0.name == "filter[startDate]" }
        let endQuery = queries.first { $0.name == "filter[endDate]" }
        
        XCTAssertNotNil(startQuery)
        XCTAssertNotNil(endQuery)
        XCTAssertNotNil(startQuery?.value)
        XCTAssertNotNil(endQuery?.value)
    }
    
    // MARK: - Array of Filter Items Tests
    
    func testArrayOfFilterItems() {
        let filters: [TestFilterItem] = [
            .name("test"),
            .age(25),
            .active(true)
        ]
        
        let queries = filters.queries
        
        XCTAssertEqual(queries.count, 3)
        XCTAssertTrue(queries.contains(where: { $0.name == "filter[name]" && $0.value == "test" }))
        XCTAssertTrue(queries.contains(where: { $0.name == "filter[age]" && $0.value == "25" }))
        XCTAssertTrue(queries.contains(where: { $0.name == "filter[active]" && $0.value == "true" }))
    }
    
    // MARK: - Enum Value Tests
    
    func testFilterItemWithEnumValue() {
        let filter = TestFilterItemWithEnumValue.status(.active)
        let queries = filter.queries
        
        XCTAssertEqual(queries.count, 1)
        XCTAssertEqual(queries.first?.name, "filter[status]")
        XCTAssertEqual(queries.first?.value, "Active")
    }
    
    func testFilterItemWithEnumValueInactive() {
        let filter = TestFilterItemWithEnumValue.status(.inactive)
        let queries = filter.queries
        
        XCTAssertEqual(queries.count, 1)
        XCTAssertEqual(queries.first?.name, "filter[status]")
        XCTAssertEqual(queries.first?.value, "Inactive")
    }
    
    // MARK: - Date Filter Item Tests
    
    func testDateFilterItem() {
        let date = Date(timeIntervalSince1970: 1609459200)
        let dateFilterValue: FilterItemValueCodable = date
        
        XCTAssertEqual(dateFilterValue.queryValue, "2021-01-01T00:00:00.000Z")
    }
}

