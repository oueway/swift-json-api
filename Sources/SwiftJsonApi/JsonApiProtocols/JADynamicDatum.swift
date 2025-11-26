//
//  JADynamicDatum.swift
//
//
//  Created by Brandee on 11/20/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//

import Foundation

// MARK: - UnknownDatum Type

/// Container used to decode heterogeneous JSON:API included resources
/// when the concrete datum type is determined at runtime.
public struct JADynamicDatum: Codable {
    /// Mapping of JSON:API `type` string to the concrete `JAAnyDatum` type.
    static var allTypes: [String: JAAnyDatum.Type] = [:]

    /// The decoded datum instance (type-erased to `JAAnyDatum`).
    public let datum: JAAnyDatum

    private enum CodingKeys: String, CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        guard let datumType = Self.allTypes[type] else {
            let message = "Unknown datum type: \(type)! Call `The\(type.capitalized)DatumType.register(as: \"\(type)\")` to register it"
            MyLogger.jsonApi?.error(message)
            throw MyError.local(message)
        }
        self.datum = try datumType.init(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        try datum.encode(to: encoder)
    }
}

public extension JAAnyDatum {
    /// Register a concrete `JAAnyDatum` type for a JSON:API `type` string
    /// so that `JADynamicDatum` can decode included resources dynamically.
    /// - Parameter type: The `type` string as it appears in the JSON:API payload.
    static func register(as type: String = Self.typeName) {
        JADynamicDatum.allTypes[type] = self.self
    }
}
