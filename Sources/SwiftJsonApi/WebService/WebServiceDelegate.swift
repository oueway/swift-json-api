//
//  WebServiceDelegate.swift
//  SwiftJsonApi
//
//  Created by Brandee on 11/18/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//

import Foundation

/// Protocol that the web service uses to obtain runtime configuration and
/// to surface authentication events back to the host application.
public protocol WebServiceDelegate: AnyObject {
    /// The base API endpoint used to resolve relative resource paths.
    var apiEndpoint: URL { get }

    /// Optional bearer/access token used for authenticated requests.
    /// If you have customized your authentication method, you can add it to `additionalHeaders`.
    var accessToken: String? { get }

    /// Reports whether the current access token is expired and should be refreshed before making further requests.
    var isTokenExpired: Bool { get }

    /// Optional pagination configuration used by the service when building requests that support paged results.
    /// If `nil`, the service will not append pagination query items automatically.
    /// Use `.default` to adopt the conventional `offset`/`limit` keys.
    var paginationParams: PaginationParams? { get }

    /// Additional HTTP headers to include with every request.
    /// Values here are merged with the service's defaults;
    /// keys in this dictionary override any duplicates from defaults.
    /// Return `nil` to send only the standard headers.
    var additionalHeaders: [String: String]? { get }

    /// The concrete `Decodable` type that represents API error payloads returned by the server.
    /// The web service uses this type to decode error responses for better diagnostics and surfacing
    /// user-facing messages. For a JSON:API-compliant backend, return `JAErrors.self`.
    var apiErrorType: (Error & Decodable).Type { get }

    /// Called when the service receives an HTTP 401 Unauthorized response.
    /// Implement this to trigger a token refresh or sign-out flow.
    func didReceiveUnauthorizedError()

    /// Called when the service receives an HTTP 403 Forbidden response.
    /// Implement this to show an appropriate permission error to the user.
    func didReceiveForbiddenError()
}

/// Describes the query parameter names used to request paginated data.
/// Many APIs use different keys for the page/index and page size.
/// Use this type to configure how the web service constructs pagination query items.
public struct PaginationParams {
    /// The query parameter key that represents the current page, index, cursor, or offset depending on the API's pagination style.
    public let indexKey: String

    /// The query parameter key that represents the number of items to request
    /// per page (e.g., `limit` or `size`).
    public let sizeKey: String

    public init(indexKey: String, sizeKey: String) {
        self.indexKey = indexKey
        self.sizeKey = sizeKey
    }

    /// The default preset, equivalent to `.offsetLimit`.
    /// Uses `offset` for the starting position and `limit` for the page size.
    public static let `default` = offsetLimit

    /// Uses `offset`/`limit` pagination, common in REST APIs.
    public static let offsetLimit = PaginationParams(indexKey: "offset", sizeKey: "limit")

    /// Uses `cursor`/`limit` pagination, often returned by APIs that provide
    /// opaque cursors for stable traversal.
    public static let cursorLimit = PaginationParams(indexKey: "cursor", sizeKey: "limit")

    /// Uses `index`/`size` pagination, where `index` is a zero- or one-based
    /// page indicator and `size` is the number of items per page.
    public static let indexSize = PaginationParams(indexKey: "index", sizeKey: "size")

    /// Uses `page`/`size` pagination, where `page` is the page number and
    /// `size` is the number of items per page.
    public static let pageIndexSize = PaginationParams(indexKey: "page", sizeKey: "size")
}
