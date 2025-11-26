//
//  JASelfLinks.swift
//
//  Created by Brandee on 11/17/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//

import Foundation


/// Simple wrapper for the JSON:API `self` link on a resource.
public struct JASelfLinks: Codable {
    public let linksSelf: String

    enum CodingKeys: String, CodingKey {
        case linksSelf = "self"
    }


    public init(linksSelf: String) {
        self.linksSelf = linksSelf
    }
}
