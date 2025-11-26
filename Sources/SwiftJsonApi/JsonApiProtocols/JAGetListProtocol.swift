//
//  JAGetListProtocol.swift
//
//
//  Created by Brandee on 11/17/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - JAGetListProtocol Type

/// Protocol for resources that support listing (GET collection) operations.
///
/// Conforming types declare `SortItem` and `FilterItem` associated types to
/// provide typed sorting and filtering helpers for requests.
public protocol JAGetListProtocol: JAResourceProtocol {
    /// The type used to represent sortable fields for collection requests.
    associatedtype SortItem: JASortItemProtocol

    /// The type used to represent filter items for collection requests.
    associatedtype FilterItem: JAFilterItemProtocol
}

// MARK: - JASortItemProtocol Type

/// Represents a sortable field. Conformers are typically simple enums.
public protocol JASortItemProtocol: StringRawRepresentable {
    /// Construct a sort item from string value.
    init(_ value: String)
}

public extension JASortItemProtocol {
    var asc: Self { self }

    var desc: Self { Self("-\(rawValue)") }

    init?(rawValue: RawValue) {
        self.init(rawValue)
    }
}

extension Array where Element: StringRawRepresentable {
    var queryValue: String {
        reduce("") { partialResult, item in
            if partialResult.isEmpty {
                return item.rawValue
            }

            return partialResult + "," + item.rawValue
        }
    }
}

// MARK: - JAEmptySortItem Type

/// A trivial `SortItem` implementation for cases where no concrete enum is used.
public struct JAEmptySortItem: JASortItemProtocol {
    public let rawValue: String

    /// Create an `JAEmptySortItem` from an arbitrary string.
    /// - Parameter value: The raw string value to use for sorting.
    public init(_ value: String) {
        rawValue = value
    }
}

// MARK: - Apollo + JAGetListProtocol

public extension JAGetListProtocol where Self: JADatumProtocol {
    /// Fetch a paginated list of resources from the server.
    ///
    /// This helper composes query items for filters, sorting and includes
    /// and calls the shared `WebService` to perform the request.
    /// - Parameters:
    ///   - filterItems: Optional array of filter items to apply.
    ///   - sortItems: Optional array of sort descriptors.
    ///   - includeItems: Optional list of related resources to include.
    ///   - pageSize: Page size to request (defaults to 15).
    /// - Returns: A decoded `JAResponse` containing the requested resources.
    static func list(
        filterBy filterItems: [FilterItem]? = nil,
        sortBy sortItems: [SortItem]? = nil,
        include includeItems: [IncludeItem]? = nil,
        pageSize: Int = 15
    ) async throws -> JAResponse<Self> {
        guard let taskManager = WebService.shared else {
            throw MyError.local("WebService is not set")
        }

        // TODO: pageIndex?
        var queryItems = [URLQueryItem(name: "page[size]", value: "\(pageSize)")]

        if let sortItems {
            queryItems.append(
                URLQueryItem(name: "sort", value: sortItems.queryValue)
            )
        }

        if let filterItems {
            queryItems.append(contentsOf: filterItems.queries)
        }

        if let includeItems {
            queryItems.append(
                URLQueryItem(name: "include", value: includeItems.queryValue)
            )
        }

        return try await taskManager.decodableTask(
            with: .get(
                from: .urlFromPath(Self.resourcePath, queryItems: queryItems)
            )
        )
    }
}
