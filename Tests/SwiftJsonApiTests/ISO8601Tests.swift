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
        // 应该包含 "2021-01-01T00:00:00.000Z" 格式
        XCTAssertTrue(json["date"]!.contains("2021-01-01T00:00:00"))
        XCTAssertTrue(json["date"]!.hasSuffix("Z"))
    }
    
    func testEncodeDateWithMilliseconds() throws {
        // 创建一个带毫秒的日期
        let date = Date(timeIntervalSince1970: 1609459200.123)
        let encoder = JSONEncoder.iso8601UTC
        
        let encoded = try encoder.encode(["date": date])
        let json = try JSONSerialization.jsonObject(with: encoded) as! [String: String]
        
        XCTAssertNotNil(json["date"])
        // 应该包含毫秒部分
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
        // 验证日期是否正确解析
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
        // 日期应该被正确解析（只包含日期部分）
        var calendar = Calendar.current
        calendar.timeZone = .gmt
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
            // 应该抛出 MyError.app 类型的错误
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

