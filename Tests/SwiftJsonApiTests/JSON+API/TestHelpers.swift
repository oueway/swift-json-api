//
//  TestHelpers.swift
//
//  Created by Oueway Forest on 11/25/25.
//

import Foundation
@testable import SwiftJsonApi

// MARK: - Mock WebServiceDelegate

class MockWebServiceDelegate: WebServiceDelegate {
    var apiEndpoint: URL
    var accessToken: String?
    var isTokenExpired: Bool
    var unauthorizedErrorCalled = false
    var forbiddenErrorCalled = false
    let paginationParams: PaginationParams?
    let additionalHeaders: [String: String]?
    var apiErrorType: any (Decodable & Error).Type

    init(apiEndpoint: URL = URL(string: "https://api.example.com")!, accessToken: String? = "test-token", isTokenExpired: Bool = false, unauthorizedErrorCalled: Bool = false, forbiddenErrorCalled: Bool = false, paginationParams: PaginationParams? = nil, additionalHeaders: [String: String]? = nil, apiErrorType: any (Decodable & Error).Type = JAErrors.self) {
        self.apiEndpoint = apiEndpoint
        self.accessToken = accessToken
        self.isTokenExpired = isTokenExpired
        self.unauthorizedErrorCalled = unauthorizedErrorCalled
        self.forbiddenErrorCalled = forbiddenErrorCalled
        self.paginationParams = paginationParams
        self.additionalHeaders = additionalHeaders
        self.apiErrorType = apiErrorType
    }

    func didReceiveUnauthorizedError() {
        unauthorizedErrorCalled = true
    }

    func didReceiveForbiddenError() {
        forbiddenErrorCalled = true
    }
}

// MARK: - Mock Datum for Testing

struct MockDatum: JADatumProtocol {
    static let typeName: String = "mock"

    let id: String
    let type: String
    let links: JASelfLinks
    let attributes: Attributes
    let relationships: Relationships?

    struct Attributes: Codable {
        let name: String
        let value: Int
    }

    struct Relationships: Codable {
        let related: JARelationship<MockDatum>?
    }

    init(id: String = "1",
         links: JASelfLinks = JASelfLinks(linksSelf: "https://api.example.com/mock/1"),
         attributes: Attributes = Attributes(name: "test", value: 100),
         relationships: Relationships? = nil)
    {
        self.id = id
        self.type = Self.typeName
        self.links = links
        self.attributes = attributes
        self.relationships = relationships
    }

    func resolveRelationships(fromIncludes includes: [String: [JAAnyDatum]]) -> MockDatum {
        guard let relationships = relationships,
              let relatedRelationship = relationships.related,
              let resolved = relatedRelationship.resolved(fromIncludes: includes)
        else {
            return self
        }

        let newRelationships = Relationships(related: resolved)
        return MockDatum(
            id: id,
            links: links,
            attributes: attributes,
            relationships: newRelationships
        )
    }
}

// MARK: - Test Utilities

extension JAResponse {
    static func createMockResponse(data: [Datum] = [],
                                   included: [JADynamicDatum]? = nil,
                                   links: Links? = nil,
                                   meta: Meta? = nil) -> JAResponse<Datum>
    {
        JAResponse(data: data, included: included, links: links, meta: meta)
    }
}

extension JAResponse.Links {
    static func createMock(linksSelf: String? = nil,
                           related: String? = nil,
                           first: String? = nil,
                           last: String? = nil,
                           next: String? = nil,
                           prev: String? = nil) -> JAResponse.Links
    {
        JAResponse.Links(
            linksSelf: linksSelf,
            related: related,
            first: first,
            last: last,
            next: next,
            prev: prev
        )
    }
}

// MARK: - JSON Test Data

enum JSONTestData {
    static let singleDatumJSON = """
    {
        "id": "1",
        "type": "mock",
        "attributes": {
            "name": "test",
            "value": 100
        },
        "links": {
            "self": "https://api.example.com/mock/1"
        }
    }
    """

    static let multipleDataJSON = """
    [
        {
            "id": "1",
            "type": "mock",
            "attributes": {
                "name": "test1",
                "value": 100
            },
            "links": {
                "self": "https://api.example.com/mock/1"
            }
        },
        {
            "id": "2",
            "type": "mock",
            "attributes": {
                "name": "test2",
                "value": 200
            },
            "links": {
                "self": "https://api.example.com/mock/2"
            }
        }
    ]
    """

    static let responseWithDataJSON = """
    {
        "data": {
            "id": "1",
            "type": "mock",
            "attributes": {
                "name": "test",
                "value": 100
            },
            "links": {
                "self": "https://api.example.com/mock/1"
            }
        },
        "links": {
            "self": "https://api.example.com/mock",
            "first": "https://api.example.com/mock?page=1",
            "last": "https://api.example.com/mock?page=10",
            "next": "https://api.example.com/mock?page=2"
        },
        "meta": {
            "totalResourceCount": 100
        }
    }
    """

    static let responseWithArrayJSON = """
    {
        "data": [
            {
                "id": "1",
                "type": "mock",
                "attributes": {
                    "name": "test1",
                    "value": 100
                },
                "links": {
                    "self": "https://api.example.com/mock/1"
                }
            }
        ]
    }
    """
}
