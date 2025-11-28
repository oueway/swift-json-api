//
//  ISO8601.swift
//
//  Created by Brandee on 11/17/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//

import Foundation

// MARK: - JSONDecoder + ISO8601

/// Convenience ISO 8601 utilities for decoding JSON payloads.
///
/// Use these helpers when you need consistent, backend-compatible
/// ISO 8601 parsing that supports fractional seconds (0, 3, 6, or 9 digits).
public extension JSONDecoder {

    /// A shared `JSONDecoder` configured to decode ISO 8601 dates using
    /// the `iso8601StandardDecodingStrategy` defined below.
    ///
    /// This decoder attempts multiple ISO 8601 formats and supports
    /// fractional-second precision variants that some servers emit.
    static let iso8601Standard: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = iso8601StandardDecodingStrategy
        return decoder
    }()

    /// A custom `DateDecodingStrategy` that tries a set of ISO 8601 formatters
    /// until one successfully parses the input string. Throws on failure.
    static let iso8601StandardDecodingStrategy: JSONDecoder.DateDecodingStrategy = .custom { decoder in
        var container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)

        for formatter in ISO8601DateFormatter.allSupportFormatters {
            if let date = formatter.date(from: text) {
                return date
            }
        }

        throw MyError.app("Cannot decode time \(text) error!")
    }

    // MARK: formatters
}

// MARK: - JSONEncoder + ISO8601

public extension JSONEncoder {

   /// A JSONDecoder instance using a customized DateEncodingStrategy.
    /// Encode to UTC time of standard ISO 8601 date format (3 nanosecond digits), which is our backend standard for accepting date values.
    static let iso8601UTC: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(DateFormatter.encodeISO8601UTC)
        return encoder
    }()
}

// MARK: - DateFormatter + ISO8601

public extension DateFormatter {
    
    /// A date formatter specfic to UTC time of standard ISO 8601 date format (3 nanosecond digits), which is our backend standard for accepting date values.
    static let encodeISO8601UTC: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        return dateFormatter
    }()
}

public extension ISO8601DateFormatter {

    nonisolated(unsafe) static let allSupportFormatters: [ISO8601DateFormatter] = [
        .decodeISO8601,
        .decodeISO8601Secondary,
        .decodeISO8601DateOnly
    ]

    /// A date formatter specfic to ISO 8601 date format with 1+ nanosecond digits
    nonisolated(unsafe) static let decodeISO8601: ISO8601DateFormatter = {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return dateFormatter
    }()

    /// A date formatter specfic to ISO 8601 date format without nanosecond digits
    nonisolated(unsafe) static let decodeISO8601Secondary: ISO8601DateFormatter = {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        return dateFormatter
    }()

    /// A date formatter specfic to ISO 8601 date format without time part
    nonisolated(unsafe) static let decodeISO8601DateOnly: ISO8601DateFormatter = {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        return dateFormatter
    }()
}
