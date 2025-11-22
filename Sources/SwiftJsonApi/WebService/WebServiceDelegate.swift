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
    var accessToken: String? { get }

    /// Reports whether the current access token is expired and should be
    /// refreshed before making further requests.
    var isTokenExpired: Bool { get }

    /// Called when the service receives an HTTP 401 Unauthorized response.
    /// Implement this to trigger a token refresh or sign-out flow.
    func didReceiveUnauthorizedError()

    /// Called when the service receives an HTTP 403 Forbidden response.
    /// Implement this to show an appropriate permission error to the user.
    func didReceiveForbiddenError()
}
