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

public protocol JAResourceProtocol {
    associatedtype IncludeItem: IncludeItemProtocol

    static var resourcePath: String { get }
}

// MARK: - IncludeItemProtocol Type

public protocol IncludeItemProtocol: StringRawRepresentable {}

// MARK: - EmptyIncludeItem Type

public struct EmptyIncludeItem: IncludeItemProtocol {
    public init?(rawValue: String) { 
        return nil
    }
    
    public var rawValue: String {
        ""
    }
}

// MARK: - get method

public extension JAResourceProtocol where Self: JADatumProtocol {
    static func get(byID id: String, include includeItems: [IncludeItem]? = nil) async throws -> JAResponse<Self> {
        guard let taskManager = WebService.shared else {
            throw MyError.local("WebService is not set")
        }
        
        var queryItems: [URLQueryItem]?
        if let includeItems {
            queryItems = [URLQueryItem(name: "include", value: includeItems.queryValue)]
        }

        return try await taskManager.decodableTask(
            with: .get(
                from: .urlFromPath(Self.resourcePath, queryItems: queryItems)
            )
        )
    }
}

// extension JAResourceProtocol where Self: Decodable {
//    public static func get(byID id: String?, filters filterItems: [Self.FilterItem]? = nil) async throws -> Self {
//        var resourcePath = resourcePath
//        if let id = id { resourcePath += "/\(id)" }
//
//        return try await CWS.shared.decodableTask(with:
//            .get(from: CWS.shared.urlFromPath(resourcePath, withQueryItems: filterItems?.queries))
//        )
//    }
//
//    public static func post<Request>(request: Request, filters: [Self.FilterItem]? = nil) async throws -> Self where Request: Encodable {
//        try await CWS.shared.decodableTask(with:
//            .post(
//                to: CWS.shared.urlFromPath(
//                    try resourcePath(
//                        userProfile: await CWSUserProfile.current
//                    ), withQueryItems: filters?.queries
//                ),
//                data: try JSONEncoder.iso8601UTC.encode(request)
//            )
//        )
//    }
//
//    public static func post(filters filterItems: [Self.FilterItem]? = nil) async throws -> Self {
//        try await CWS.shared.decodableTask(with:
//            .post(
//                to: CWS.shared.urlFromPath(
//                    try resourcePath(
//                        userProfile: await CWSUserProfile.current
//                    ), withQueryItems: filterItems?.queries
//                ),
//                data: Data()
//            )
//        )
//    }
//
//    public static func put<Request>(request: Request, id: String?, filters: [Self.FilterItem]? = nil) async throws -> Self where Request: Encodable {
//        var resourcePath = try resourcePath(userProfile: await CWSUserProfile.current)
//        if let id = id { resourcePath += "/\(id)" }
//
//        return try await CWS.shared.decodableTask(with:
//            .put(
//                to: CWS.shared.urlFromPath(resourcePath, withQueryItems: filters?.queries),
//                data: try JSONEncoder.iso8601UTC.encode(request)
//            )
//        )
//    }
//
//    public static func put(id: String?, filters: [Self.FilterItem]? = nil) async throws -> Self {
//        var resourcePath = try resourcePath(userProfile: await CWSUserProfile.current)
//        if let id = id { resourcePath += "/\(id)" }
//
//        return try await CWS.shared.decodableTask(with:
//            .put(
//                to: CWS.shared.urlFromPath(resourcePath, withQueryItems: filters?.queries),
//                data: Data()
//            )
//        )
//    }
//
//    public static func delete(byID id: String?, filters: [Self.FilterItem]? = nil) async throws -> Bool {
//        var resourcePath = try resourcePath(userProfile: await CWSUserProfile.current)
//        if let id = id { resourcePath += "/\(id)" }
//
//        return try await CWS.shared.booleanTask(with:
//            .delete(
//                from: CWS.shared.urlFromPath(resourcePath, withQueryItems: filters?.queries))
//        )
//    }
// }
