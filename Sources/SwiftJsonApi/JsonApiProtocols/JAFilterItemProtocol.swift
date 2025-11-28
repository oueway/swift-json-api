//
//  JAFilterItemProtocol.swift
//
//  Created by Brandee on 11/19/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//

import Foundation

public protocol JAFilterItemProtocol: FilterItemProtocol {
    var queries: [URLQueryItem] { get }
}

public extension JAFilterItemProtocol {
    var queries: [URLQueryItem] {
        keyValues.map {
            QueryConverter.queryItem(fromKey: "filter[\($0)]", value: $1)
        }
    }
}

public extension Array where Element: JAFilterItemProtocol {
    var queries: [URLQueryItem] {
        keyValues.map {
            QueryConverter.queryItem(fromKey: "filter[\($0)]", value: $1)
        }
    }
}
