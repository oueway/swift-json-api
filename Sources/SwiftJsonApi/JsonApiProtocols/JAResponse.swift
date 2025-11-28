//
//  JAResponse.swift
//
//  Created by Brandee on 11/17/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//

import Foundation

/// Wrapper for the top-level JSON:API response envelope containing
/// the primary `data`, optional `included` resources, pagination `links`
/// and `meta` information.
public struct JAResponse<Datum>: Codable where Datum: JADatumProtocol {
    /// The primary data payload (single or multiple resources).
    public let data: JADataOrDatas<Datum>

    /// Optional included resources referenced by the primary data.
    public let included: [JADynamicDatum]?
    public let links: Links?
    public let meta: Meta?

    // MARK: - ApolloResponseLinks

    /// Pagination and relationship links returned by the API.
    public struct Links: Codable {
        public let linksSelf, related: String?

        /// First/last/next/prev page links for paginated responses.
        public let first, last, next, prev: String?

        enum CodingKeys: String, CodingKey {
            case linksSelf = "self"
            case related
            case first, last, next, prev
        }

        // MARK: -  Creation

        /// An empty `Links` instance where every property is `nil`.
        public static var empty: Self {
            Links(linksSelf: nil, related: nil, first: nil, last: nil, next: nil, prev: nil)
        }

        public init(linksSelf: String?, related: String?, first: String?, last: String?, next: String?, prev: String?) {
            self.linksSelf = linksSelf
            self.related = related
            self.first = first
            self.last = last
            self.next = next
            self.prev = prev
        }
    }

    // MARK: - Meta

    /// Metadata returned by the API, such as total resource count.
    public struct Meta: Codable {
        /// Total number of resources available on the server.
        public let totalResourceCount: Int
    }

    // MARK: -  Computed Properties

    /// Convenience accessor returning the primary data as an array of `Datum`.
    public var datums: [Datum] { data.array }

    // MARK: - Creation

    /// An empty response instance with no data or metadata.
    public static var empty: Self {
        JAResponse(data: [], included: nil, links: .empty, meta: nil)
    }

    public init(data: [Datum], included: [JADynamicDatum]?, links: Links?, meta: Meta?) {
        self.data = JADataOrDatas<Datum>(datas: data)
        self.included = included
        self.links = links
        self.meta = meta
    }
}

extension JAResponse: SingleResponse, ListResponse {
    public typealias Item = Datum
    public var items: [Datum] { data.array }
    public var item: Item? { data.array.first }
}

// MARK: - Handle Included Section

extension JAResponse {
    func resolvedRelationshipsFromIncluded() -> Self {
        JAResponse(data: datumsWithResolvedRelationshipsFromIncluded(),
                   included: nil,
                   links: links,
                   meta: meta)
    }

    func datumsWithResolvedRelationshipsFromIncluded() -> [Datum] {
        guard let includes = mappedIncludes else { return datums }

        return datums.map {
            $0.resolveRelationships(fromIncludes: includes)
        }
    }

    var mappedIncludes: [String: [JAAnyDatum]]? {
        guard let included = included else { return nil }

        return included.reduce(into: [String: [JAAnyDatum]]()) { partialResult, dynamicDatum in
            var array = partialResult[dynamicDatum.datum.type] ?? []
            array.append(dynamicDatum.datum)
            partialResult[dynamicDatum.datum.type] = array
        }
    }
}

// MARK: - Handle Pages

public extension JAResponse {
    var hasNextPage: Bool {
        guard let nextLink = links?.next else { return false }
        let url = URL(string: nextLink)
        return url?.scheme != nil && url?.host != nil
    }

    func nextPage() async throws -> JAResponse<Datum>? {
        guard let nextPageRequest else { return nil }
        guard let webService = WebService.shared else {
            throw MyError.local("WebService is not set")
        }

        return try await webService.decodableTask(with: nextPageRequest)
    }

    mutating func updateWithNextPage() async throws {
        guard let nextPageResponse = try await nextPage() else { return }
        self = appending(nextPageResponse)
    }

    private var nextPageRequest: URLRequest? {
        guard let nextLink = links?.next else { return nil }

        let nextUrl: URL?
        if #available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *) {
            nextUrl = URL(string: nextLink, encodingInvalidCharacters: false)
        } else {
            nextUrl = URL(string: nextLink)
        }

        guard let nextUrl = nextUrl else { return nil }

        // Verify that the URL is a valid absolute URL (must contain scheme and host)
        guard nextUrl.scheme != nil,
              nextUrl.host != nil
        else {
            return nil
        }

        return URLRequest.get(from: nextUrl)
    }

    func appending(_ pageResponse: JAResponse<Datum>) -> JAResponse<Datum> {
        var newData = datums
        newData.append(contentsOf: pageResponse.datums)
        var newIncluded = included ?? pageResponse.included

        if included != nil, let nextPageIncluded = pageResponse.included {
            newIncluded?.append(contentsOf: nextPageIncluded)
        }

        return JAResponse(
            data: newData,
            included: newIncluded,
            links: .init(
                linksSelf: links?.linksSelf,
                related: links?.related,
                first: links?.first,
                last: pageResponse.links?.last,
                next: pageResponse.links?.next,
                prev: links?.prev
            ),
            meta: pageResponse.meta
        )
    }
}
