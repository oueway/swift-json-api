//
//  JADynamicDatum.swift
//
//
//  Created by Brandee on 11/20/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//

import Foundation

// MARK: - UnknownDatum Type

public struct JADynamicDatum: Codable {
    static var allTypes: [String: JAAnyDatum.Type] = [:]

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
    static func register(as type: String) {
        JADynamicDatum.allTypes[type] = self.self
    }
}
