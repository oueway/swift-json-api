//
//  SingleResponse.swift
//  SwiftJsonApi
//
//  Created by Brandee on 11/27/25.
//

public protocol SingleResponse: Decodable {
    associatedtype Item: Decodable
    var item: Item? { get }
}

public struct SimpleSingleResponse<Item: Decodable>: SingleResponse {
    public let item: Item?
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.item = try container.decode(Item.self)
    }
}
