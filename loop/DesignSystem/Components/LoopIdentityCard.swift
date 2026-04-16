import Combine
import CoreMotion
import SwiftUI

private final class LoopTiltMotionManager: ObservableObject {
    @Published var pitch: Double = 0
    @Published var roll: Double = 0

    private let motionManager = CMMotionManager()

    func start() {
        guard motionManager.isDeviceMotionAvailable, !motionManager.isDeviceMotionActive else { return }
        motionManager.deviceMotionUpdateInterval = 1 / 45
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.pitch = max(min(motion.attitude.pitch * 0.9, 0.5), -0.5)
            self.roll = max(min(motion.attitude.roll * 0.9, 0.5), -0.5)
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
}

struct LoopIdentityCard: View {
    let userProfile: UserProfile
    let gameState: GameState

    @StateObject private var motion = LoopTiltMotionManager()
    @State private var isFlipped = false

    private let avatars = ["person.circle.fill", "laptopcomputer", "terminal.fill", "cpu.fill", "gamecontroller.fill"]

    var body: some View {
        ZStack {
            frontFace
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

            backFace
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .rotation3DEffect(.degrees(-motion.pitch * 12), axis: (x: 1, y: 0, z: 0))
        .rotation3DEffect(.degrees(motion.roll * 16), axis: (x: 0, y: 1, z: 0))
        .shadow(color: accent.opacity(0.22), radius: 24, y: 16)
        .shadow(color: .black.opacity(0.18), radius: 32, y: 18)
        .contentShape(RoundedRectangle(cornerRadius: Radius.xl))
        .onTapGesture {
            withAnimation(.spring(response: 0.52, dampingFraction: 0.84)) {
                isFlipped.toggle()
            }
        }
        .onAppear { motion.start() }
        .onDisappear { motion.stop() }
    }

    private var frontFace: some View {
        cardShell {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LOOP ID")
                            .font(LoopFont.bold(11))
                            .foregroundColor(.white.opacity(0.7))
                        Text(identityTitle)
                            .font(LoopFont.black(24))
                            .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    heroPill(icon: "wave.3.right", text: "Mueve tu telefono")
                }

                HStack(alignment: .center, spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [accent.opacity(0.92), secondaryAccent.opacity(0.96)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 78, height: 78)

                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            .frame(width: 78, height: 78)

                        Image(systemName: avatarSymbol)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayName)
                            .font(LoopFont.bold(22))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(identitySubtitle)
                            .font(LoopFont.regular(13))
                            .foregroundColor(.white.opacity(0.76))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                ViewThatFits(in: .vertical) {
                    HStack(spacing: Spacing.sm) {
                        statPill(icon: "flame.fill", text: "\(gameState.currentStreak) dias")
                        statPill(icon: "clock.fill", text: "\(userProfile.minutesPerDay) min")
                        statPill(icon: "sparkles", text: languageLabel)
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack(spacing: Spacing.sm) {
                            statPill(icon: "flame.fill", text: "\(gameState.currentStreak) dias")
                            statPill(icon: "clock.fill", text: "\(userProfile.minutesPerDay) min")
                        }
                        statPill(icon: "sparkles", text: languageLabel)
                    }
                }

                ViewThatFits(in: .vertical) {
                    HStack(spacing: Spacing.sm) {
                        infoTile(label: "Objetivo", value: userProfile.goal.rawValue)
                        infoTile(label: "Nivel", value: userProfile.knowledgeLevel.rawValue)
                    }

                    VStack(spacing: Spacing.sm) {
                        infoTile(label: "Objetivo", value: userProfile.goal.rawValue)
                        infoTile(label: "Nivel", value: userProfile.knowledgeLevel.rawValue)
                    }
                }

                Text("Toca la tarjeta para ver tu snapshot actual.")
                    .font(LoopFont.semiBold(12))
                    .foregroundColor(.white.opacity(0.62))
            }
        }
    }

