//
//  ListResponse.swift
//  SwiftJsonApi
//
//  Created by Brandee on 11/27/25.
//

public protocol ListResponse: Decodable {
    associatedtype Item: Decodable
    var items: [Item] { get }
    var hasNextPage: Bool { get }

    func nextPage() async throws -> Self?
    mutating func updateWithNextPage() async throws
}

public extension ListResponse {
    var hasNextPage: Bool { false }
    func nextPage() async throws -> Self? { nil }
    mutating func updateWithNextPage() async throws {}
}

public struct SimpleListResponse<Item: Decodable>: ListResponse {
    public let items: [Item]
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.items = try container.decode([Item].self)
    }
}
