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

public protocol JAGetListProtocol: JAResourceProtocol {
    associatedtype SortItem: SortItemProtocol
    associatedtype FilterItem: JAFilterItemProtocol
}

// MARK: - SortItemProtocol Type

public protocol SortItemProtocol: StringRawRepresentable {
    init(_ value: String)
}

public extension SortItemProtocol {
    var ascending: Self { self }

    var descending: Self { Self("-\(rawValue)") }

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

// MARK: - EmptySortItem Type

public struct EmptySortItem: SortItemProtocol {
    public let rawValue: String

    public init(_ value: String) {
        rawValue = value
    }
}

// MARK: - Apollo + JAGetListProtocol

public extension JAGetListProtocol where Self: JADatumProtocol {
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
