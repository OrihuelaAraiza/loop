import Pow
import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var auth = AppleAuthService()
    @State private var showMockConfirm = false
    @State private var reveal = false
    @State private var heroPulse = false
    @State private var benefitsReveal = false
    @State private var blob1 = false
    @State private var blob2 = false
    @State private var blob3 = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LoopMeshBackground()
            decorativeBlobs

            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.xl) {
                    heroSection
                        .padding(.top, Spacing.xxl)

                    benefitsGrid

                    loginCard

                    footer
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .onAppear {
            auth.onSuccess = { session in
                appState.authSession = session
                if appState.userProfile.name.isEmpty, let name = session.displayName {
                    appState.userProfile.name = name
                }
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) {
                reveal = true
            }
            if !reduceMotion {
                withAnimation(LoopAnimation.meshBreath) {
                    heroPulse = true
                }
                withAnimation(.easeInOut(duration: 7.0).repeatForever(autoreverses: true)) {
                    blob1 = true
                }
                withAnimation(.easeInOut(duration: 9.5).repeatForever(autoreverses: true).delay(1.2)) {
                    blob2 = true
                }
                withAnimation(.easeInOut(duration: 6.0).repeatForever(autoreverses: true).delay(2.8)) {
                    blob3 = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                benefitsReveal = true
            }
        }
        .alert("Modo demo", isPresented: $showMockConfirm) {
            Button("Continuar") { auth.mockSignIn() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Entraras con una cuenta invitada. Tu progreso se guarda localmente en este dispositivo.")
        }
    }

    // MARK: - Decorative background

    private var decorativeBlobs: some View {
        ZStack {
            Circle()
                .fill(Color.coral.opacity(0.18))
                .frame(width: blob1 ? 320 : 260, height: blob1 ? 320 : 260)
                .blur(radius: 75)
                .offset(x: blob1 ? -110 : -160, y: blob1 ? -220 : -280)

            Circle()
                .fill(Color.amethyst.opacity(0.20))
                .frame(width: blob2 ? 360 : 290, height: blob2 ? 360 : 290)
                .blur(radius: 95)
                .offset(x: blob2 ? 130 : 180, y: blob2 ? 240 : 180)

            Circle()
                .fill(Color.coral.opacity(0.10))
                .frame(width: blob3 ? 240 : 200, height: blob3 ? 240 : 200)
                .blur(radius: 85)
                .offset(x: blob3 ? 150 : 200, y: blob3 ? -200 : -150)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: Spacing.md) {
            heroBadge
                .scaleEffect(reveal ? 1 : 0.8)
                .opacity(reveal ? 1 : 0)

            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text("loop")
                        .font(LoopFont.black(56))
                        .foregroundColor(.textPrimary)
                    Circle()
                        .fill(Color.coral)
                        .frame(width: 14, height: 14)
                        .offset(y: 14)
                        .scaleEffect(heroPulse ? 1.1 : 0.95)
                        .shadow(color: .coral.opacity(0.6), radius: heroPulse ? 14 : 8, y: 4)
                }

                Text("Aprende a programar, un ciclo a la vez.")
                    .font(LoopFont.bold(16))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Rutas personalizadas, racha diaria y progreso real que se queda contigo.")
                    .font(LoopFont.regular(13))
                    .foregroundColor(.textSecond)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Spacing.md)
            }
            .opacity(reveal ? 1 : 0)
            .offset(y: reveal ? 0 : 10)
        }
    }

    private var heroBadge: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.coral.opacity(0.45), Color.amethyst.opacity(0.1), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 90
                    )
                )
                .frame(width: 180, height: 180)
                .scaleEffect(heroPulse ? 1.08 : 0.95)

            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                .frame(width: 150, height: 150)

            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                .frame(width: 110, height: 110)

            floatingLoopy
                .frame(width: 120, height: 120)
                .clipped()
        }
        .frame(height: 180)
    }

    @ViewBuilder
    private var floatingLoopy: some View {
        if reduceMotion {
            LoopyView(mood: .celebrating)
                .scaleEffect(0.6)
        } else {
            PhaseAnimator([0.0, -8.0, 0.0]) { phase in
                LoopyView(mood: .celebrating)
                    .scaleEffect(0.6)
                    .offset(y: CGFloat(phase))
            } animation: { _ in
                .easeInOut(duration: 1.8)
            }
        }
    }

    // MARK: - Benefits

    private var benefitsGrid: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(Array(benefitItems.enumerated()), id: \.offset) { index, item in
                Group {
                    if benefitsReveal {
                        benefitPill(icon: item.icon, label: item.label, tint: item.tint)
                            .transition(.movingParts.pop)
                    }
                }
                .animation(LoopAnimation.springBouncy.delay(0.1 * Double(index)), value: benefitsReveal)
            }
        }
    }

    private var benefitItems: [(icon: String, label: String, tint: Color)] {
        [
            ("flame.fill", "Racha diaria", .loopGold),
            ("map.fill", "Rutas guiadas", .periwinkle),
            ("sparkles", "Card 3D", .coral)
        ]
    }

    private func benefitPill(icon: String, label: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.18))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(tint)
            }
            Text(label)
                .font(LoopFont.bold(11))
                .foregroundColor(.textSecond)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg)
                .fill(Color.loopSurf2.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(Color.borderSoft, lineWidth: 1)
        )
    }

    // MARK: - Login card

    private var loginCard: some View {
        LoopCard(accentColor: .coral, showsSceneAccent: true, usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.coral)
                    Text("Empieza en 10 segundos")
                        .font(LoopFont.bold(11))
                        .foregroundColor(.coral)
                        .textCase(.uppercase)
                        .tracking(0.8)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.coral.opacity(0.12))
                .clipShape(Capsule())

                VStack(alignment: .leading, spacing: 6) {
                    Text("Inicia sesion")
                        .font(LoopFont.bold(20))
                        .foregroundColor(.textPrimary)
                    Text("Tu racha, XP y perfil 3D se sincronizan en tu cuenta.")
                        .font(LoopFont.regular(13))
                        .foregroundColor(.textSecond)
                        .fixedSize(horizontal: false, vertical: true)
                }

                SignInWithAppleButton(.continue) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    auth.handle(result: result)
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 54)
                .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                .shadow(color: .black.opacity(0.25), radius: 12, y: 6)

                HStack(spacing: 10) {
                    Rectangle().fill(Color.borderSoft).frame(height: 1)
                    Text("o")
                        .font(LoopFont.bold(11))
                        .foregroundColor(.textMuted)
                    Rectangle().fill(Color.borderSoft).frame(height: 1)
                }
                .padding(.vertical, 2)

                Button {
                    showMockConfirm = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 14, weight: .bold))
                        Text("Continuar como invitado")
                            .font(LoopFont.semiBold(14))
                    }
                    .foregroundColor(.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.loopSurf2.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.lg)
                            .stroke(Color.borderMid, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                if let error = auth.lastError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(LoopFont.regular(12))
                        .foregroundColor(.coral)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scaleEffect(reveal ? 1 : 0.96)
        .opacity(reveal ? 1 : 0)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 4) {
            Text("Hecho para aprender a tu ritmo.")
                .font(LoopFont.bold(12))
                .foregroundColor(.textSecond)
            Text("Al continuar aceptas nuestros terminos y la politica de privacidad.")
                .font(LoopFont.regular(11))
                .foregroundColor(.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.sm)
    }
}

#Preview {
    AuthView().environmentObject(AppState())
}
