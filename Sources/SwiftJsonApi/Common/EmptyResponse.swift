//
//  EmptyResponse.swift
//
//
//  Created by Brandee on 11/19/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//

import Foundation

// MARK: - EmptyResponse

/// Protocol representing an intentionally empty response body.
///
/// Types conforming to `EmptyResponse` indicate that the server should
/// not provide a body for the corresponding response. The default
/// `Codable` implementations throw to surface misuse.
public protocol EmptyResponse: Codable {
    /// A parameterless initializer required for conformance.
    init()
}

extension EmptyResponse {
    public init(from decoder: Decoder) throws {
        throw MyError.server("EmptyResponse should not be decoded!")
    }

    public func encode(to encoder: Encoder) throws {
        throw MyError.server("EmptyResponse should not be encoded!")
    }
}
