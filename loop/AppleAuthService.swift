import Foundation
import Combine
import AuthenticationServices
import SwiftUI

final class AppleAuthService: NSObject, ObservableObject {
    @Published var isProcessing = false
    @Published var lastError: String?

    var onSuccess: ((AuthSession) -> Void)?
    private let api = AuthAPIClient()

    func handle(result: Result<ASAuthorization, Error>) {
        switch result {
        case let .success(authorization):
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let displayName = [credential.fullName?.givenName, credential.fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                    .trimmingCharacters(in: .whitespaces)
                    .nonEmptyOrNil

                signInWithApple(
                    appleSub: credential.user,
                    email: credential.email,
                    displayName: displayName
                )
            } else {
                mockSignIn()
            }
        case let .failure(error):
            lastError = error.localizedDescription
        }
    }

    func signInWithEmail(email: String, password: String) {
        execute {
            try await self.api.login(email: email, password: password)
        }
    }

    func registerWithEmail(name: String?, email: String, password: String) {
        execute {
            try await self.api.register(name: name, email: email, password: password)
        }
    }

    func signInWithApple(appleSub: String, email: String?, displayName: String?) {
        execute {
            try await self.api.appleSignIn(appleSub: appleSub, email: email, displayName: displayName)
        }
    }

    // Fallback para entornos sin capability SIWA configurada.
    func mockSignIn(displayName: String? = nil, email: String? = nil) {
        let session = AuthSession(
            userID: "mock-" + UUID().uuidString,
            displayName: displayName ?? "Loop Learner",
            email: email,
            apiToken: nil,
            provider: .mockApple
        )
        onSuccess?(session)
    }

    private func execute(_ operation: @escaping () async throws -> AuthSession) {
        isProcessing = true
        lastError = nil

        Task {
            do {
                let session = try await operation()
                await MainActor.run {
                    self.isProcessing = false
                    self.lastError = nil
                    self.onSuccess?(session)
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
        }
    }
}

private extension String {
    var nonEmptyOrNil: String? {
        isEmpty ? nil : self
    }
}

private struct AuthAPIClient {
    private let baseURL = AuthConfig.apiBaseURL

    func register(name: String?, email: String, password: String) async throws -> AuthSession {
        var payload: [String: Any] = [
            "email": email,
            "password": password,
            "password_confirmation": password
        ]

        if let name, !name.isEmpty {
            payload["name"] = name
        }

        return try await performAuth(path: "auth/register", payload: payload)
    }

    func login(email: String, password: String) async throws -> AuthSession {
        try await performAuth(
            path: "auth/login",
            payload: [
                "email": email,
                "password": password
            ]
        )
    }

    func appleSignIn(appleSub: String, email: String?, displayName: String?) async throws -> AuthSession {
        var payload: [String: Any] = [
            "apple_sub": appleSub
        ]

        if let email, !email.isEmpty {
            payload["email"] = email
        }

        if let displayName, !displayName.isEmpty {
            payload["name"] = displayName
        }

        return try await performAuth(path: "auth/apple", payload: payload)
    }

    private func performAuth(path: String, payload: [String: Any]) async throws -> AuthSession {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        request.setValue("LoopiOS/1.0", forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await LoopAPISession.perform(request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthAPIError(message: "No se recibió respuesta del servidor.")
        }

        if (200 ... 299).contains(httpResponse.statusCode) {
            let decoded = try JSONDecoder().decode(AuthAPIResponse.self, from: data)
            return decoded.toSession()
        }

        if let apiError = try? JSONDecoder().decode(AuthAPIErrorPayload.self, from: data) {
            throw AuthAPIError(message: apiError.humanMessage)
        }

        throw AuthAPIError(message: "Error del servidor (\(httpResponse.statusCode)).")
    }
}

private struct AuthAPIResponse: Decodable {
    let token: String
    let user: AuthAPIUser

    func toSession() -> AuthSession {
        AuthSession(
            userID: user.id,
            displayName: user.name,
            email: user.email,
            apiToken: token,
            provider: user.provider
        )
    }
}

private struct AuthAPIUser: Decodable {
    let id: String
    let email: String
    let name: String?
    let authProvider: String

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case authProvider = "auth_provider"
    }

    var provider: AuthSession.Provider {
        switch authProvider {
        case "apple":
            return .apple
        case "password":
            return .password
        default:
            return .password
        }
    }
}

private struct AuthAPIErrorPayload: Decodable {
    let error: String
    let details: [String: [String]]?

    var humanMessage: String {
        if let details,
           let firstField = details.keys.sorted().first,
           let message = details[firstField]?.first {
            return "\(firstField): \(message)"
        }

        return error.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

private struct AuthAPIError: LocalizedError {
    let message: String

    var errorDescription: String? { message }
}
