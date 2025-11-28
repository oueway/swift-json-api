//
//  ResourceProtocol.swift
//  SwiftJsonApi
//
//  Created by Brandee on 11/26/25.
//

import Foundation

// MARK: - ResourceProtocol

public protocol ResourceProtocol {
    associatedtype FilterItem: FilterItemProtocol

    /// The resource path segment used to construct API endpoints for the type.
    static var resourcePath: String? { get }
}

public extension ResourceProtocol {
    typealias FilterItem = EmptyFilterItem
}

public extension ResourceProtocol where Self: Decodable {
    static func get<RR: SingleResponse>(byID id: String?, filters: [Self.FilterItem]? = nil) async throws -> RR where RR.Item == Self {
        guard let webService = WebService.shared else { throw MyError.local("WebService is not set") }
        guard var resourcePath else { throw MyError.local("\(Self.self).resourcePath is not set") }
        if let id { resourcePath += "/\(id)" }

        return try await webService.decodableTask(
            with: .get(
                from: .urlFromPath(resourcePath, queryItems: filters?.queries)
            )
        )
    }

    static func post<R, RR>(request: R = EmptyRequestData(), filters: [Self.FilterItem]? = nil) async throws -> RR where R: Encodable, RR: SingleResponse, RR.Item == Self {
        guard let webService = WebService.shared else { throw MyError.local("WebService is not set") }
        guard let resourcePath else { throw MyError.local("\(Self.self).resourcePath is not set") }

        return try await webService.decodableTask(with:
            .post(
                to: .urlFromPath(resourcePath, queryItems: filters?.queries),
                data: JSONEncoder.iso8601UTC.encode(request)
            )
        )
    }

    static func put<R, RR>(request: R = EmptyRequestData(), id: String?, filters: [Self.FilterItem]? = nil) async throws -> RR where R: Encodable, RR: SingleResponse, RR.Item == Self {
        guard let webService = WebService.shared else { throw MyError.local("WebService is not set") }
        guard var resourcePath else { throw MyError.local("\(Self.self).resourcePath is not set") }
        if let id { resourcePath += "/\(id)" }

        return try await webService.decodableTask(with:
            .put(
                to: .urlFromPath(resourcePath, queryItems: filters?.queries),
                data: JSONEncoder.iso8601UTC.encode(request)
            )
        )
    }

    static func delete(byID id: String?, filters: [Self.FilterItem]? = nil) async throws -> Bool {
        guard let webService = WebService.shared else { throw MyError.local("WebService is not set") }
        guard var resourcePath else { throw MyError.local("\(Self.self).resourcePath is not set") }
        if let id = id { resourcePath += "/\(id)" }

        return try await webService.booleanTask(with:
            .delete(from: .urlFromPath(resourcePath, queryItems: filters?.queries))
        )
    }
}

public struct EmptyRequestData: Encodable {
    public init() {}
}
