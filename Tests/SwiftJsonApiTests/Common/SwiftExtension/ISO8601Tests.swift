//
//  ISO8601Tests.swift
//
//  Created by Oueway Forest on 11/25/25.
//

import XCTest
@testable import SwiftJsonApi

final class ISO8601Tests: XCTestCase {
    
    // MARK: - Date Encoding Tests
    
    func testEncodeDateToISO8601UTC() throws {
        let date = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
        let encoder = JSONEncoder.iso8601UTC
        
        let encoded = try encoder.encode(["date": date])
        let json = try JSONSerialization.jsonObject(with: encoded) as! [String: String]
        
        XCTAssertNotNil(json["date"])
        // Should contain format like "2021-01-01T00:00:00.000Z"
        XCTAssertTrue(json["date"]!.contains("2021-01-01T00:00:00"))
        XCTAssertTrue(json["date"]!.hasSuffix("Z"))
    }
    
    func testEncodeDateWithMilliseconds() throws {
        // Create a date with milliseconds
        let date = Date(timeIntervalSince1970: 1609459200.123)
        let encoder = JSONEncoder.iso8601UTC
        
        let encoded = try encoder.encode(["date": date])
        let json = try JSONSerialization.jsonObject(with: encoded) as! [String: String]
        
        XCTAssertNotNil(json["date"])
        // Should include the milliseconds part
        XCTAssertTrue(json["date"]!.contains(".123"))
    }
    
    // MARK: - Date Decoding Tests
    
    func testDecodeISO8601WithFractionalSeconds() throws {
        let jsonString = """
        {"date": "2021-01-01T00:00:00.123Z"}
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder.iso8601Standard
        
        struct DateContainer: Codable {
            let date: Date
        }
        
        let decoded = try decoder.decode(DateContainer.self, from: jsonData)
        
        XCTAssertNotNil(decoded.date)
        // Verify the date is parsed correctly
        let timeInterval = decoded.date.timeIntervalSince1970
        XCTAssertEqual(timeInterval, 1609459200.123, accuracy: 0.001)
    }
    
    func testDecodeISO8601WithoutFractionalSeconds() throws {
        let jsonString = """
        {"date": "2021-01-01T00:00:00Z"}
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder.iso8601Standard
        
        struct DateContainer: Codable {
            let date: Date
        }
        
        let decoded = try decoder.decode(DateContainer.self, from: jsonData)
        
        XCTAssertNotNil(decoded.date)
        let timeInterval = decoded.date.timeIntervalSince1970
        XCTAssertEqual(timeInterval, 1609459200, accuracy: 1.0)
    }
    
    func testDecodeISO8601DateOnly() throws {
        let jsonString = """
        {"date": "2021-01-01"}
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder.iso8601Standard
        
        struct DateContainer: Codable {
            let date: Date
        }
        
        let decoded = try decoder.decode(DateContainer.self, from: jsonData)
        
        XCTAssertNotNil(decoded.date)
        // The date should be correctly parsed (date-only)
        var calendar = Calendar.current
        if #available(iOS 16, tvOS 16, macOS 13, watchOS 9, *) {
            calendar.timeZone = .gmt
        } else {
            // Fallback on earlier versions
        }
        let components = calendar.dateComponents([.year, .month, .day], from: decoded.date)
        
        XCTAssertEqual(components.year, 2021)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 1)
    }
    
    func testDecodeInvalidDateThrowsError() {
        let jsonString = """
        {"date": "invalid-date"}
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder.iso8601Standard
        
        struct DateContainer: Codable {
            let date: Date
        }
        
        XCTAssertThrowsError(try decoder.decode(DateContainer.self, from: jsonData)) { error in
            // Should throw an error of type MyError.app
            XCTAssertTrue(error is MyError)
        }
    }
    
    // MARK: - DateFormatter Tests
    
    func testEncodeISO8601UTCFormatter() {
        let date = Date(timeIntervalSince1970: 1609459200)
        let formatter = DateFormatter.encodeISO8601UTC
        
        let formatted = formatter.string(from: date)
        
        XCTAssertEqual(formatted, "2021-01-01T00:00:00.000Z")
    }
    
    func testEncodeISO8601UTCFormatterTimezone() {
        let formatter = DateFormatter.encodeISO8601UTC
        XCTAssertEqual(formatter.timeZone?.identifier, "GMT")
    }
    
    // MARK: - ISO8601DateFormatter Tests
    
    func testAllSupportFormattersCount() {
        let formatters = ISO8601DateFormatter.allSupportFormatters
        XCTAssertEqual(formatters.count, 3)
    }
    
    func testDecodeISO8601Formatter() {
        let formatter = ISO8601DateFormatter.decodeISO8601
        let dateString = "2021-01-01T00:00:00.123Z"
        
        let date = formatter.date(from: dateString)
        
        XCTAssertNotNil(date)
    }
    
    func testDecodeISO8601SecondaryFormatter() {
        let formatter = ISO8601DateFormatter.decodeISO8601Secondary
        let dateString = "2021-01-01T00:00:00Z"
        
        let date = formatter.date(from: dateString)
        
        XCTAssertNotNil(date)
    }
    
    func testDecodeISO8601DateOnlyFormatter() {
        let formatter = ISO8601DateFormatter.decodeISO8601DateOnly
        let dateString = "2021-01-01"
        
        let date = formatter.date(from: dateString)
        
        XCTAssertNotNil(date)
    }
}

