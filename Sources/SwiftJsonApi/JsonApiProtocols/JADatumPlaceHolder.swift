//
//  JADatumPlaceHolder.swift
//  SwiftJsonApi
//
//  Created by Brandee on 11/20/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//


// MARK: - JADatumPlaceHolder Type

/// A generic placeholder datum used when a concrete resource type is not
/// available. Useful for decoding unknown included items or during tests.
public struct JADatumPlaceHolder: JADatumProtocol {
    public static let typeName: String = "placeholder"

    public let id: String
    public let type: String
    public let links: JASelfLinks
    public let attributes: Attributes
    public let relationships: Relationships?

    public struct Attributes: Codable {}
    public struct Relationships: Codable {}

    public func resolveRelationships(fromIncludes _: [String: [JAAnyDatum]]) -> Self { self }

    public init(id: String, links: JASelfLinks, attributes: Attributes, relationships: Relationships?) {
        type = Self.typeName
        self.id = id
        self.links = links
        self.attributes = attributes
        self.relationships = relationships
    }
}
