//
//  GithubWebService.swift
//  SwiftJsonApi
//
//  Created by Brandee on 11/28/25.
//
import Foundation
import SwiftJsonApi

class GithubWebService: WebServiceDelegate {
    let apiEndpoint: URL = .init(string: "https://api.github.com")!
    
    var accessToken: String? { nil }
    
    var isTokenExpired: Bool { false }
    
    var paginationParams: PaginationParams? {
        PaginationParams(indexKey: "page", sizeKey: "per_page")
    }
    
    var additionalHeaders: [String: String]? {
        [
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28"
        ]
    }
    
    var apiErrorType: any (Decodable & Error).Type = GitHubApiError.self
    
    func didReceiveUnauthorizedError() {}
    
    func didReceiveForbiddenError() {}
}

struct GitHubApiError: Decodable, Error {}