    private var backFace: some View {
        cardShell {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SNAPSHOT")
                            .font(LoopFont.bold(11))
                            .foregroundColor(.white.opacity(0.7))
                        Text("Tu progreso actual")
                            .font(LoopFont.bold(20))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    heroPill(icon: "hand.tap.fill", text: "Toca para volver")
                }

                ViewThatFits(in: .vertical) {
                    HStack(spacing: Spacing.sm) {
                        progressCell(value: "\(gameState.totalXP)", label: "XP")
                        progressCell(value: "Nivel \(gameState.level)", label: "Estado")
                        progressCell(value: "\(activeDaysCount)", label: "Dias")
                    }

                    VStack(spacing: Spacing.sm) {
                        HStack(spacing: Spacing.sm) {
                            progressCell(value: "\(gameState.totalXP)", label: "XP")
                            progressCell(value: "Nivel \(gameState.level)", label: "Estado")
                        }
                        progressCell(value: "\(activeDaysCount)", label: "Dias")
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Resumen")
                        .font(LoopFont.bold(13))
                        .foregroundColor(.white.opacity(0.78))
                    Text(backSummary)
                        .font(LoopFont.regular(14))
                        .foregroundColor(.white.opacity(0.86))
                        .fixedSize(horizontal: false, vertical: true)
                }

                ViewThatFits(in: .vertical) {
                    HStack(spacing: Spacing.sm) {
                        infoTile(label: "Edad", value: "\(userProfile.age) anos")
                        infoTile(label: "Ruta", value: languageLabel)
                    }

                    VStack(spacing: Spacing.sm) {
                        infoTile(label: "Edad", value: "\(userProfile.age) anos")
                        infoTile(label: "Ruta", value: languageLabel)
                    }
                }
            }
        }
    }

    private func cardShell<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: Radius.xl)
                .fill(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.96),
                            secondaryAccent.opacity(0.84),
                            Color.loopBG.opacity(0.98),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.xl))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.xl)
                        .fill(Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.xl)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )

            RoundedRectangle(cornerRadius: Radius.xl)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.28), .clear, Color.black.opacity(0.18)],
                        startPoint: UnitPoint(x: 0.12 - motion.roll * 0.18, y: 0.02 + motion.pitch * 0.12),
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.screen)

            LoopSceneAccent(tint: .white.opacity(0.9))
                .opacity(0.42)
                .padding(.top, -10)
                .padding(.trailing, -6)

            VStack {
                RoundedRectangle(cornerRadius: Radius.xl)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)
                Spacer()
            }

            content()
                .padding(Spacing.xl)
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
    }

    private func heroPill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(LoopFont.bold(12))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundColor(.white)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func statPill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(LoopFont.bold(12))
                .lineLimit(1)
                .minimumScaleFactor(0.88)
        }
        .foregroundColor(.white)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func infoTile(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(LoopFont.bold(10))
                .foregroundColor(.white.opacity(0.62))
            Text(value)
                .font(LoopFont.semiBold(14))
                .foregroundColor(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func progressCell(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(LoopFont.bold(18))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            Text(label)
                .font(LoopFont.semiBold(11))
                .foregroundColor(.white.opacity(0.68))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var displayName: String {
        let trimmed = userProfile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Loop Learner" : trimmed
    }

    private var avatarSymbol: String {
        let index = min(max(userProfile.avatarIndex, 0), avatars.count - 1)
        return avatars[index]
    }

    private var identityTitle: String {
        switch userProfile.goal {
        case .createApps:
            return "Builder Mode"
        case .getJob:
            return "Career Track"
        case .passClasses:
            return "Academic Run"
        case .curiosity:
            return "Curious Mind"
        }
    }

    private var identitySubtitle: String {
        switch userProfile.knowledgeLevel {
        case .zero:
            return "Arrancando desde cero con una ruta clara y sin friccion."
        case .someReading:
            return "Con base previa ligera, listo para convertir lectura en practica."
        case .basicKnows:
            return "Ya dominas la base y ahora toca consolidar ritmo real."
        case .hasPractice:
            return "Tu enfoque ya es practico; ahora el salto es consistencia y profundidad."
        }
    }

    private var languageLabel: String {
        userProfile.generatedPlan?.language.rawValue ?? "Python"
    }

    private var activeDaysCount: String {
        "\(userProfile.activeDays.count)"
    }

    private var backSummary: String {
        "Estas construyendo una identidad de \(identityTitle.lowercased()) con \(userProfile.minutesPerDay) minutos por sesion, \(activeDaysCount) dias activos y una racha de \(gameState.currentStreak) dias."
    }

    private var accent: Color {
        switch userProfile.goal {
        case .createApps:
            return .coral
        case .getJob:
            return .loopGold
        case .passClasses:
            return .periwinkle
        case .curiosity:
            return .mint
        }
    }

    private var secondaryAccent: Color {
        switch userProfile.knowledgeLevel {
        case .zero:
            return .amethyst
        case .someReading:
            return .cerulean
        case .basicKnows:
            return .periwinkle
        case .hasPractice:
            return .loopGold
        }
    }
}
