//
//  Array+FilterItemProtocol.swift
//  SwiftJsonApi
//
//  Created by Brandee on 11/26/25.
//

import Foundation

extension Array where Element: FilterItemProtocol {
    var keyValues: [String: Any] {
        reduce(into: [String: Any]()) { result, element in
            for item in element.keyValues {
                result.updateValue(item.value, forKey: item.key)
            }
        }
    }

    public var queries: [URLQueryItem] {
        keyValues.map {
            QueryConverter.queryItem(fromKey: $0, value: $1)
        }
    }
}

enum QueryConverter {
    static func queryItem(fromKey key: String, value: Any) -> URLQueryItem {
        let stringValue: String
        switch value {
        case let value as FilterItemValueCodable:
            stringValue = value.queryValue
        case let values as [FilterItemValueCodable]:
            stringValue = queryValueFromCodableValues(values)
        case let values as [Any]:
            stringValue = queryValueFromArray(values)
        default:
            stringValue = "\(value)"
        }

        return URLQueryItem(name: key, value: stringValue)
    }

    static func valueOfArray(_ array: [Any]) -> String {
        let stringValue: String
        switch array {
        case let values as [FilterItemValueCodable]:
            stringValue = queryValueFromCodableValues(values)
        default:
            stringValue = queryValueFromArray(array)
        }
        return stringValue
    }

    private static func queryValueFromCodableValues(_ array: [FilterItemValueCodable]) -> String {
        var ret = array.reduce("") { $0 + "\($1.queryValue)," }
        ret.removeLast()
        return ret
    }

    private static func queryValueFromArray(_ array: [Any]) -> String {
        var ret = array.reduce("") { $0 + "\($1)," }
        ret.removeLast()
        return ret
    }
}
