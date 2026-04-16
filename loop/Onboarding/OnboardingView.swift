import SwiftUI
import UIKit

struct OnboardingFlow: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()
    private let stepLabels = ["Inicio", "Perfil", "Edad", "Objetivo", "Nivel", "Rutina", "Plan"]

    var body: some View {
        ZStack {
            AmbientBackground(topColor: .amethyst, bottomColor: .cerulean)

            VStack(spacing: 0) {
                header
                stepContent
                    .id(viewModel.step)
                    .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .trailing)), removal: .opacity))
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.88), value: viewModel.step)
        }
    }

    private var header: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Button {
                    viewModel.previous()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(viewModel.step == 0 ? .textMuted : .textPrimary)
                        .frame(width: 32, height: 32)
                        .background(Color.loopSurf2.opacity(0.65))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.borderSoft, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.step == 0)

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text(stepLabels[viewModel.step].uppercased())
                        .font(LoopFont.bold(10))
                        .foregroundColor(.periwinkle)

                    Text("Paso \(viewModel.step + 1) de \(viewModel.totalSteps)")
                        .font(LoopFont.semiBold(12))
                        .foregroundColor(.textSecond)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, 6)
                        .background(Color.loopSurf2.opacity(0.7))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.borderSoft, lineWidth: 1))
                }
            }

            CrumbStepsBar(currentStep: viewModel.step, totalSteps: viewModel.totalSteps)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.md)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.step {
        case 0:
            OnboardingWelcomeView(next: viewModel.next)
        case 1:
            OnboardingNameView(viewModel: viewModel)
        case 2:
            OnboardingAgeView(viewModel: viewModel)
        case 3:
            OnboardingGoalView(viewModel: viewModel)
        case 4:
            OnboardingLevelView(viewModel: viewModel)
        case 5:
            OnboardingTimeView(viewModel: viewModel)
        default:
            OnboardingPlanView(
                viewModel: viewModel,
                finish: {
                    appState.userProfile = viewModel.userProfile
                    appState.hasCompletedOnboarding = true
                }
            )
        }
    }
}

private struct CrumbStepsBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0 ..< totalSteps, id: \.self) { index in
                Capsule()
                    .fill(
                        index <= currentStep
                            ? LinearGradient(
                                colors: [Color.coral, Color.amethyst.opacity(0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [Color.borderSoft, Color.borderSoft],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .frame(width: index == currentStep ? 30 : 12, height: 8)
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: currentStep)
            }
        }
        .padding(.horizontal, 2)
    }
}

private struct OnboardingContainer<Content: View>: View {
    let title: String
    let subtitle: String
    let eyebrow: String
    let content: Content

    init(title: String, subtitle: String, eyebrow: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.eyebrow = eyebrow
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    Text(eyebrow.uppercased())
                        .font(LoopFont.bold(11))
                        .foregroundColor(.periwinkle)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, 6)
                        .background(Color.loopSurf2.opacity(0.8))
                        .clipShape(Capsule())

                    Text(title)
                        .font(LoopFont.black(30))
                        .foregroundColor(.textPrimary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitle)
                        .font(LoopFont.regular(15))
                        .foregroundColor(.textSecond)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    content

                    Spacer(minLength: Spacing.section)
                }
                .frame(maxWidth: 560, alignment: .leading)
                .frame(minHeight: proxy.size.height, alignment: .top)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.section)
            }
            .padding(.horizontal, Spacing.xl)
        }
    }
}

