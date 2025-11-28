//
//  JAResourceProtocol.swift
//
//
//  Created by Brandee on 11/17/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - JAResourceProtocol Type

// TODO: conform to ResourceProtocol
/// Protocol for a JSON:API resource type that exposes its REST path and
/// include-able relationships.
public protocol JAResourceProtocol {
    /// The `IncludeItem` type enumerates relationships that can be included
    /// when requesting the resource from the API.
    associatedtype IncludeItem: IncludeItemProtocol

    /// The resource path segment used to construct API endpoints for the type.
    static var resourcePath: String { get }
}

// MARK: - IncludeItemProtocol Type

/// Protocol representing a valid include token (typically an enum).
public protocol IncludeItemProtocol: StringRawRepresentable {}

// MARK: - EmptyIncludeItem Type

/// A placeholder `IncludeItem` implementation used when no includes are needed.
public struct EmptyIncludeItem: IncludeItemProtocol {
    public init?(rawValue: String) { nil }
    public var rawValue: String { "" }
}

// MARK: - get method

public extension JAResourceProtocol where Self: JADatumProtocol {
    /// Fetch a single resource by identifier.
    /// - Parameters:
    ///   - id: The resource identifier to fetch.
    ///   - includeItems: Optional relationships to include.
    /// - Returns: A decoded `JAResponse` containing the requested resource.
    static func get(byID id: String, include includeItems: [IncludeItem]? = nil) async throws -> JAResponse<Self> {
        guard let webService = WebService.shared else { throw MyError.local("WebService is not set") }

        let resourcePath = "\(Self.resourcePath)/\(id)"
        var queryItems: [URLQueryItem]?
        if let includeItems {
            queryItems = [URLQueryItem(name: "include", value: includeItems.queryValue)]
        }

        return try await webService.decodableTask(
            with: .get(
                from: .urlFromPath(resourcePath, queryItems: queryItems),
                contentType: .jsonAPI
            )
        )
    }
}
