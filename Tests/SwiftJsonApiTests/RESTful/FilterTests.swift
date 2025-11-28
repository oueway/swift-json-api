//
//  FilterTests.swift
//
//  Created by Oueway Forest on 11/28/25.
//

import XCTest
@testable import SwiftJsonApi

final class FilterTests: XCTestCase {

    enum Status: String, FilterItemEnumValue {
        case todo = "todo"
        case inProgress = "inProgress"
    }

    enum TestFilter: FilterItemProtocol {
        case assignee(String)
        case status([Status])
        case date(startFrom: Date, endOn: Date)
        case group([String])
    }

    func testKeyValuesSingle() {
        let filter = TestFilter.assignee("octocat")
        let keyValues = filter.keyValues

        XCTAssertEqual(keyValues.count, 1)
        XCTAssertEqual(keyValues["assignee"] as? String, "octocat")
    }

    func testQueriesSingle() {
        let filter = TestFilter.assignee("octocat")
        let queryItems = [filter].queries

        XCTAssertEqual(queryItems.count, 1)
        let first = queryItems.first!
        XCTAssertEqual(first.value, "octocat")
        XCTAssertTrue(first.name.lowercased().contains("assignee"))
    }

    func testMultipleParamFilter() {
        let start = Date(timeIntervalSince1970: 0)
        let end = Date(timeIntervalSince1970: 3600)
        let filter = TestFilter.date(startFrom: start, endOn: end)
        let keyValues = filter.keyValues

        // Should include both joined keys
        XCTAssertNotNil(keyValues["dateStartFrom"])
        XCTAssertNotNil(keyValues["dateEndOn"])

        let queries = [filter].queries
        let startQuery = queries.first { $0.name.contains("dateStartFrom") }
        let endQuery = queries.first { $0.name.contains("dateEndOn") }

        XCTAssertNotNil(startQuery)
        XCTAssertNotNil(endQuery)

        // Verify date formatting uses ISO8601 UTC
        XCTAssertTrue(startQuery?.value?.contains("1970-01-01T00:00:00") ?? false)
    }

    func testArrayValueFilter() {
        let filter = TestFilter.status([.todo, .inProgress])
        let queryItems = [filter].queries

        let query = queryItems.first { $0.name.contains("status") }
        XCTAssertNotNil(query)
        XCTAssertEqual(query?.value, "todo,inProgress")
    }

    func testGroupArrayFilter() {
        let filter = TestFilter.group(["a", "b", "c"])
        let queryItems = [filter].queries

        let query = queryItems.first { $0.name.contains("group") }
        XCTAssertNotNil(query)
        XCTAssertEqual(query?.value, "a,b,c")
    }

    func testQueryConverterValueOfArrayWithCodableValues() {
        let values: [FilterItemValueCodable] = [Date(timeIntervalSince1970: 0), Date(timeIntervalSince1970: 1)]
        let str = QueryConverter.valueOfArray(values as [Any])
        XCTAssertTrue(str.contains("1970-01-01T00:00:00"))
    }
}
