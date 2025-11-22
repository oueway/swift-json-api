//
//  JASelfLinks.swift
//
//  Created by Brandee on 11/17/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//

import Foundation


public struct JASelfLinks: Codable {
    public let linksSelf: String

    enum CodingKeys: String, CodingKey {
        case linksSelf = "self"
    }

    // - creation

    public init(linksSelf: String) {
        self.linksSelf = linksSelf
    }
}
