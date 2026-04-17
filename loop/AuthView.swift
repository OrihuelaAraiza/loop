import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var auth = AppleAuthService()
    @State private var showMockConfirm = false

    var body: some View {
        ZStack {
            AmbientBackground(topColor: .amethyst, bottomColor: .cerulean)
            VStack(spacing: Spacing.xl) {
                Spacer()

                VStack(spacing: Spacing.md) {
                    Text("loop")
                        .font(LoopFont.black(44))
                        .foregroundColor(.textPrimary)
                        .overlay(alignment: .trailing) {
                            Circle().fill(Color.coral).frame(width: 11, height: 11).offset(x: 10, y: 6)
                        }

                    Text("Aprende a programar con tu ruta personalizada.")
                        .font(LoopFont.regular(15))
                        .foregroundColor(.textSecond)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, Spacing.xl)

                LoopCard(accentColor: .amethyst, showsSceneAccent: true, usesGlassSurface: true) {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Inicia sesion")
                                .font(LoopFont.bold(18))
                                .foregroundColor(.textPrimary)
                            Text("Guarda tu progreso, racha y XP para siempre en tu cuenta.")
                                .font(LoopFont.regular(13))
                                .foregroundColor(.textSecond)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            auth.handle(result: result)
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))

                        Button {
                            showMockConfirm = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "person.crop.circle.badge.questionmark")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Usar modo demo (sin cuenta)")
                                    .font(LoopFont.semiBold(13))
                            }
                            .foregroundColor(.periwinkle)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.loopSurf2.opacity(0.9))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.borderMid, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        if let error = auth.lastError {
                            Text(error)
                                .font(LoopFont.regular(12))
                                .foregroundColor(.coral)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                Spacer()

                Text("Al continuar aceptas nuestros terminos y la politica de privacidad.")
                    .font(LoopFont.regular(11))
                    .foregroundColor(.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .onAppear {
            auth.onSuccess = { session in
                appState.authSession = session
                if appState.userProfile.name.isEmpty, let name = session.displayName {
                    appState.userProfile.name = name
                }
            }
        }
        .alert("Modo demo", isPresented: $showMockConfirm) {
            Button("Continuar") { auth.mockSignIn() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Entraras con una cuenta invitada. Tu progreso se guarda localmente en este dispositivo.")
        }
    }
}

#Preview {
    AuthView().environmentObject(AppState())
}
