//
//  WebService.swift
//
//  Created by Brandee on 11/18/25.
//  Copyright © 2025 Oueway Studio. All rights reserved.
//

import Combine
import Foundation

public class WebService {
    public private(set) nonisolated(unsafe) static var shared: WebService?
    
    private static let configureLock = NSLock()

    private let runningState = TaskManagerRunningState()

    private(set) var delegate: WebServiceDelegate

    public enum Method {
        case get, post, put, delete
    }

    // MARK: Lifecycle

    private init(delegate: WebServiceDelegate) {
        self.delegate = delegate
    }

    // MARK: Public

    /// Configures the shared WebService singleton.
    ///
    /// Call this once during application startup to set up delegate handling.
    /// If `shared` has already been set and `force` is `false`, the call will be
    /// ignored and a warning will be logged. Passing `force = true` will update
    /// the existing instance's delegate.
    ///
    /// - Parameters:
    ///   - delegate: A `WebServiceDelegate` that receives lifecycle and request events.
    ///   - force: When `true`, replaces an existing configuration. Defaults to `false`.
    ///
    /// - Note: Ideally, call this only once. Subsequent calls without `force` will log
    ///   a duplicate configuration warning and return without changing the current setup.
    ///
    /// - Example:
    ///   ```swift
    ///   WebService.configure(delegate: MyServiceDelegate())
    ///   ```
    public static func configure(delegate: WebServiceDelegate, force: Bool = false) {
        configureLock.lock()
        defer { configureLock.unlock() }
        
        guard let shared else {
            shared = WebService(delegate: delegate)
            return
        }

        if force {
            MyLogger.jsonApi?.log("Force overridden of existing WebService configuration!")
            shared.delegate = delegate
        } else {
            MyLogger.jsonApi?.warning("Duplicate configure to WebService!")
        }
    }

    public func cleanAllRequests() async {
        await runningState.cleanAllRequests()
    }

    /** Create a WebService API request Publisher if you want to use Combine.

      WebService.shared.publishTask {
          try await WebService.shared.list(type: TaskManagerLocation.self)
      }
      .sink(receiveCompletion: { result in
          print("receiveCompletion", result)
      }, receiveValue: { value in
          print("receiveValue", value)
      })
      .store(in: &cancelables)
     */
    public func publishTask<T>(priority: TaskPriority = .userInitiated, _ action: @escaping () async throws -> T) -> AnyPublisher<T, Error> {
        Deferred {
            Future { promise in
                Task(priority: priority) {
                    do {
                        try promise(.success(await action()))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Due to inconsistent design of WebService API, some special APIs are not RESTful standard.
    /// Use `specialTask` to perform the call
    public func specialTask<T>(type: T.Type = T.self, method: Method, path: String, queries: [URLQueryItem]?, data: Data?) async throws -> T where T: Decodable {
        let request: URLRequest
        let url = URL.urlFromPath(path, queryItems: queries)

        switch method {
        case .get: request = .get(from: url)
        case .post: request = .post(to: url, data: data ?? Data())
        case .put: request = .put(to: url, data: data ?? Data())
        case .delete: request = .delete(from: url)
        }

        return try await decodableTask(with: request)
    }

    public func booleanTask(with request: URLRequest) async throws -> Bool {
        if delegate.isTokenExpired {
            throw MyError.local("Access token is expired.")
        }

        defer {
            Task {
                await runningState.finishRequest(request)
            }
        }

        try await runningState.preStartCheck(request: request)

        request.debugLog()

        let (data, response) = try await URLSession.shared.data(for: request)

        if let statusCode = (response as? HTTPURLResponse)?.statusCode,
           (200 ... 299).contains(statusCode)
        {
            return true
        } else {
            throw errorFromData(data, response: response, decoder: JSONDecoder.iso8601Standard)
        }
    }

    // MARK: Internal

    func decodableTask<T: Decodable>(with request: URLRequest, decoder: JSONDecoder = .iso8601Standard) async throws -> T {
        if delegate.isTokenExpired {
            throw MyError.local("Access token is expired.")
        }

        defer {
            Task {
                await runningState.finishRequest(request)
            }
        }

        try await runningState.preStartCheck(request: request)

        request.debugLog()

        let (data, response) = try await URLSession.shared.data(for: request)

        do {
            MyLogger.jsonApi?.debug("decoding:", String(data: data, encoding: .utf8) ?? "<nil>")
            if data.isEmpty,
               let type = T.self as? EmptyResponse.Type,
               let obj = type.init() as? T
            {
                return obj
            }
            return try decoder.decode(T.self, from: data)
        } catch {
            MyLogger.jsonApi?.debug("Decode failed \(error)")
            throw errorFromData(data, response: response, decoder: decoder)
        }
    }

    // MARK: Private

    private func errorFromData(_ data: Data, response: URLResponse, decoder: JSONDecoder) -> MyError {
        let code = (response as? HTTPURLResponse)?.statusCode ?? -1
        Task {
            if code == 401 {
                delegate.didReceiveUnauthorizedError()
            } else if code == 403 {
                delegate.didReceiveForbiddenError()
            }
        }
        
        do {
            let errors = try decoder.decode(JAErrors.self, from: data)
            MyLogger.jsonApi?.error("APIError failed \(errors)")
            return .underlayers(errors.errors)
        } catch {
            MyLogger.jsonApi?.error("Decode APIError failed \(code) \(String(data: data, encoding: .utf8) ?? "")")
            return .underlayerWithCode(NSError(code: code, message: "Unable to decode data response from server!"))
        }
    }
}

private actor TaskManagerRunningState {
    private var inProgressRequests = [String: Date]()

    // MARK: Fileprivate

    fileprivate func preStartCheck(request: URLRequest) throws {
        let key = request.uniqueID
        if inProgressRequests.index(forKey: key) != nil {
//            MyLogger.jsonApi?.debug("Duplicate Request \(request.url!)")
            throw MyError.local("The same request is in progress.")
        }

        inProgressRequests[key] = Date()
    }

    fileprivate func finishRequest(_ request: URLRequest) {
        inProgressRequests.removeValue(forKey: request.uniqueID)
    }

    fileprivate func cleanAllRequests() {
        inProgressRequests.removeAll()
    }
}

