import Foundation

enum AuthConfig {
    // For iOS Simulator use localhost. For a physical iPhone, use your Mac's LAN IP.
    private static let defaultHost = "127.0.0.1"
    private static let defaultPort = 4000
    private static let defaultScheme = "http"

    static var apiHost: String {
        value(for: "LOOP_API_HOST") ?? defaultHost
    }

    static var apiPort: Int {
        if let raw = value(for: "LOOP_API_PORT"), let port = Int(raw) {
            return port
        }

        return defaultPort
    }

    static var apiScheme: String {
        value(for: "LOOP_API_SCHEME") ?? defaultScheme
    }

    static let apiBaseURL: URL = {
        var components = URLComponents()
        components.scheme = apiScheme
        components.host = apiHost
        components.path = "/api"

        // Port only if non-default (443 for https, 80 for http)
        let defaultPort = (apiScheme == "https") ? 443 : 80
        if apiPort != defaultPort {
            components.port = apiPort
        }

        guard let url = components.url else {
            fatalError("Invalid API URL config")
        }

        #if DEBUG
        print("[LOOP] API base URL = \(url.absoluteString)")
        print("[LOOP]   host   = \(apiHost) (env: \(ProcessInfo.processInfo.environment["LOOP_API_HOST"] ?? "nil"))")
        print("[LOOP]   port   = \(apiPort)")
        print("[LOOP]   scheme = \(apiScheme)")
        #endif

        return url
    }()

    private static func value(for key: String) -> String? {
        if let env = ProcessInfo.processInfo.environment[key] {
            let trimmed = env.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }

        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

enum LoopAPISession {
    private static let lock = NSLock()
    private static var _session: URLSession = makeSession()
    private static var consecutiveTransportFailures = 0
    private static let failureThreshold = 3

    static func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        let currentSession = snapshotSession()
        let start = Date()
        let method = request.httpMethod ?? "GET"
        let path = request.url?.path ?? ""

        do {
            let result = try await currentSession.data(for: request)
            let ms = Int(Date().timeIntervalSince(start) * 1000)
            if let http = result.1 as? HTTPURLResponse {
                #if DEBUG
                print("[API] \(method) \(path) → \(http.statusCode) (\(ms)ms)")
                #endif
            }
            recordTransportSuccess()
            return result
        } catch {
            let ms = Int(Date().timeIntervalSince(start) * 1000)
            #if DEBUG
            print("[API] \(method) \(path) → ERROR \(error.localizedDescription) (\(ms)ms)")
            #endif
            if error is URLError {
                recordTransportFailure()
            }
            throw error
        }
    }

    private static func snapshotSession() -> URLSession {
        lock.lock(); defer { lock.unlock() }
        return _session
    }

    private static func recordTransportSuccess() {
        lock.lock(); defer { lock.unlock() }
        consecutiveTransportFailures = 0
    }

    private static func recordTransportFailure() {
        lock.lock()
        consecutiveTransportFailures += 1
        let shouldReset = consecutiveTransportFailures >= failureThreshold
        if shouldReset {
            consecutiveTransportFailures = 0
        }
        let staleSession = shouldReset ? _session : nil
        if shouldReset {
            _session = makeSession()
        }
        lock.unlock()

        if let staleSession {
            #if DEBUG
            print("[API] resetting URLSession after \(failureThreshold) consecutive transport failures")
            #endif
            staleSession.invalidateAndCancel()
        }
    }

    private static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.waitsForConnectivity = false
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.httpMaximumConnectionsPerHost = 4
        return URLSession(configuration: config)
    }
}
