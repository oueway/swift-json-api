//
//  FilesStore.swift
//  
//
//  Created by Brandee on 11/17/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//

import Foundation

public struct FilesStore {
    public static let applicationDocumentsDirectory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

    public static let userDocumentsDirectory: URL? = FileManager.default.urls(for: .documentationDirectory, in: .userDomainMask).first

    public static let userDownloadsDirectory: URL? = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first

    // MARK: Public

    public static func autoCreateFolders(for url: URL) {
        do {
            if FileManager.default.fileExists(atPath: url.path) { return }
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            autoCreateFolders(for: url.deletingLastPathComponent())
        } catch let error as NSError {
            MyLogger.common?.error("[FilesStore] create folder error:", error.localizedDescription)
        }
    }

    public static func saveUrl(forFile name: String) -> URL {
        let url = (userDownloadsDirectory ?? applicationDocumentsDirectory).appendingPathComponent(name)
        autoCreateFolders(for: url.deletingLastPathComponent())
        return url
    }

    public static func documentURL(forFile name: String) -> URL {
        applicationDocumentsDirectory.appendingPathComponent(name)
    }
}
