//
//  JAError.swift
//
//  Created by Brandee on 11/17/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//

import Foundation

// MARK: - JAErrors Type

struct JAErrors: Codable {
    let errors: [JAError]
}

// MARK: - JAError Type

/**
 https://jsonapi.org/format/#errors
 {
   "id": "f82b5d8e-8f2a-4d9",
   "status": "422",
   "code": "VALIDATION_ERROR",
   "title": "Invalid Attribute",
   "detail": "Email format error",
   "source": {
     "pointer": "/data/attributes/email"
   },
 "links": {},
 "meta": {}
 }
 */
struct JAError: Codable, Error {
    let id: String?
    let status: String?
    let code: String?
    let title: String?
    let detail: String?
    let meta: JAMeta?

    var statusValue: Int? { Int(status ?? "-1") }

    init(id: String? = nil, status: String, code: String?, title: String?, detail: String?, meta: JAMeta? = nil) {
        self.id = id
        self.status = status
        self.code = code
        self.title = title
        self.detail = detail
        self.meta = meta
    }
}

// MARK: - JAMeta

struct JAMeta: Codable {
    let type: String?
    let path: String?
    let timestamp: Date?
}

// MARK: - NSError for JAError

extension NSError {
    convenience init(jsonApiError error: JAError, response: URLResponse?) {
        self.init(
            domain: errorDomain,
            code: error.statusValue ?? (response as? HTTPURLResponse)?.statusCode ?? -1,
            userInfo: [
                NSLocalizedFailureReasonErrorKey: error.code ?? error.title ?? "",
                NSLocalizedDescriptionKey: error.detail ?? error.title ?? "",
                NSLocalizedFailureErrorKey: error.meta?.type ?? error.title ?? ""
            ]
        )
    }
}
