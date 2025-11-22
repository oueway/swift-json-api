//
//  JARelationship.swift
//
//
//  Created by Brandee on 11/17/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//

import Foundation

// MARK: - JARelationship Type

/// Represents a JSON:API relationship for a resource of type `T`.
///
/// Contains optional linkage data, relationship `links` and any resolved
/// included `datums` of type `T`.
public struct JARelationship<T: JADatumProtocol>: Codable {

    /// The relationship linkage data (single or multiple).
    public let data: JADataOrDatas<_Data>?

    public let links: Links?

    /// Resolved related resources when `included` contains full objects.
    public let datums: [T]?

    /// Relationship-level links (self and related).
    public struct Links: Codable {
        public let linksSelf, related: String

        enum CodingKeys: String, CodingKey {
            case linksSelf = "self"
            case related
        }
    }

    /// Lightweight representation for relationship linkage data.
    public struct _Data: Codable {
        public let id, type: String
    }

    // MARK: -  Creation

    /// An empty relationship with no data, links or included datums.
    public static var empty: Self {
        JARelationship(data: nil, links: nil, datums: nil)
    }

    public init(data: JADataOrDatas<_Data>?, links: Links?, datums: [T]?) {
        self.data = data
        self.links = links
        self.datums = datums
    }
}

extension JARelationship {

    /// Attempt to resolve relationship linkage to concrete included objects.
    /// - Parameter includes: A map of included resources keyed by type name.
    /// - Returns: A `JARelationship` containing the resolved datums or `nil`
    ///            if no matching included objects were found.
    func resolved(fromIncludes includes: [String: [JAAnyDatum]]) -> Self? {

        guard let objects = includes[T.typeName],
              let datums = data?.array.compactMap({ data in
                  (objects.first { $0.id == data.id } as? T)?
                      .resolveRelationships(fromIncludes: includes)
              }),
              !datums.isEmpty else {
            return nil
        }

        return JARelationship(
            data: data,
            links: links,
            datums: datums
        )
    }
}

// MARK: - JADataOrDatas Type

/// A small helper type that decodes either a single `T` or an array of `T`
/// into a uniform `[T]` representation.
public struct JADataOrDatas<T: Codable>: Codable {
    /// The decoded array of items.
    public let array: [T]

    public init(datas: [T]) {
        array = datas
    }

    public init(data: T) {
        array = [data]
    }

    public init(from decoder: Decoder) throws {
        do {
            array = try [T].init(from: decoder)
        } catch {
            let data = try T(from: decoder)
            array = [data]
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        try array.encode(to: encoder)
    }
}
