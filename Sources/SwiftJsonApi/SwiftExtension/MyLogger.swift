//
//  MyLogger.swift
//
//  Created by Brandee on 11/17/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//

import Foundation
import OSLog
#if canImport(WebKit)
import WebKit
#endif

// MARK: - MyLogger

public class MyLogger {
    public enum Level: Int {
        case debug = 0, `default`, warning, error
    }

    #if USE_OSLOG
    fileprivate let osLogger: os.Logger
    #else
    fileprivate static let logWriter = DataWriter(
        url: FilesStore.documentURL(
            forFile: "log-\(Date().formatted(withFormat: "yyyy-MM-dd")).log"
        )
    )
    fileprivate let moduleName: String
    #endif

    public nonisolated(unsafe) static var app: MyLogger?
    public nonisolated(unsafe) static var common: MyLogger?

    // MARK: Lifecycle

    fileprivate init(module: String) {
        #if USE_OSLOG
        self.osLogger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: module)
        #else
        self.moduleName = module
        #endif
    }

    // MARK: Public

    public class func setAppLogLevel(_ level: Level = .default) {
        app = MyLogger.create(for: level)
    }

    public class func setCommonLogLevel(_ level: Level = .default) {
        common = MyLogger.create(moduleName: "Common", for: level)
    }

    public class func create(moduleName: String = "App", for level: Level) -> MyLogger {
        switch level {
        case .debug: return AllLogger(module: moduleName)
        case .default: return DefaultLogger(module: moduleName)
        case .warning: return WarningLogger(module: moduleName)
        case .error: return ErrorLogger(module: moduleName)
        }
    }

    // MARK: - log methods

    public func debug(_ items: Any...) {}
    public func log(_ items: Any...) {}
    public func warning(_ items: Any...) {}
    public func error(_ items: Any...) {}
    public func fault(_ items: Any...) {}

    // MARK: - async log methods

    // Delay calls to avoid unnecessary computations

    public func debugAsync(_ getItems: () -> [Any]) {}
    public func logAsync(_ getItems: () -> [Any]) {}
    public func warningAsync(_ getItems: () -> [Any]) {}
    public func errorAsync(_ getItems: () -> [Any]) {}
    public func faultAsync(_ getItems: () -> [Any]) {}

    // MARK: Fileprivate

    fileprivate static func connectedParams(_ items: [Any]) -> String {
        var ret = ""
        for item in items {
            ret += "\(item) "
        }
        return ret
    }

    fileprivate func connectAndPrint(_ type: OSLogType?, _ items: [Any]) {
        #if USE_OSLOG
        osLogger.log(level: type, "[\(type.typeName, privacy: .public)] \(Self.connectedParams(items), privacy: .public)")
        #else
        let cnnectedString = "\(type?.icon ?? "⚠️") \(Date().formatted(withFormat: "MMddzzzhh:mm:ss")) [\(moduleName)] \(Self.connectedParams(items))"
        print(cnnectedString)
        Task {
            try await Self.logWriter.appendLine(cnnectedString)
        }
        #endif
    }
}

private extension Date {
    func formatted(withFormat format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}

// MARK: - ErrorLogger

private class ErrorLogger: MyLogger {
    override func faultAsync(_ getItems: () -> [Any]) {
        fault(getItems())
    }

    override func fault(_ items: Any...) {
        connectAndPrint(.fault, items)
    }

    override func errorAsync(_ getItems: () -> [Any]) {
        error(getItems())
    }

    override func error(_ items: Any...) {
        connectAndPrint(.error, items)
    }
}

// MARK: - WarningLogger

private class WarningLogger: ErrorLogger {
    override func warningAsync(_ getItems: () -> [Any]) {
        warning(getItems())
    }

    override func warning(_ items: Any...) {
        connectAndPrint(nil, items)
    }
}

// MARK: - DefaultLogger

private class DefaultLogger: WarningLogger {
    override func logAsync(_ getItems: () -> [Any]) {
        log(getItems())
    }

    override func log(_ items: Any...) {
        connectAndPrint(.default, items)
    }
}

// MARK: - AllLogger

private class AllLogger: DefaultLogger {
    override func debugAsync(_ getItems: () -> [Any]) {
        debug(getItems())
    }

    override func debug(_ items: Any...) {
        connectAndPrint(.debug, items)
    }
}

// MARK: - Get Log File

public extension MyLogger {
    #if canImport(WebKit)
    func generateDisplayView() -> WKWebView {
        let webView = WKWebView()

        if let logURL = MyLogger.getLogFile() {
            webView.load(URLRequest(url: logURL))
        }

        return webView
    }
    #endif

    #if USE_OSLOG
    @available(iOS 15.0, *)
    class func getLogFile(from: Date? = nil, fileName: String = "log-\(Date()).log") -> URL? {
        guard let fileUrl = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent(fileName)
        else {
            MyLogger.common?.error("get log file failed:", "cannot create file")
            return nil
        }

        return extractLogs(from: from, saveTo: fileUrl)
    }
    #else
    class func getLogFile() -> URL? { MyLogger.logWriter.url }
    #endif

    // MARK: Private

    #if USE_OSLOG
    @available(iOS 15.0, *)
    private static func extractLogs(from: Date?, saveTo fileUrl: URL) -> URL? {
        do {
            var postion: OSLogPosition?
            let osLogStore = try OSLogStore(scope: .currentProcessIdentifier)
            if let from = from {
                postion = osLogStore.position(date: from)
            }

            let predicate = NSPredicate(format: "subsystem == %@", Bundle.main.bundleIdentifier ?? "")
            let logContent = try osLogStore.getEntries(at: postion, matching: predicate)
                .reduce("") { partialResult, entry in
                    guard let entry = entry as? OSLogEntryLog else {
                        return partialResult
                    }
                    return "\(partialResult)\n\(entry.date) [\(entry.category)] \(entry.composedMessage)"
                }

            try logContent.write(to: fileUrl, atomically: true, encoding: .utf8)

            return fileUrl
        } catch {
            MyLogger.common?.error("get log file failed:", error)
        }

        return nil
    }
    #endif
}

extension OSLogType {
    var typeName: String {
        switch self {
        case .default: return "Log"
        case .debug: return "Debug"
        case .error: return "Error"
        case .info: return "Info"
        case .fault: return "Fault"
        default: return "Unknown"
        }
    }

    var icon: String {
        switch self {
        case .default: return "📄"
        case .debug: return "🟢"
        case .error: return "🔴"
        case .info: return "📀"
        case .fault: return "❌"
        default: return "⁉️"
        }
    }
}
