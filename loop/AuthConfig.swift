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

    static var apiBaseURL: URL {
        var components = URLComponents()
        components.scheme = apiScheme
        components.host = apiHost
        components.port = apiPort
        components.path = "/api"

        guard let url = components.url else {
            fatalError("Invalid API URL config")
        }

        return url
    }

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
