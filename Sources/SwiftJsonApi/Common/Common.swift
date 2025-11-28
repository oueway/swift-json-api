//
//  Common.swift
//  SwiftJsonApi
//
//  Created by Brandee on 11/20/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//

import Foundation
import SwiftCommon

/// A marker protocol for enums backed by String raw values.
public protocol StringRawRepresentable: RawRepresentable where Self.RawValue == String {}

public let domain = "com.oueway.jsonapi"
public let errorDomain = "\(domain).error"

/// Logging utilities for the JSON:API module.
extension MyLogger {
    nonisolated(unsafe) static var jsonApi: MyLogger?

    // MARK: Public

    /// Configure a dedicated logger for the JSON:API subsystem.
    /// - Parameter level: The desired logging level. Defaults to `.default`.
    public class func setJsonApiLog(level: Level = .default) {
        jsonApi = MyLogger.create(moduleName: "JSON:API", for: level)
    }
}

public typealias MyError = SwiftCommon.MyError
public typealias MyLogger = SwiftCommon.MyLogger

extension NSError: ErrorWithCode {
    convenience init(httpUrlResponse: HTTPURLResponse?, message: String? = nil) {
        self.init(
            domain: errorDomain,
            code: httpUrlResponse?.statusCode ?? -1,
            userInfo: [
                NSLocalizedDescriptionKey: (httpUrlResponse?.url?.absoluteString ?? "") + ": \(message ?? "")"
            ]
        )
    }

    convenience init(code: Int?, message: String? = nil) {
        self.init(
            domain: errorDomain,
            code: code ?? -1,
            userInfo: [
                NSLocalizedDescriptionKey: message ?? ""
            ]
        )
    }
}
