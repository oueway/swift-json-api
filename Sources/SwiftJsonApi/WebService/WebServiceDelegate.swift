//
//  WebServiceDelegate.swift
//  SwiftJsonApi
//
//  Created by Brandee on 11/18/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//

import Foundation

public protocol WebServiceDelegate: AnyObject {
    var apiEndpoint: URL { get }
    var accessToken: String? { get }
    var isTokenExpired: Bool { get }

    func didReceiveUnauthorizedError()
    func didReceiveForbiddenError()
}
