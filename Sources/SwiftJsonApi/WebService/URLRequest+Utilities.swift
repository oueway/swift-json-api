//
//  WebService+Request.swift
//
//
//  Created by Brandee on 11/18/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//

import CryptoKit
import Foundation

// MARK: - Create Request Helpers

extension URLRequest {
    static func formData(withQueryItems queryItems: [URLQueryItem]) throws -> Data {
        var urlQuery = URLComponents()
        urlQuery.queryItems = queryItems

        guard let data = urlQuery.percentEncodedQuery?.data(using: .utf8) else {
            throw MyError.local("Generate x-www-form-urlencoded data failed!")
        }

        return data
    }

    static func jsonData(withKeyValues keyValues: [String: Any]?) throws -> Data {
        guard let keyValues = keyValues else { return Data() }
        return try JSONEncoder.iso8601UTC.encode(EncodableConverter(keyValues: keyValues))
    }
}

// MARK: - EncodableConverter

private struct EncodableConverter: Encodable {
    let keyValues: [String: Any]

    // MARK: Internal

    struct CodingKeys: CodingKey {
        let stringValue: String

        var intValue: Int? { Int(stringValue) }

        // MARK: Lifecycle

        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { self.stringValue = String(intValue) }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        for item in keyValues {
            let key = CodingKeys(stringValue: item.0)!
            switch item.1 {
            case let value as FilterItemValueCodable:
                try container.encode(value.queryValue, forKey: key)
            case let value as [FilterItemValueCodable]:
                try container.encode(value.map { $0.queryValue }, forKey: key)
            case let value as Encodable:
                try value.encode(to: container.superEncoder(forKey: key))
            case let value as [String: Any]:
                try container.encode(EncodableConverter(keyValues: value), forKey: key)
            default: break
            }
        }
    }
}

// MARK: - URLRequest Helpers

public extension URLRequest {
    // TODO: public as supported Types
    enum ContentType: String {
        case formUrlEncoded = "application/x-www-form-urlencoded"
        case json = "application/json;charset=UTF-8"
        case jsonAPI = "application/vnd.api+json"
    }

    internal var uniqueID: String {
        let urlString = url?.absoluteString ?? ""

        guard let data = httpBody else {
            return urlString
        }

        return urlString + Insecure.MD5.hash(data: data)
            .map {
                String(format: "%02hhx", $0)
            }.joined()
    }

    // MARK: Lifecycle

    private init(wsUrl url: URL, timeoutInterval: TimeInterval = 10, authorization: String? = nil) {
        self.init(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: timeoutInterval)
        // TODO: extract defaultBearerToken
        setValue(authorization ?? "Bearer " + (WebService.shared?.delegate.accessToken ?? ""), forHTTPHeaderField: "Authorization")
        setValue(ContentType.json.rawValue, forHTTPHeaderField: "Accept")
        setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        // TODO: override with custom headers
    }

    // MARK: Public

    static func get(from url: URL) -> URLRequest {
        var request = URLRequest(wsUrl: url)
        request.httpMethod = "GET"
        return request
    }

    static func post(to url: URL, data: Data, contentType: ContentType = .json, authorization: String? = nil) -> URLRequest {
        var request = URLRequest(wsUrl: url, authorization: authorization)
        request.httpMethod = "POST"
        request.setValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        return request
    }

    static func put(to url: URL, data: Data, contentType: ContentType = .json) -> URLRequest {
        var request = URLRequest(wsUrl: url)
        request.httpMethod = "PUT"
        request.setValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        return request
    }

    static func delete(from url: URL) -> URLRequest {
        var request = URLRequest(wsUrl: url)
        request.httpMethod = "DELETE"
        return request
    }

    // MARK: Internal

    internal func debugLog() {
        MyLogger.jsonApi?.debugAsync {
            var messages = [String]()
            if let httpMethod { messages.append(httpMethod) }
            if let urlStr = url?.absoluteString { messages.append(urlStr) }
            if let allHTTPHeaderFields { messages.append("\(allHTTPHeaderFields)") }
            return messages
        }

        MyLogger.jsonApi?.logAsync {
            guard let data = httpBody, !data.isEmpty,
                  let string = String(data: data, encoding: .utf8)
            else {
                return []
            }
            return [string]
        }
    }
}

extension URL {
    static func urlFromPath(_ path: String, queryItems: [URLQueryItem]? = nil) -> URL {
        let endpoint = WebService.shared?.delegate.apiEndpoint ??
            URL(string: "https://Config-Public-API-Endpoint-URL-Goes-Here.com")!

        var url = URL(string: path, relativeTo: endpoint) ?? URL(string: "https://Error-Creating-URL.com")!
        if let queryItems {
            url.append(queryItems: queryItems) // TODO: check: urlQuery.percentEncodedQuery
        }

        return url
    }
}
