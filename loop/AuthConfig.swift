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
