import Foundation
import Combine
import AuthenticationServices
import SwiftUI

final class AppleAuthService: NSObject, ObservableObject {
    @Published var isProcessing = false
    @Published var lastError: String?

    var onSuccess: ((AuthSession) -> Void)?

    func handle(result: Result<ASAuthorization, Error>) {
        switch result {
        case let .success(authorization):
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let session = AuthSession(
                    userID: credential.user,
                    displayName: [credential.fullName?.givenName, credential.fullName?.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                        .trimmingCharacters(in: .whitespaces)
                        .nonEmptyOrNil,
                    email: credential.email,
                    provider: .apple
                )
                onSuccess?(session)
            } else {
                mockSignIn()
            }
        case let .failure(error):
            lastError = error.localizedDescription
        }
    }

    // Fallback para entornos sin capability SIWA configurada.
    func mockSignIn(displayName: String? = nil, email: String? = nil) {
        let session = AuthSession(
            userID: "mock-" + UUID().uuidString,
            displayName: displayName ?? "Loop Learner",
            email: email,
            provider: .mockApple
        )
        onSuccess?(session)
    }
}

private extension String {
    var nonEmptyOrNil: String? {
        isEmpty ? nil : self
    }
}
