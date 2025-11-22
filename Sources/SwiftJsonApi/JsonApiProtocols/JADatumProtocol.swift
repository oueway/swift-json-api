//
//  JADatumProtocol.swift
//
//
//  Created by Brandee on 11/20/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//

import Foundation

// MARK: - JADatumProtocol Type

/// Protocol representing a JSON:API resource (datum) with typed
/// attributes and relationships.
///
/// Conforming types should provide a designated initializer that can be
/// used by dynamic decoders and helper APIs.
public protocol JADatumProtocol: JAAnyDatum, JADatumProperties {
    /// Designated initializer for JSON:API datum types.
    init(id: String, links: JASelfLinks, attributes: Attributes, relationships: Relationships?)
}

// MARK: - JAAnyDatum Type

public protocol JAAnyDatum: Codable {
    /// JSON:API type name (resource type).
    static var typeName: String { get }

    var type: String { get }
    var id: String { get }
    var links: JASelfLinks { get }

    /// Resolve relationship placeholders using included resources map.
    /// - Parameter includes: A dictionary keyed by resource type with arrays of included resources.
    /// - Returns: A new instance with relationships resolved.
    func resolveRelationships(fromIncludes includes: [String: [JAAnyDatum]]) -> Self
}

// MARK: - JADatumProperties Type

public protocol JADatumProperties {
    /// Attributes payload for the resource.
    associatedtype Attributes: Codable
    /// Relationships payload for the resource.
    associatedtype Relationships: Codable 

    /// Decoded attributes.
    var attributes: Attributes { get }
    /// Decoded relationships (optional).
    var relationships: Relationships? { get }
}

// MARK: - Default Implementations

public extension JAAnyDatum {
    /// Default implementation returns self. Conforming types can override to actually resolve relationships.
    func resolveRelationships(fromIncludes includes: [String: [JAAnyDatum]]) -> Self { self }
}
