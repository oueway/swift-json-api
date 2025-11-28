//
//  JASelfLinksTests.swift
//
//  Created by Oueway Forest on 11/25/25.
//

import XCTest
@testable import SwiftJsonApi

final class JASelfLinksTests: XCTestCase {
    
    func testInit() {
        let selfLink = "https://api.example.com/resource/1"
        let links = JASelfLinks(linksSelf: selfLink)
        
        XCTAssertEqual(links.linksSelf, selfLink)
    }
    
    func testEncodeDecode() throws {
        let originalLinks = JASelfLinks(linksSelf: "https://api.example.com/resource/1")
        
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(originalLinks)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(JASelfLinks.self, from: encoded)
        
        XCTAssertEqual(decoded.linksSelf, originalLinks.linksSelf)
    }
    
    func testDecodeFromJSON() throws {
        let json = """
        {
            "self": "https://api.example.com/resource/1"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let links = try decoder.decode(JASelfLinks.self, from: json)
        
        XCTAssertEqual(links.linksSelf, "https://api.example.com/resource/1")
    }
    
    func testEncodeToJSON() throws {
        let links = JASelfLinks(linksSelf: "https://api.example.com/resource/1")
        
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(links)
        
        let json = try JSONSerialization.jsonObject(with: encoded) as! [String: String]
        
        XCTAssertEqual(json["self"], "https://api.example.com/resource/1")
    }
}

