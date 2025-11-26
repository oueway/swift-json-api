//
//  MyError.swift
//
//  Created by Brandee on 11/17/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//

import Foundation

// MARK: - MyError

/// Application-level errors used throughout the library.
///
/// Use `MyError` to represent local, server, storage and underlying
/// failures in a consistent way. `LocalizedError` conformance provides
/// user-facing messages.
public enum MyError: Error {
    /// special error: when login user switched caused a stop of API call
    case userSwitched

    /// special error: a placeholder of an optional, OR cannot define the error reason
    case unknown

    /// error category generate local errors that represent all kinds of errors that are not from servers.
    /// The error message will show whatever the String provides.
    case local(String)

    /// error category app error is the native code error that we haven't handled in special cases.
    /// The error message shows "App Error: {String}"
    case app(String)

    /// error category storage error is because a failure happened in storage.
    /// The error message shows "Storage Error: {String}"
    case storage(String)

    /// error category server error is a case that error caused by server.
    /// The error message shows "Server Error: {String}"
    case server(String)

    /// error category underlayer error is a failure that happened with an error.
    /// The error message shows whatever the underlayer error provided.
    case underlayer(Error)
    
    /// error category underlayer error is a failure that happened with multiple errors.
    /// The error message shows whatever the underlayer errors provided.
    case underlayers([Error])

    /// error category underlayer error is a failure that happened with an error.
    /// The error message shows whatever the underlayer error provided.
    case underlayerWithCode(ErrorWithCode)

    /// special app error on failed to encode post content
    public static let encodeRequestFailure = Self.app("Can not encode your request.")
}

// MARK: LocalizedError

extension MyError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .userSwitched: return "User Changed."
        case .unknown: return "Unknown error."
        case let .local(message): return message
        case let .app(message): return "App Error: \(message)"
        case let .storage(message): return "Storage Error: \(message)"
        case let .server(message): return "Server Error: \(message)"
        case let .underlayer(error): return error.localizedDescription
        case let .underlayers(errors): return errors.map(\.localizedDescription).joined(separator: "\n")
        case let .underlayerWithCode(error):
            return "[\(error.code)] \(error.localizedDescription)"
        }
    }

    public var failureReason: String? {
        guard case let .underlayer(error) = self else {
            return errorDescription
        }

        return (error as NSError).localizedFailureReason
    }
}

// MARK: - ErrorWithCode

/// An error that exposes an integer `code` in addition to standard
/// `LocalizedError` information. Useful for mapping HTTP or domain-specific
/// numeric error identifiers back to application behavior.
public protocol ErrorWithCode: LocalizedError {
    var code: Int { get }
}

extension NSError: @retroactive LocalizedError {}

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
