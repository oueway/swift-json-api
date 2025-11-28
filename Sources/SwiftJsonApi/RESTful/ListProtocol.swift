//
//  ListProtocol.swift
//
//  Created by Brandee on 3/29/23.
//

import Foundation

// MARK: - ListProtocol

public protocol ListProtocol: ResourceProtocol {
//    associatedtype FilterItem: FilterItemProtocol

    /// Due to the inconsistent design of the CWS API, it is necessary to specify whether the resource supports paging.
    static var supportPagination: Bool { get }

    /// Due to the inconsistent design of the CWS API, it is necessary to specify what method that API support
    static var filterMethod: ListFilterMethod { get }
}

// MARK: - ListFilterMethod

public enum ListFilterMethod {
    case query, postForm, postJson
}

// MARK: - ListProtocol + Default

public extension ListProtocol {
    static var supportPagination: Bool { true }

    static var filterMethod: ListFilterMethod { .query }
}

public extension ListProtocol where Self: Decodable {
    static func list<R: ListResponse>(filters: [Self.FilterItem]? = nil, pageIndex: Int = 0, pageSize: Int = 15) async throws -> R where R.Item == Self {
        guard let webService = WebService.shared else { throw MyError.local("WebService is not set") }
        guard let resourcePath else { throw MyError.local("\(Self.self).resourcePath is not set") }
        let request: URLRequest

        var queries = filters?.queries ?? []
        if Self.supportPagination, let params = webService.delegate.paginationParams {
            queries.append(URLQueryItem(name: params.indexKey, value: "\(pageIndex)"))
            queries.append(URLQueryItem(name: params.sizeKey, value: "\(pageSize)"))
        }

        switch Self.filterMethod {
        case .query:
            request = URLRequest.get(from: .urlFromPath(resourcePath, queryItems: queries))

        case .postForm:
            request = try URLRequest.post(
                to: .urlFromPath(resourcePath),
                data: URLRequest.formData(withQueryItems: queries),
                contentType: .formUrlEncoded
            )

        case .postJson:
            // TODO: queries -> keyValues?
            request = try URLRequest.post(
                to: .urlFromPath(resourcePath),
                data: URLRequest.jsonData(withKeyValues: filters?.keyValues)
            )
        }

        return try await webService.decodableTask(with: request)
    }
}
