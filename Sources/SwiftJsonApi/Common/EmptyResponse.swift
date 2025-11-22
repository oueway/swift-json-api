//
//  EmptyResponse.swift
//
//
//  Created by Brandee on 11/19/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//

import Foundation

// MARK: - EmptyResponse

public protocol EmptyResponse: Codable {
    init()
}

extension EmptyResponse {

    // MARK: Lifecycle

    public init(from decoder: Decoder) throws {
        throw MyError.server("EmptyResponse should not be decoded!")
    }

    // MARK: Public

    public func encode(to encoder: Encoder) throws {
        throw MyError.server("EmptyResponse should not be encoded!")
    }
}