private struct OnboardingMiniPill: View {
    let icon: String
    let text: String
    var tint: Color = .periwinkle

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(LoopFont.bold(12))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
        }
        .foregroundColor(tint)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.loopSurf2.opacity(0.82))
        )
        .overlay(
            Capsule()
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct OnboardingSelectableCard<Content: View>: View {
    let isSelected: Bool
    var tint: Color = .coral
    var isDisabled = false
    let content: Content

    init(isSelected: Bool, tint: Color = .coral, isDisabled: Bool = false, @ViewBuilder content: () -> Content) {
        self.isSelected = isSelected
        self.tint = tint
        self.isDisabled = isDisabled
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            content
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg)
                .fill(
                    LinearGradient(
                        colors: isSelected
                            ? [tint.opacity(0.16), Color.loopSurf2.opacity(0.98)]
                            : [Color.loopSurf2.opacity(0.96), Color.loopSurf1.opacity(0.96)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(isDisabled ? Color.borderSoft : (isSelected ? tint.opacity(0.45) : Color.borderMid), lineWidth: 1)
        )
        .shadow(color: isSelected ? tint.opacity(0.12) : .clear, radius: 12, y: 8)
        .opacity(isDisabled ? 0.48 : 1)
    }
}

private struct OnboardingWelcomeView: View {
    let next: () -> Void

    var body: some View {
        OnboardingContainer(
            title: "Bienvenido a Loop",
            subtitle: "Aprende programacion con retos diarios y un plan adaptado a tu ritmo.",
            eyebrow: "Inicio"
        ) {
            ViewThatFits(in: .vertical) {
                HStack(alignment: .top, spacing: Spacing.md) {
                    LoopyView(mood: .speaking)
                        .frame(width: 100, height: 110)
                    LoopyBubbleView(text: "Te guiare paso a paso para construir constancia real y progreso medible.")
                }

                VStack(alignment: .leading, spacing: Spacing.md) {
                    LoopyView(mood: .speaking)
                        .frame(width: 100, height: 110)
                    LoopyBubbleView(text: "Te guiare paso a paso para construir constancia real y progreso medible.")
                }
            }

            ViewThatFits(in: .vertical) {
                HStack(spacing: Spacing.sm) {
                    OnboardingMiniPill(icon: "sparkles", text: "Plan hecho para ti")
                    OnboardingMiniPill(icon: "clock.fill", text: "Sesiones cortas", tint: .mint)
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    OnboardingMiniPill(icon: "sparkles", text: "Plan hecho para ti")
                    OnboardingMiniPill(icon: "clock.fill", text: "Sesiones cortas", tint: .mint)
                }
            }

            LoopCard(accentColor: .coral, showsSceneAccent: true) {
                featureRow(icon: "star.fill", title: "Rutas claras", detail: "Progreso visual por modulos.")
                featureRow(icon: "bolt.fill", title: "Sesiones cortas", detail: "Lecciones de alto impacto.")
                featureRow(icon: "checkmark.circle.fill", title: "Feedback inmediato", detail: "Correccion al instante.")
            }

            LoopCTA(title: "Continuar", trailingIcon: "arrow.right", style: .solid(.coral), action: next)
        }
    }

    private func featureRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(.periwinkle)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(LoopFont.bold(14)).foregroundColor(.textPrimary)
                Text(detail).font(LoopFont.regular(13)).foregroundColor(.textSecond)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

private struct OnboardingNameView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    private let avatars = ["person.circle.fill", "laptopcomputer", "terminal.fill", "cpu.fill", "gamecontroller.fill"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 5)

    private var trimmedName: String {
        viewModel.userProfile.name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        OnboardingContainer(title: "Tu identidad", subtitle: "Cuentame tu nombre y elige un avatar.", eyebrow: "Perfil") {
            LoopCard(accentColor: .periwinkle, showsSceneAccent: true) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Asi se vera tu perfil")
                        .font(LoopFont.semiBold(13))
                        .foregroundColor(.textSecond)

                    ViewThatFits(in: .vertical) {
                        HStack(spacing: Spacing.md) {
                            profileAvatar

                            VStack(alignment: .leading, spacing: 4) {
                                profileTitle
                                Text("Tu nombre aparecera en tu racha, perfil y celebraciones.")
                                    .font(LoopFont.regular(13))
                                    .foregroundColor(.textSecond)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            profileAvatar
                            VStack(alignment: .leading, spacing: 4) {
                                profileTitle
                                Text("Tu nombre aparecera en tu racha, perfil y celebraciones.")
                                    .font(LoopFont.regular(13))
                                    .foregroundColor(.textSecond)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }

                Divider().overlay(Color.borderSoft)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Nombre")
                        .font(LoopFont.semiBold(13))
                        .foregroundColor(.textSecond)

                    TextField("Tu nombre", text: $viewModel.userProfile.name)
                        .font(LoopFont.medium(17))
                        .foregroundColor(.textPrimary)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.continue)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, 14)
                        .background(Color.loopSurf2.opacity(0.82))
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .stroke(Color.borderMid, lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Avatar")
                        .font(LoopFont.semiBold(13))
                        .foregroundColor(.textSecond)

                    LazyVGrid(columns: columns, spacing: Spacing.sm) {
                        ForEach(0 ..< avatars.count, id: \.self) { index in
                            Button {
                                viewModel.userProfile.avatarIndex = index
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(index == viewModel.userProfile.avatarIndex ? Color.coral.opacity(0.18) : Color.loopSurf2)
                                    Image(systemName: avatars[index])
                                        .font(.system(size: 19, weight: .bold))
                                        .foregroundColor(index == viewModel.userProfile.avatarIndex ? .white : .periwinkle)
                                }
                                .frame(height: 56)
                                .background(
                                    Circle()
                                        .fill(
                                            index == viewModel.userProfile.avatarIndex
                                                ? LinearGradient(
                                                    colors: [Color.coral, Color.amethyst.opacity(0.9)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                                : LinearGradient(
                                                    colors: [Color.loopSurf2, Color.loopSurf2],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                        )
                                )
                                .overlay(Circle().stroke(index == viewModel.userProfile.avatarIndex ? Color.white.opacity(0.24) : Color.borderSoft, lineWidth: 1.4))
                                .scaleEffect(index == viewModel.userProfile.avatarIndex ? 1 : 0.96)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            LoopCTA(title: "Continuar", trailingIcon: "arrow.right", isDisabled: trimmedName.isEmpty, style: .solid(.coral)) {
                viewModel.userProfile.name = trimmedName
                viewModel.next()
            }
        }
    }

    private var profileAvatar: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color.amethyst, Color.cerulean],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 56, height: 56)
            .overlay(
                Image(systemName: avatars[viewModel.userProfile.avatarIndex])
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            )
    }

    private var profileTitle: some View {
        Text(trimmedName.isEmpty ? "Loop Learner" : trimmedName)
            .font(LoopFont.bold(18))
            .foregroundColor(.textPrimary)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct OnboardingAgeView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingContainer(title: "Selecciona tu edad", subtitle: "Usamos este dato para ajustar ritmo y tono del contenido.", eyebrow: "Edad") {
            AgeDialPicker(
                age: Binding(
                    get: { viewModel.userProfile.age },
                    set: { newAge in
                        viewModel.userProfile.age = min(max(newAge, 4), 99)
                        viewModel.userProfile.ageRange = AgeRange.from(age: viewModel.userProfile.age)
                    }
                )
            )
            LoopCTA(title: "Continuar", trailingIcon: "arrow.right", style: .solid(.coral)) { viewModel.next() }
        }
    }
}

private struct AgeDialPicker: View {
    @Binding var age: Int
    @State private var sliderValue: Double = 17
    @State private var lastHapticAge: Int = -1

    private let minAge = 4
    private let maxAge = 99
    private let ringSize: CGFloat = 236
    private let ringLineWidth: CGFloat = 24
    private let tickCount = 24
    private var rangeSpan: Int { maxAge - minAge }
    private var ringProgress: CGFloat {
        CGFloat(age - minAge) / CGFloat(max(rangeSpan, 1))
    }
    private var ageDescriptor: (title: String, detail: String, tint: Color) {
        switch age {
        case 4 ... 12:
            return ("Guiado", "Ritmo guiado, ejemplos claros y progreso muy visual.", .mint)
        case 13 ... 15:
            return ("Explora", "Practica corta y claridad total para que avanzar se sienta ligero.", .periwinkle)
        case 16 ... 18:
            return ("Prepa", "Fundamentos mas proyectos para sumar traccion desde la semana uno.", .coral)
        case 19 ... 22:
            return ("Carrera", "Mas intensidad y ejemplos reales para conectar teoria con practica.", .amethyst)
        case 23 ... 28:
            return ("Portfolio", "Constancia, proyectos y avance visible sin saturar tu semana.", .loopGold)
        default:
            return ("Pro", "Sesiones flexibles y enfoque practico para aprovechar mejor tu tiempo.", .cerulean)
        }
    }

    var body: some View {
        LoopCard(accentColor: ageDescriptor.tint, showsSceneAccent: true) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                ViewThatFits(in: .vertical) {
                    HStack(alignment: .top, spacing: Spacing.md) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Edad real")
                                .font(LoopFont.semiBold(14))
                                .foregroundColor(.textPrimary)
                            Text("Ajusta el aro o usa los botones para afinar el plan.")
                                .font(LoopFont.regular(13))
                                .foregroundColor(.textSecond)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        OnboardingMiniPill(icon: "sparkles", text: ageDescriptor.title, tint: ageDescriptor.tint)
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Edad real")
                            .font(LoopFont.semiBold(14))
                            .foregroundColor(.textPrimary)
                        OnboardingMiniPill(icon: "sparkles", text: ageDescriptor.title, tint: ageDescriptor.tint)
                        Text("Ajusta el aro o usa los botones para afinar el plan.")
                            .font(LoopFont.regular(13))
                            .foregroundColor(.textSecond)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                ZStack {
                    Circle()
                        .fill(ageDescriptor.tint.opacity(0.08))
                        .frame(width: ringSize, height: ringSize)
                        .blur(radius: 2)

                    Circle()
                        .stroke(Color.periwinkle.opacity(0.1), lineWidth: ringLineWidth)
                        .frame(width: ringSize, height: ringSize)

                    tickMarks

                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [ageDescriptor.tint.opacity(0.12), ageDescriptor.tint, Color.periwinkle]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: ringSize, height: ringSize)

                    Circle()
                        .fill(Color.periwinkle)
                        .frame(width: 18, height: 18)
                        .shadow(color: ageDescriptor.tint.opacity(0.4), radius: 10)
                        .offset(ringHandleOffset)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.98), ageDescriptor.tint.opacity(0.28)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 138, height: 138)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: ageDescriptor.tint.opacity(0.18), radius: 22, y: 10)
                        .overlay(
                            VStack(spacing: 2) {
                                Text("EDAD")
                                    .font(LoopFont.bold(10))
                                    .foregroundColor(Color.loopBG.opacity(0.55))
                                Text("\(age)")
                                    .font(LoopFont.black(48))
                                    .foregroundColor(Color.loopBG)
                                Text(AgeRange.from(age: age).rawValue)
                                    .font(LoopFont.bold(13))
                                    .foregroundColor(Color.loopBG.opacity(0.72))
                            }
                        )
                }
                .frame(maxWidth: .infinity)
                .frame(width: ringSize, height: ringSize)
                .contentShape(Circle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            updateAgeFromRingDrag(location: value.location)
                        }
                )

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(spacing: Spacing.sm) {
                        Text("Rango \(AgeRange.from(age: age).rawValue)")
                            .font(LoopFont.bold(12))
                            .foregroundColor(ageDescriptor.tint)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, 7)
                            .background(ageDescriptor.tint.opacity(0.12))
                            .clipShape(Capsule())

                        Spacer()

                        Text("\(age) anos")
                            .font(LoopFont.bold(14))
                            .foregroundColor(.textPrimary)
                    }

                    Text(ageDescriptor.detail)
                        .font(LoopFont.regular(13))
                        .foregroundColor(.textSecond)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(minHeight: 38, alignment: .topLeading)
                }

                HStack(spacing: Spacing.md) {
                    AgeAdjustButton(icon: "minus", tint: ageDescriptor.tint, isDisabled: age == minAge) {
                        selectAge(age - 1, triggerHeavy: true)
                    }

                    Slider(
                        value: $sliderValue,
                        in: Double(minAge) ... Double(maxAge),
                        step: 1
                    )
                    .tint(ageDescriptor.tint)
                    .onChange(of: sliderValue) { _, _ in
                        let newAge = Int(sliderValue.rounded())
                        age = min(max(newAge, minAge), maxAge)
                        if age != lastHapticAge {
                            triggerHaptic(.light)
                            lastHapticAge = age
                        }
                    }

                    AgeAdjustButton(icon: "plus", tint: ageDescriptor.tint, isDisabled: age == maxAge) {
                        selectAge(age + 1, triggerHeavy: true)
                    }
                }

                HStack {
                    Text("\(minAge)").font(LoopFont.bold(16)).foregroundColor(.textSecond)
                    Spacer()
                    Text("Arrastra el aro o usa +/-")
                        .font(LoopFont.regular(12))
                        .foregroundColor(.textMuted)
                    Spacer()
                    Text("\(maxAge)").font(LoopFont.bold(16)).foregroundColor(.textSecond)
                }
            }
        }
        .onAppear {
            age = min(max(age, minAge), maxAge)
            sliderValue = Double(age)
            lastHapticAge = age
        }
        .onChange(of: age) { _, newAge in
            let clamped = min(max(newAge, minAge), maxAge)
            if Int(sliderValue.rounded()) != clamped {
                sliderValue = Double(clamped)
            }
            if clamped != lastHapticAge {
                lastHapticAge = clamped
            }
        }
    }

    private var tickMarks: some View {
        ZStack {
            ForEach(0 ..< tickCount, id: \.self) { index in
                Capsule()
                    .fill(Double(index) / Double(max(tickCount - 1, 1)) <= Double(ringProgress) ? ageDescriptor.tint.opacity(0.85) : Color.borderSoft)
                    .frame(width: index.isMultiple(of: 3) ? 3 : 2, height: index.isMultiple(of: 3) ? 14 : 8)
                    .offset(y: -((ringSize / 2) - (ringLineWidth / 2) - 2))
                    .rotationEffect(.degrees(Double(index) / Double(tickCount) * 360))
            }
        }
        .frame(width: ringSize, height: ringSize)
    }

    private func selectAge(_ value: Int, triggerHeavy: Bool) {
        let clamped = min(max(value, minAge), maxAge)
        if clamped == age { return }
        age = clamped
        withAnimation(.spring(response: 0.24, dampingFraction: 0.84)) {
            sliderValue = Double(clamped)
        }
        if triggerHeavy {
            triggerHaptic(.medium)
            lastHapticAge = clamped
        }
    }

    private var ringHandleOffset: CGSize {
        let radius = (ringSize / 2) - (ringLineWidth / 2)
        let angle = (2 * .pi * ringProgress) - (.pi / 2)
        return CGSize(width: cos(angle) * radius, height: sin(angle) * radius)
    }

    private func updateAgeFromRingDrag(location: CGPoint) {
        let center = CGPoint(x: ringSize / 2, y: ringSize / 2)
        let dx = location.x - center.x
        let dy = location.y - center.y

        var angle = atan2(dy, dx) + (.pi / 2)
        if angle < 0 { angle += 2 * .pi }
        let normalized = angle / (2 * .pi)

        let newAge = minAge + Int(round(normalized * Double(rangeSpan)))
        let clamped = min(max(newAge, minAge), maxAge)
        if clamped != age {
            age = clamped
            sliderValue = Double(clamped)
            if clamped != lastHapticAge {
                triggerHaptic(.light)
                lastHapticAge = clamped
            }
        }
    }

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

