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
            self.pitch = max(min(motion.attitude.pitch * 0.8, 0.45), -0.45)
            self.roll = max(min(motion.attitude.roll * 0.8, 0.45), -0.45)
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
}

struct LoopIdentityCard: View {
    let userProfile: UserProfile
    let gameState: GameState
    var isCustomizerPresented = false
    var onCustomize: () -> Void = {}

    @Environment(\.isJuniorMode) private var isJuniorMode
    @StateObject private var motion = LoopTiltMotionManager()
    @State private var isFlipped = false
    @State private var dragPitch: Double = 0
    @State private var dragRoll: Double = 0
    @State private var isDragging = false

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
        .frame(minHeight: 248)
        .rotation3DEffect(.degrees(-combinedPitch * 12), axis: (x: 1, y: 0, z: 0), perspective: 0.45)
        .rotation3DEffect(.degrees(combinedRoll * 14), axis: (x: 0, y: 1, z: 0), perspective: 0.45)
        .scaleEffect(isDragging ? 1.015 : 1)
        .shadow(color: accent.opacity(0.12 + (0.3 * userProfile.cardGlowStrength)), radius: 14 + (14 * userProfile.cardGlowStrength), y: 8 + (6 * userProfile.cardGlowStrength))
        .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
        .contentShape(RoundedRectangle(cornerRadius: Radius.xl))
        .onTapGesture {
            HapticManager.shared.impact(.medium)
            withAnimation(.spring(response: 0.52, dampingFraction: 0.84)) {
                isFlipped.toggle()
            }
        }
        .simultaneousGesture(cardDragGesture)
        .onAppear {
            if userProfile.cardMotionEnabled {
                motion.start()
            }
        }
        .onChange(of: userProfile.cardMotionEnabled) { _, isEnabled in
            if isEnabled {
                motion.start()
            } else {
                motion.stop()
            }
        }
        .onChange(of: userProfile.cardDragEnabled) { _, isEnabled in
            if !isEnabled {
                resetDragTilt(animated: true)
            }
        }
        .onDisappear { motion.stop() }
    }

    private var frontFace: some View {
        cardShell {
            VStack(alignment: .leading, spacing: Spacing.md) {
                ViewThatFits(in: .vertical) {
                    HStack(alignment: .top) {
                        identityHeader
                        Spacer()
                        customizationButton
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        identityHeader
                        customizationButton
                    }
                }

                ViewThatFits(in: .vertical) {
                    HStack(alignment: .center, spacing: Spacing.md) {
                        avatarSeal
                        identitySummary
                    }

                    VStack(alignment: .leading, spacing: Spacing.md) {
                        avatarSeal
                        identitySummary
                    }
                }

                ViewThatFits(in: .vertical) {
                    HStack(spacing: Spacing.sm) {
                        statPill(icon: "flame.fill", text: "\(gameState.currentStreak) días")
                        statPill(icon: "clock.fill", text: "\(userProfile.minutesPerDay) min")
                        statPill(icon: "sparkles", text: languageLabel)
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack(spacing: Spacing.sm) {
                            statPill(icon: "flame.fill", text: "\(gameState.currentStreak) días")
                            statPill(icon: "clock.fill", text: "\(userProfile.minutesPerDay) min")
                        }
                        statPill(icon: "sparkles", text: languageLabel)
                    }
                }

                ViewThatFits(in: .vertical) {
                    HStack(spacing: Spacing.sm) {
                        infoTile(label: "Objetivo", value: LoopCopy.goalName(userProfile.goal, junior: isJuniorMode))
                        infoTile(label: "Nivel", value: userProfile.knowledgeLevel.rawValue)
                    }

                    VStack(spacing: Spacing.sm) {
                        infoTile(label: "Objetivo", value: LoopCopy.goalName(userProfile.goal, junior: isJuniorMode))
                        infoTile(label: "Nivel", value: userProfile.knowledgeLevel.rawValue)
                    }
                }

                Text(cardInteractionHint)
                    .font(LoopFont.semiBold(12))
                    .foregroundColor(.white.opacity(0.62))
            }
        }
    }

    private var backFace: some View {
        cardShell {
            VStack(alignment: .leading, spacing: Spacing.md) {
                ViewThatFits(in: .vertical) {
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

                        customizationButton
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SNAPSHOT")
                                .font(LoopFont.bold(11))
                                .foregroundColor(.white.opacity(0.7))
                            Text("Tu progreso actual")
                                .font(LoopFont.bold(20))
                                .foregroundColor(.white)
                        }
                        customizationButton
                    }
                }

                ViewThatFits(in: .vertical) {
                    HStack(spacing: Spacing.sm) {
                        xpCell
                        progressCell(value: "Nivel \(gameState.level)", label: "Estado")
                        progressCell(value: "\(activeDaysCount)", label: "Días")
                    }

                    VStack(spacing: Spacing.sm) {
                        HStack(spacing: Spacing.sm) {
                            xpCell
                            progressCell(value: "Nivel \(gameState.level)", label: "Estado")
                        }
                        progressCell(value: "\(activeDaysCount)", label: "Días")
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
                        infoTile(label: "Edad", value: "\(userProfile.age) años")
                        infoTile(label: "Ruta", value: languageLabel)
                    }

                    VStack(spacing: Spacing.sm) {
                        infoTile(label: "Edad", value: "\(userProfile.age) años")
                        infoTile(label: "Ruta", value: languageLabel)
                    }
                }
            }
        }
    }

    private var identityHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(displayBadge.rawValue.uppercased())
                .font(LoopFont.bold(11))
                .foregroundColor(.white.opacity(0.7))
            Text(identityTitle)
                .font(LoopFont.black(24))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var customizationButton: some View {
        Button(action: onCustomize) {
            HStack(spacing: 6) {
                Image(systemName: isCustomizerPresented ? "xmark" : "slider.horizontal.3")
                    .font(.system(size: 11, weight: .bold))
                Text(isCustomizerPresented ? "Cerrar" : "Editar")
                    .font(LoopFont.bold(12))
                    .lineLimit(1)
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
        .buttonStyle(.plain)
    }

    private var avatarSeal: some View {
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
    }

    private var identitySummary: some View {
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

    private func cardShell<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: Radius.xl)
                .fill(
                    LinearGradient(
                        colors: cardGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.xl))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.xl)
                        .fill(Color.loopBG.opacity(surfaceDepthOpacity))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.xl)
                        .fill(Color.white.opacity(surfaceHighlightOpacity))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.xl)
                        .stroke(surfaceBorderColor, lineWidth: userProfile.cardSurface == .neon ? 1.35 : 1)
                )

            RoundedRectangle(cornerRadius: Radius.xl)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.2), .clear, Color.black.opacity(0.14)],
                        startPoint: UnitPoint(x: 0.18 - motion.roll * 0.12, y: 0.04 + motion.pitch * 0.08),
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.screen)

            LoopSceneAccent(tint: .white.opacity(0.8))
                .opacity(sceneAccentOpacity)
                .padding(.top, -8)
                .padding(.trailing, -4)

            content()
                .padding(Spacing.xl)
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
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

    private var xpCell: some View {
        VStack(alignment: .leading, spacing: 4) {
            XPBounceText(
                value: gameState.totalXP,
                font: LoopFont.bold(18),
                color: .white
            )
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            Text(LoopCopy.xpLabel(junior: isJuniorMode))
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

    private var motionPitch: Double {
        userProfile.cardMotionEnabled ? motion.pitch : 0
    }

    private var motionRoll: Double {
        userProfile.cardMotionEnabled ? motion.roll : 0
    }

    private var combinedPitch: Double {
        motionPitch + dragPitch
    }

    private var combinedRoll: Double {
        motionRoll + dragRoll
    }

    private var cardDragGesture: some Gesture {
        DragGesture(minimumDistance: 3, coordinateSpace: .local)
            .onChanged { value in
                guard userProfile.cardDragEnabled else { return }
                if !isDragging {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                        isDragging = true
                    }
                }
                let maxDrag: CGFloat = 120
                let clampedX = Double(max(min(value.translation.width, maxDrag), -maxDrag) / maxDrag)
                let clampedY = Double(max(min(value.translation.height, maxDrag), -maxDrag) / maxDrag)
                dragRoll = clampedX * 0.45
                dragPitch = clampedY * 0.45
            }
            .onEnded { _ in
                resetDragTilt(animated: true)
            }
    }

    private func resetDragTilt(animated: Bool) {
        let reset = {
            dragPitch = 0
            dragRoll = 0
            isDragging = false
        }
        if animated {
            withAnimation(.interpolatingSpring(stiffness: 140, damping: 12)) {
                reset()
            }
        } else {
            reset()
        }
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
            return "Arrancando desde cero con una ruta clara y sin fricción."
        case .someReading:
            return "Con base previa ligera, listo para convertir lectura en práctica."
        case .basicKnows:
            return "Ya dominas la base y ahora toca consolidar ritmo real."
        case .hasPractice:
            return "Tu enfoque ya es práctico; ahora el salto es consistencia y profundidad."
        }
    }

    private var languageLabel: String {
        userProfile.generatedPlan?.language.rawValue ?? "Python"
    }

    private var activeDaysCount: String {
        "\(userProfile.activeDays.count)"
    }

    private var backSummary: String {
        "Estás construyendo una identidad de \(identityTitle.lowercased()) con badge \(displayBadge.rawValue.lowercased()), \(userProfile.minutesPerDay) minutos por sesión y una racha de \(gameState.currentStreak) días."
    }

    private var displayBadge: IdentityCardBadge {
        IdentityCardBadge.normalizedForJunior(userProfile.cardBadge, junior: isJuniorMode)
    }

    private var cardInteractionHint: String {
        if userProfile.cardDragEnabled {
            return "Toca para girarla. Arrastra con el dedo y verá la inclinación reaccionar."
        }
        return "Toca la tarjeta para ver tu snapshot actual."
    }

    private var cardGradient: [Color] {
        switch userProfile.cardSurface {
        case .glass:
            return [accent.opacity(0.96), secondaryAccent.opacity(0.84), Color.loopBG.opacity(0.98)]
        case .neon:
            return [accent.opacity(1), secondaryAccent.opacity(0.95), Color.loopBG.opacity(0.92)]
        case .stealth:
            return [Color.loopSurf2.opacity(0.94), accent.opacity(0.42), Color.loopBG.opacity(0.99)]
        }
    }

    private var surfaceBorderColor: Color {
        switch userProfile.cardSurface {
        case .glass:
            return Color.white.opacity(0.14)
        case .neon:
            return accent.opacity(0.58 + (0.35 * userProfile.cardGlowStrength))
        case .stealth:
            return Color.white.opacity(0.09)
        }
    }

    private var surfaceDepthOpacity: Double {
        switch userProfile.cardSurface {
        case .glass:
            return 0.2
        case .neon:
            return 0.14
        case .stealth:
            return 0.32
        }
    }

    private var surfaceHighlightOpacity: Double {
        switch userProfile.cardSurface {
        case .glass:
            return 0.04
        case .neon:
            return 0.08 + (0.08 * userProfile.cardGlowStrength)
        case .stealth:
            return 0.025
        }
    }

    private var sceneAccentOpacity: Double {
        switch userProfile.cardSurface {
        case .glass:
            return 0.18
        case .neon:
            return 0.24 + (0.18 * userProfile.cardGlowStrength)
        case .stealth:
            return 0.1
        }
    }

    private var accent: Color {
        switch userProfile.cardPalette {
        case .coral:
            return .coral
        case .aurora:
            return .mint
        case .midnight:
            return .periwinkle
        case .sunset:
            return .loopGold
        case .ocean:
            return .cerulean
        }
    }

    private var secondaryAccent: Color {
        switch userProfile.cardPalette {
        case .coral:
            return .amethyst
        case .aurora:
            return .cerulean
        case .midnight:
            return .loopGold
        case .sunset:
            return .coral
        case .ocean:
            return .mint
        }
    }
}
