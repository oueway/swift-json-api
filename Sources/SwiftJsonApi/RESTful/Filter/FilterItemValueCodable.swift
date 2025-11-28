//
//  FilterItemValueCodable.swift
//  SwiftJsonApi
//
//  Created by Brandee on 11/26/25.
//

import Foundation

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

// MARK: - LocaleID + FilterItemValueCodable

public enum LocaleID: FilterItemValueCodable {
    case current
    case locale(Locale)

    public var queryValue: String {
        let locale: Locale
        switch self {
        case .current:
            locale = .current
        case let .locale(l):
            locale = l
        }

        return locale.identifier.replacingOccurrences(of: "_", with: "-")
    }
}
