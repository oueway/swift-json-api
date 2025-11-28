//
//  FilterItemProtocol.swift
//  SwiftJsonApi
//
//  Created by Brandee on 11/26/25.
//

import Foundation

// MARK: - FilterItemProtocol

/**
 The ``FilterItemProtocol`` makes it easy to list filters. It automatically interprets, connects, and encodes query and query values for service APIs.

 Implement ``FilterItemProtocol`` using an `enum` to list all filter cases with parameter types.
    * `Case Name` is the default query name of the service API. Define a ``Key`` enum to handle query names differently.
    * `String Interpolation` is the default method to handle all kinds of value types. Use ``FilterItemValueCodable`` to handle value differently.
    * See the `FilterItem` in the example.

 ```
 public enum FilterItem: FilterItemProtocol {

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
public protocol FilterItemProtocol {
    typealias KeyProtocol = CaseIterable & StringRawRepresentable

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

// MARK: - FilterItemProtocol Implementations

extension FilterItemProtocol {
    public var keyValues: [String: Any] {
        let mirror = Mirror(reflecting: self)

        guard let label = mirror.children.first?.label,
              let value = mirror.children.first?.value
        else {
            return [:]
        }

        if let pairs = mutiplePairs(label: label, value: value) {
            return pairs
        }

        return [key(from: label): value]
    }

    /// Method to handle multiple queries in one filter
    private func mutiplePairs(label: String, value: Any) -> [String: Any]? {
        let paramsMirror = Mirror(reflecting: value)
        var result = [String: Any]()

        if paramsMirror.children.isEmpty { return nil }

        for param in paramsMirror.children {
            guard let paramLabel = param.label else { continue }
            let key = key(from: jointLabel(label, and: paramLabel))
            result[key] = param.value
        }

        return result.isEmpty ? nil : result
    }

    /// Method of making joint label using filter name and param name
    private func jointLabel(_ label: String, and paramLabel: String) -> String {
        label + paramLabel.prefix(1).uppercased() + String(paramLabel.dropFirst())
    }

    /// Method to generate key of the query
    private func key(from label: String) -> String {
        Self.Key.allCases
            .first {
                label == "\($0)"
            }?
            .rawValue as? String
            ?? label
    }
}



// MARK: - DefaultFilterItemKey

public enum DefaultFilterItemKey: String, FilterItemProtocol.KeyProtocol {
    case na
}

// MARK: - EmptyFilterItem

public enum EmptyFilterItem: FilterItemProtocol {}

