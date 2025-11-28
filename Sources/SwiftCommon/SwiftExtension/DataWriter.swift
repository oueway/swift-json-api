//
//  DataWriter.swift
//
//  Created by Brandee on 11/17/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//

import Foundation

// MARK: - DataWriter

public actor DataWriter {

    public let url: URL
    public let autoClose: Bool
    private var fileHandle: FileHandle?

    public var currentSize: UInt64 {
        do {
            return try ensuerFileHandleOpen().offset()
        } catch {
            MyLogger.common?.error("DataWriter: currentSize error:", error)
            return 0
        }
    }

    // MARK: Lifecycle

    public init(url: URL, autoClose: Bool = true) {
        self.url = url
        self.autoClose = autoClose
        MyLogger.common?.log("[DataWriter]", url.relativePath)

        // create file if needed
        if FileManager.default.fileExists(atPath: url.relativePath) { return }
        FileManager.default.createFile(atPath: url.relativePath, contents: nil)
    }

    // MARK: Public

    public func close() throws {
        try fileHandle?.close()
        fileHandle = nil
    }

    public func append(_ data: Data) throws {
        if fileHandle == nil {
            fileHandle = try FileHandle(forWritingTo: url)
        }

        let fileHandle = try ensuerFileHandleOpen()

        defer {
            if autoClose {
                try? fileHandle.close()
                self.fileHandle = nil
            }
        }

        try fileHandle.write(contentsOf: data)
    }

    public func append(_ text: String) throws {
        guard let data = text.data(using: .utf8) else {
            throw MyError.local("Cannot convert to data")
        }

        try append(data)
    }

    @inlinable
    public func appendLine(_ text: String) throws {
        try append("\(text)\n")
    }

    // MARK: Private

    private func ensuerFileHandleOpen() throws -> FileHandle {
        if fileHandle == nil {
            fileHandle = try FileHandle(forWritingTo: url)
        }

        guard let fileHandle else {
            throw MyError.local("File handle is nil")
        }

        try fileHandle.seekToEnd()
        return fileHandle
    }
}