private struct AgeAdjustButton: View {
    let icon: String
    let tint: Color
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(isDisabled ? Color.loopSurf2 : tint.opacity(0.14))
                .frame(width: 42, height: 42)
                .overlay(
                    Circle()
                        .stroke(isDisabled ? Color.borderSoft : tint.opacity(0.24), lineWidth: 1)
                )
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(isDisabled ? .textMuted : tint)
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

private struct OnboardingGoalView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingContainer(title: "Objetivo principal", subtitle: "Elegimos una ruta basada en lo que quieres lograr.", eyebrow: "Objetivo") {
            Text("Tu objetivo define el tono del plan, el tipo de ejercicios y la forma en la que te medimos avance.")
                .font(LoopFont.regular(13))
                .foregroundColor(.textSecond)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: Spacing.sm) {
                goalCard(.createApps, icon: "app.fill", detail: "Construir tus propias apps")
                goalCard(.getJob, icon: "briefcase.fill", detail: "Prepararte para entrevistas")
                goalCard(.passClasses, icon: "graduationcap.fill", detail: "Mejorar en materias tecnicas")
                goalCard(.curiosity, icon: "sparkles", detail: "Explorar por interes personal")
            }
            LoopCTA(title: "Continuar", trailingIcon: "arrow.right", style: .solid(.coral)) { viewModel.next() }
        }
    }

    private func goalCard(_ goal: LearningGoal, icon: String, detail: String) -> some View {
        Button {
            viewModel.userProfile.goal = goal
        } label: {
            OnboardingSelectableCard(isSelected: viewModel.userProfile.goal == goal, tint: .coral) {
                HStack(spacing: Spacing.md) {
                    Circle()
                        .fill(viewModel.userProfile.goal == goal ? Color.coral.opacity(0.22) : Color.loopSurf3)
                        .frame(width: 42, height: 42)
                        .overlay(
                            Image(systemName: icon)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(viewModel.userProfile.goal == goal ? .white : .periwinkle)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.rawValue).font(LoopFont.bold(15)).foregroundColor(.textPrimary)
                        Text(detail).font(LoopFont.regular(13)).foregroundColor(.textSecond)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Image(systemName: viewModel.userProfile.goal == goal ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(viewModel.userProfile.goal == goal ? .mint : .textMuted)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct OnboardingLevelView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingContainer(title: "Nivel actual", subtitle: "Selecciona tu punto de partida real.", eyebrow: "Nivel") {
            VStack(spacing: Spacing.sm) {
                ForEach(Level.allCases) { level in
                    Button {
                        viewModel.userProfile.knowledgeLevel = level
                    } label: {
                        OnboardingSelectableCard(
                            isSelected: viewModel.userProfile.knowledgeLevel == level,
                            tint: .amethyst,
                            isDisabled: viewModel.wantsPlacementTest
                        ) {
                            HStack(spacing: Spacing.md) {
                                Circle()
                                    .fill(viewModel.userProfile.knowledgeLevel == level ? Color.amethyst.opacity(0.2) : Color.loopSurf3)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: icon(for: level))
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(viewModel.userProfile.knowledgeLevel == level ? .white : .periwinkle)
                                    )

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(level.rawValue)
                                        .font(LoopFont.semiBold(14))
                                        .foregroundColor(.textPrimary)
                                    Text(detail(for: level))
                                        .font(LoopFont.regular(13))
                                        .foregroundColor(.textSecond)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer()

                                if viewModel.wantsPlacementTest {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.textMuted)
                                } else if viewModel.userProfile.knowledgeLevel == level {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.mint)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.wantsPlacementTest)
                }
            }

            if viewModel.wantsPlacementTest {
                OnboardingMiniPill(icon: "lock.fill", text: "El mini test definira tu nivel", tint: .loopGold)
            }

            LoopCard(accentColor: viewModel.wantsPlacementTest ? .loopGold : .clear, showsSceneAccent: viewModel.wantsPlacementTest) {
                Toggle(isOn: $viewModel.wantsPlacementTest) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hacer mini test de placement")
                            .font(LoopFont.semiBold(14))
                            .foregroundColor(.textPrimary)
                        Text("Si activas esto, arrancamos con 3 preguntas para ajustar mejor tu modulo inicial.")
                            .font(LoopFont.regular(13))
                            .foregroundColor(.textSecond)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(.coral)
            }

            LoopCTA(title: "Continuar", trailingIcon: "arrow.right", style: .solid(.coral)) { viewModel.next() }
        }
    }

    private func detail(for level: Level) -> String {
        switch level {
        case .zero:
            return "Prefieres partir sin asumir contexto previo."
        case .someReading:
            return "Ya viste conceptos sueltos, pero todavia no se sienten naturales."
        case .basicKnows:
            return "Entiendes la base y quieres practicar con mas direccion."
        case .hasPractice:
            return "Ya haces ejercicios y buscas mas consistencia o profundidad."
        }
    }

    private func icon(for level: Level) -> String {
        switch level {
        case .zero:
            return "0.circle.fill"
        case .someReading:
            return "book.fill"
        case .basicKnows:
            return "hammer.fill"
        case .hasPractice:
            return "bolt.fill"
        }
    }
}

private struct OnboardingTimeView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    private let minuteOptions = [5, 10, 15, 20, 30]
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    private let dayColumns = [GridItem(.adaptive(minimum: 78), spacing: Spacing.sm)]

    private var weeklyMinutes: Int {
        viewModel.userProfile.minutesPerDay * viewModel.userProfile.activeDays.count
    }

    var body: some View {
        OnboardingContainer(title: "Tiempo disponible", subtitle: "Define tu ritmo semanal para mantener consistencia.", eyebrow: "Rutina") {
            LoopCard(accentColor: .cerulean, showsSceneAccent: true) {
                ViewThatFits(in: .vertical) {
                    HStack {
                        weeklySummary
                        Spacer()
                        activeDaysSummary
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        weeklySummary
                        activeDaysSummary
                    }
                }
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Minutos por dia")
                    .font(LoopFont.semiBold(13))
                    .foregroundColor(.textSecond)

                LazyVGrid(columns: columns, spacing: Spacing.sm) {
                    ForEach(minuteOptions, id: \.self) { option in
                        Button {
                            viewModel.userProfile.minutesPerDay = option
                        } label: {
                            OnboardingSelectableCard(isSelected: viewModel.userProfile.minutesPerDay == option, tint: .coral) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(option) min")
                                        .font(LoopFont.bold(16))
                                        .foregroundColor(.textPrimary)
                                    Text(option <= 10 ? "Sprint express" : option <= 20 ? "Ritmo balanceado" : "Bloque profundo")
                                        .font(LoopFont.regular(12))
                                        .foregroundColor(.textSecond)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Dias activos")
                    .font(LoopFont.semiBold(13))
                    .foregroundColor(.textSecond)

                LazyVGrid(columns: dayColumns, spacing: Spacing.sm) {
                    ForEach(Weekday.allCases) { day in
                        Button {
                            if viewModel.userProfile.activeDays.contains(day) {
                                viewModel.userProfile.activeDays.remove(day)
                            } else {
                                viewModel.userProfile.activeDays.insert(day)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(day.rawValue)
                                        .font(LoopFont.bold(16))
                                        .foregroundColor(viewModel.userProfile.activeDays.contains(day) ? .white : .textPrimary)

                                    Spacer()

                                    if viewModel.userProfile.activeDays.contains(day) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.white)
                                    }
                                }

                                Text(dayTitle(for: day))
                                    .font(LoopFont.regular(12))
                                    .foregroundColor(viewModel.userProfile.activeDays.contains(day) ? Color.white.opacity(0.82) : .textSecond)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: Radius.md)
                                    .fill(
                                        viewModel.userProfile.activeDays.contains(day)
                                            ? LinearGradient(
                                                colors: [Color.coral, Color.amethyst.opacity(0.9)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                            : LinearGradient(
                                                colors: [Color.loopSurf2, Color.loopSurf1.opacity(0.96)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.md)
                                    .stroke(viewModel.userProfile.activeDays.contains(day) ? Color.white.opacity(0.16) : Color.borderSoft, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("Selecciona los dias en los que de verdad puedes sostener el ritmo.")
                    .font(LoopFont.regular(12))
                    .foregroundColor(.textSecond)
            }

            LoopCTA(title: "Generar plan", trailingIcon: "sparkles", isDisabled: viewModel.userProfile.activeDays.isEmpty, style: .solid(.coral)) {
                viewModel.generatePlan()
                viewModel.next()
            }
        }
    }

    private var weeklySummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Tu ritmo estimado")
                .font(LoopFont.semiBold(13))
                .foregroundColor(.textSecond)
            Text("\(weeklyMinutes) min por semana")
                .font(LoopFont.bold(20))
                .foregroundColor(.textPrimary)
        }
    }

    private var activeDaysSummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(viewModel.userProfile.activeDays.count) dias activos")
                .font(LoopFont.bold(18))
                .foregroundColor(.mint)
            Text("Tu plan se va a repartir sobre esos bloques.")
                .font(LoopFont.regular(12))
                .foregroundColor(.textSecond)
        }
    }

    private func dayTitle(for day: Weekday) -> String {
        switch day {
        case .l:
            return "Lunes"
        case .m:
            return "Martes"
        case .x:
            return "Miercoles"
        case .j:
            return "Jueves"
        case .v:
            return "Viernes"
        case .s:
            return "Sabado"
        case .d:
            return "Domingo"
        }
    }
}

private struct OnboardingPlanView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let finish: () -> Void
    @State private var showReasons = false

    var body: some View {
        let plan = viewModel.userProfile.generatedPlan ?? PlanGenerator.generatePlan(from: viewModel.userProfile)
        OnboardingContainer(title: "Tu plan esta listo", subtitle: "Se genera al final del onboarding con tus datos reales.", eyebrow: "Plan IA") {
            LoopCard(accentColor: .amethyst, showsSceneAccent: true) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    ViewThatFits(in: .vertical) {
                        HStack(alignment: .top) {
                            planHeader(plan: plan)
                            Spacer()
                            OnboardingMiniPill(icon: "sparkles", text: "Plan listo", tint: .amethyst)
                        }

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            planHeader(plan: plan)
                            OnboardingMiniPill(icon: "sparkles", text: "Plan listo", tint: .amethyst)
                        }
                    }

                    ViewThatFits(in: .vertical) {
                        HStack(spacing: Spacing.sm) {
                            planMetric(title: "Ritmo", value: "\(viewModel.userProfile.minutesPerDay)m", tint: .coral)
                            planMetric(title: "Dias", value: "\(viewModel.userProfile.activeDays.count)", tint: .mint)
                            planMetric(title: "Inicio", value: "M\(plan.startModule)", tint: .periwinkle)
                        }

                        VStack(spacing: Spacing.sm) {
                            planMetric(title: "Ritmo", value: "\(viewModel.userProfile.minutesPerDay)m", tint: .coral)
                            planMetric(title: "Dias", value: "\(viewModel.userProfile.activeDays.count)", tint: .mint)
                            planMetric(title: "Inicio", value: "M\(plan.startModule)", tint: .periwinkle)
                        }
                    }
                }
            }

            LoopCard(accentColor: .periwinkle) {
                Text("Por que este plan")
                    .font(LoopFont.bold(16))
                    .foregroundColor(.textPrimary)
                    .padding(.bottom, Spacing.xs)
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(Array(plan.aiReasons.enumerated()), id: \.offset) { index, reason in
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Circle().fill(Color.periwinkle).frame(width: 6, height: 6).padding(.top, 6)
                            Text(reason)
                                .font(LoopFont.regular(13))
                                .foregroundColor(.textSecond)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .opacity(showReasons ? 1 : 0)
                        .offset(y: showReasons ? 0 : 8)
                        .animation(.easeOut(duration: 0.35).delay(Double(index) * 0.12), value: showReasons)
                    }
                }
            }

            LoopCard(accentColor: .mint) {
                Text("Tu primera semana")
                    .font(LoopFont.bold(16))
                    .foregroundColor(.textPrimary)
                Text("Vas a practicar \(viewModel.userProfile.minutesPerDay) minutos en \(viewModel.userProfile.activeDays.count) dias para construir ritmo antes de subir intensidad.")
                    .font(LoopFont.regular(13))
                    .foregroundColor(.textSecond)
                    .fixedSize(horizontal: false, vertical: true)
            }

            LoopCTA(title: "Comenzar", trailingIcon: "arrow.right", style: .solid(.coral)) { finish() }
        }
        .onAppear { showReasons = true }
    }

    private func planHeader(plan: LearningPlan) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(plan.language.rawValue) · Modulo \(plan.startModule)")
                .font(LoopFont.bold(18))
                .foregroundColor(.textPrimary)
            Text("\(plan.dailyLessons) leccion diaria · \(plan.weeksEstimated) semanas estimadas")
                .font(LoopFont.regular(14))
                .foregroundColor(.textSecond)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func planMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(LoopFont.bold(10))
                .foregroundColor(.textMuted)
            Text(value)
                .font(LoopFont.bold(16))
                .foregroundColor(.textPrimary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }
}

#Preview {
    OnboardingFlow().environmentObject(AppState())
}
