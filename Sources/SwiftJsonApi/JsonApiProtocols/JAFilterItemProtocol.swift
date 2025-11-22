//
//  JAFilterItemProtocol.swift
//
//  Created by Brandee on 11/19/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//

import Foundation

// MARK: - JAFilterItemProtocol

/**
 The ``JAFilterItemProtocol`` makes it easy to list filters. It automatically interprets, connects, and encodes query and query values for service APIs.

 Implement ``JAFilterItemProtocol`` using an `enum` to list all filter cases with parameter types.
    * `Case Name` is the default query name of the service API. Define a ``Key`` enum to handle query names differently.
    * `String Interpolation` is the default method to handle all kinds of value types. Use ``FilterItemValueCodable`` to handle value differently.
    * See the `FilterItem` in the example.

 ```
 public enum FilterItem: JAFilterItemProtocol {

     case miles(Double)
     case search(String)
     case samplingRate(SamplingRate)
     case date(startFrom: Date, endOn: Date)

     public enum Key: String, KeyProtocol {
         case search = "search.keyword"
         case dateStartFrom = "startDate"
         case dateEndOn = "endDate"
     }

     public enum SamplingRate: String, FilterItemEnumValue {
         // ...
     }
 }
 ```
 */
public protocol JAFilterItemProtocol {

    typealias KeyProtocol = StringRawRepresentable & CaseIterable

    /**
     `Key` enum is optional. Implement it with ``KeyProtocol``. It is needed if
        * The key can not be described by the case name of the filter. Such as `search.keyword` in the example
        * Or, you want to do a different name from the service API.
        * Or, needed by combined/multiple filters. Such as `date(startFrom: Date, endOn: Date)`  in the example
            * Connect the filter case and parameter names directly in the `Key` enum list.
            * To make the final name camel style, you need to capitalize the first letter of the parameter name.
            * For e.g. the `case dateStartFrom = "startDate"` matchs the `date(startFrom: Date, ..)`
            * For detail you can take a peek at `func jointLabel(_ label: String, and paramLabel: String) -> String`
     ```
     // ...
     case search(String)
     case date(startFrom: Date, endOn: Date)

     public enum Key: String, KeyProtocol {
         case search = "search.keyword"
         case dateStartFrom = "startDate"
         case dateEndOn = "endDate"
     }
     ```
     */
    associatedtype Key: KeyProtocol = DefaultFilterItemKey
}

// MARK: - JAFilterItemProtocol Implementations

public extension JAFilterItemProtocol {

    var queries: [URLQueryItem] {
        let mirror = Mirror(reflecting: self)

        guard let label = mirror.children.first?.label,
              let value = mirror.children.first?.value else {
            return []
        }

        switch value {
        case let value as FilterItemValueCodable:
            return [URLQueryItem(name: key(from: label), value: value.queryValue)]
        case let values as [FilterItemValueCodable]:
            return [URLQueryItem(name: key(from: label), value: valueFromCodableValues(values))]
        case let values as [Any]:
            return [URLQueryItem(name: key(from: label), value: valueFromArray(values))]
        default: break
        }

        if let queryItems = multipleQueries(label: label, value: value) {
            return queryItems
        }

        return [URLQueryItem(name: key(from: label), value: "\(value)")]
    }

    // MARK: Private

    /// Method to handle multiple queries in one filter
    private func multipleQueries(label: String, value: Any) -> [URLQueryItem]? {
        let paramsMirror = Mirror(reflecting: value)
        var result: [URLQueryItem] = []

        if paramsMirror.children.isEmpty { return nil }

        for param in paramsMirror.children {
            guard let paramLabel = param.label else { continue }
            let key = key(from: jointLabel(label, and: paramLabel))
            let stringValue = (param.value as? FilterItemValueCodable)?.queryValue ?? "\(param.value)"
            result.append(URLQueryItem(name: key, value: stringValue))
        }

        return result
    }

    /// Method of making joint label using filter name and param name
    private func jointLabel(_ label: String, and paramLabel: String) -> String {
        label + paramLabel.prefix(1).uppercased() + String(paramLabel.dropFirst())
    }

    /// Method to generate key of the query
    private func key(from label: String) -> String {
        let key = Self.Key.allCases
            .first {
                label == "\($0)"
            }?
            .rawValue as? String
            ?? label

        return "filter[\(key)]"
    }

    private func valueFromCodableValues(_ array: [FilterItemValueCodable]) -> String {
        array.reduce("") {
            $0.isEmpty ? $1.queryValue : $0 + ",\($1.queryValue)"
        }
    }

    private func valueFromArray(_ array: [Any]) -> String {
        array.reduce("") {
            $0.isEmpty ? "\($1)" : $0 + ",\($1)"
        }
    }
}

// MARK: - Array of JAFilterItemProtocol

extension Array where Element: JAFilterItemProtocol {

    var queries: [URLQueryItem] {
        flatMap { $0.queries }
    }
}

// MARK: - FilterItemValueCodable

/**
 Implement ``FilterItemValueCodable`` if a type needs to customize the value to the service API.
    * We had implemented Apollo API compatible `FilterItemValueCodable` for `Date` type. So by default, you don't need to customize it.
    * `FilterItemEnumValue` had implemented the `FilterItemValueCodable` for enums. see details ``FilterItemEnumValue``
 */
public protocol FilterItemValueCodable {

    var queryValue: String { get }
}

// MARK: - Date + FilterItemValueCodable

extension Date: FilterItemValueCodable {

    public var queryValue: String {
        DateFormatter.encodeISO8601UTC.string(from: self)
    }
}

// MARK: - FilterItemEnumValue

/**
 ``FilterItemEnumValue`` had implemented the `FilterItemValueCodable` for `enums` with value(RawRepresentable)

 You can easily add ``FilterItemEnumValue`` to your enums. Such as `SamplingRate` in the example.

 ```
 public enum SamplingRate: String, FilterItemEnumValue {
     case allRecords = "AllRecords"
     case twelvePerMinute = "12RecordsMinute"
     case onePerMinute = "1RecordMinute"
 }
 ```
 */
public protocol FilterItemEnumValue: RawRepresentable, FilterItemValueCodable {}

public extension FilterItemEnumValue {

    var queryValue: String { "\(rawValue)" }
}

// MARK: - DefaultFilterItemKey

public enum DefaultFilterItemKey: String, JAFilterItemProtocol.KeyProtocol {
    case na
}

// MARK: - EmptyFilterItem

public enum EmptyFilterItem: JAFilterItemProtocol {}
