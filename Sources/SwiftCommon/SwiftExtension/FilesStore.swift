//
//  FilesStore.swift
//  
//
//  Created by Brandee on 11/17/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//

import Foundation

/// A small helper for locating or creating platform file-system directories
/// used by the library. All APIs are static convenience helpers.
public struct FilesStore {
    /// The app's Documents directory (guaranteed non-nil on typical platforms).
    /// Falls back to the first `documentDirectory` returned by `FileManager`.
    public static let applicationDocumentsDirectory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

    /// The user's documentation directory, if available on the platform.
    public static let userDocumentsDirectory: URL? = FileManager.default.urls(for: .documentationDirectory, in: .userDomainMask).first

    /// The user's downloads directory, if available on the platform.
    public static let userDownloadsDirectory: URL? = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first

    // MARK: Public

    /// Ensure all folders in the provided `url` path exist by creating
    /// any missing directories. If the path already exists nothing is done.
    ///
    /// - Note: Errors are logged via `MyLogger` instead of being thrown.
    /// - Parameter url: The file or directory URL whose parent folders should exist.
    public static func autoCreateFolders(for url: URL) {
        do {
            if FileManager.default.fileExists(atPath: url.path) { return }
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            autoCreateFolders(for: url.deletingLastPathComponent())
        } catch let error as NSError {
            MyLogger.common?.error("[FilesStore] create folder error:", error.localizedDescription)
        }
    }

    /// Returns a writable URL for a file name located in the user's downloads
    /// directory when available, otherwise the app documents directory is used.
    ///
    /// The method will create any missing parent directories before returning.
    /// - Parameter name: The file name to create a URL for.
    /// - Returns: A `URL` where the file can be saved.
    public static func saveUrl(forFile name: String) -> URL {
        let url = (userDownloadsDirectory ?? applicationDocumentsDirectory).appendingPathComponent(name)
        autoCreateFolders(for: url.deletingLastPathComponent())
        return url
    }

    /// Returns a URL inside the app's documents directory for the given file name.
    /// - Parameter name: The file name to create a documents URL for.
    /// - Returns: The documents `URL` for the named file.
    public static func documentURL(forFile name: String) -> URL {
        applicationDocumentsDirectory.appendingPathComponent(name)
    }
}
