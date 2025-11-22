//
//  JARelationship.swift
//
//
//  Created by Brandee on 11/17/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//

import Foundation

// MARK: - JARelationship Type

public struct JARelationship<T: JADatumProtocol>: Codable {

    public let data: JADataOrDatas<_Data>?
    public let links: Links?
    public let datums: [T]?

    public struct Links: Codable {
        public let linksSelf, related: String

        enum CodingKeys: String, CodingKey {
            case linksSelf = "self"
            case related
        }
    }

    public struct _Data: Codable {
        public let id, type: String
    }

    // MARK: -  Creation

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

public struct JADataOrDatas<T: Codable>: Codable {
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
