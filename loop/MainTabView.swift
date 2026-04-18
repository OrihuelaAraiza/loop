import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selected: MainTab = .home
    @State private var showExercise = false
    @State private var showCelebration = false

    var body: some View {
        Group {
            switch selected {
            case .home:
                HomeView(onStartLesson: { showExercise = true })
                    .environmentObject(appState)
            case .routes:
                RoutesView()
                    .environmentObject(appState)
            case .map:
                MapView()
            case .profile:
                ProfileView()
                    .environmentObject(appState)
            }
        }
        .overlay(alignment: .bottom) {
            BottomNavBar(selected: $selected)
                .ignoresSafeArea(edges: .bottom)
        }
        .fullScreenCover(isPresented: $showExercise) {
            ExerciseView(
                lesson: appState.todayLesson,
                initialExerciseIndex: appState.lessonProgress(for: appState.todayLesson?.id)?.exerciseIndex,
                onCompleted: {
                    showExercise = false
                    showCelebration = true
                },
                onClose: {
                    showExercise = false
                }
            )
            .environmentObject(appState)
        }
        .fullScreenCover(isPresented: $showCelebration) {
            CelebrationView {
                showCelebration = false
            }
            .environmentObject(appState)
        }
        .onAppear {
            appState.refreshTodayLesson()
        }
        .onChange(of: appState.selectedMainTab) { _, newTab in
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                selected = newTab
            }
        }
    }
}

private struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.isJuniorMode) private var isJuniorMode
    @State private var showCustomizerSheet = false
    @State private var showSettingsSheet = false

    var body: some View {
        ZStack {
            AmbientBackground(topColor: .amethyst, bottomColor: .cerulean)
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        HStack(alignment: .top, spacing: Spacing.md) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(LoopCopy.profileTitle(junior: isJuniorMode))
                                    .font(LoopFont.black(28))
                                    .foregroundColor(.textPrimary)
                                Text("Tu tarjeta vive aquí. Tócala para girarla, arrastrarla y abre ajustes desde Editar.")
                                    .font(LoopFont.regular(13))
                                    .foregroundColor(.textSecond)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Button {
                                showSettingsSheet = true
                            } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.textPrimary)
                                    .frame(width: 40, height: 40)
                                    .background(Color.loopSurf2.opacity(0.9))
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.borderMid, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Ajustes")
                        }

                        LoopIdentityCard(
                            userProfile: appState.userProfile,
                            gameState: appState.gameState,
                            isCustomizerPresented: showCustomizerSheet,
                            onCustomize: {
                                showCustomizerSheet = true
                            }
                        )
                        .padding(.horizontal, 4)
                        .padding(.top, 6)
                        .padding(.bottom, 6)
                    }

                    ViewThatFits(in: .vertical) {
                        HStack(spacing: Spacing.md) {
                            statCard(title: "Nivel", value: "\(appState.gameState.level)", tint: .periwinkle)
                            statCard(title: "\(LoopCopy.xpLabel(junior: isJuniorMode)) total", value: "\(appState.gameState.totalXP)", tint: .loopGold)
                        }

                        VStack(spacing: Spacing.md) {
                            statCard(title: "Nivel", value: "\(appState.gameState.level)", tint: .periwinkle)
                            statCard(title: "\(LoopCopy.xpLabel(junior: isJuniorMode)) total", value: "\(appState.gameState.totalXP)", tint: .loopGold)
                        }
                    }

                    LoopCard(accentColor: .cerulean, showsSceneAccent: true, usesGlassSurface: true) {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Enfoque actual")
                                .font(LoopFont.bold(16))
                                .foregroundColor(.textPrimary)
                            Text(summaryLine)
                                .font(LoopFont.regular(14))
                                .foregroundColor(.textSecond)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(Spacing.lg)
                .padding(.top, Spacing.xl)
                .padding(.bottom, 90)
            }
        }
        .sheet(isPresented: $showCustomizerSheet) {
            ProfileCustomizationSheet(
                userProfile: Binding(
                    get: { appState.userProfile },
                    set: { appState.userProfile = $0 }
                )
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsSheet()
                .environmentObject(appState)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private func statCard(title: String, value: String, tint: Color) -> some View {
        LoopCard(accentColor: tint, usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title.uppercased())
                    .font(LoopFont.bold(10))
                    .foregroundColor(.textMuted)
                Text(value)
                    .font(LoopFont.black(24))
                    .foregroundColor(.textPrimary)
            }
        }
    }

    private var summaryLine: String {
        let name = appState.userProfile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = name.isEmpty ? "Loop Learner" : name
        let language = appState.userProfile.generatedPlan?.language.rawValue ?? "Python"
        let goal = LoopCopy.goalName(appState.userProfile.goal, junior: isJuniorMode).lowercased()
        return "\(displayName) está en ruta de \(goal), practicando \(appState.userProfile.minutesPerDay) minutos por sesión en \(language)."
    }
}

private struct ProfileCustomizationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isJuniorMode) private var isJuniorMode
    @Binding var userProfile: UserProfile

    private func compactSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(LoopFont.semiBold(13))
                .foregroundColor(.textSecond)
            content()
        }
    }

    var body: some View {
        ZStack {
            AmbientBackground(topColor: .amethyst, bottomColor: .cerulean)
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    header

                    LoopCard(accentColor: customizationTint, usesGlassSurface: true) {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            compactSection(title: "Paleta") {
                                HStack(spacing: Spacing.sm) {
                                    ForEach(IdentityCardPalette.allCases) { palette in
                                        Button {
                                            userProfile.cardPalette = palette
                                        } label: {
                                            paletteSwatch(palette)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            compactSection(title: "Badge") {
                                chipGrid(
                                    options: IdentityCardBadge.availableBadges(junior: isJuniorMode).map(\.rawValue),
                                    selected: IdentityCardBadge.normalizedForJunior(userProfile.cardBadge, junior: isJuniorMode).rawValue,
                                    tintResolver: badgeTint(label:)
                                ) { value in
                                    if let badge = IdentityCardBadge.availableBadges(junior: isJuniorMode).first(where: { $0.rawValue == value }) {
                                        userProfile.cardBadge = badge
                                    }
                                }
                            }

                            compactSection(title: "Superficie") {
                                chipGrid(
                                    options: IdentityCardSurface.allCases.map(\.rawValue),
                                    selected: userProfile.cardSurface.rawValue,
                                    tintResolver: { _ in customizationTint }
                                ) { value in
                                    if let surface = IdentityCardSurface.allCases.first(where: { $0.rawValue == value }) {
                                        userProfile.cardSurface = surface
                                    }
                                }
                            }

                            compactSection(title: "Avatar") {
                                avatarSelector
                            }

                            compactSection(title: "Brillo") {
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Slider(value: $userProfile.cardGlowStrength, in: 0.1 ... 1, step: 0.05)
                                        .tint(customizationTint)
                                    Text("\(Int(userProfile.cardGlowStrength * 100))%")
                                        .font(LoopFont.medium(11))
                                        .foregroundColor(.textSecond)
                                }
                            }

                            toggleRow(title: "Movimiento 3D", isOn: $userProfile.cardMotionEnabled)
                            toggleRow(title: "Arrastrar card", isOn: $userProfile.cardDragEnabled)
                        }
                    }
                }
                .padding(Spacing.lg)
                .padding(.bottom, 18)
            }
        }
        .onAppear {
            userProfile.cardBadge = IdentityCardBadge.normalizedForJunior(userProfile.cardBadge, junior: isJuniorMode)
        }
        .onChange(of: isJuniorMode) { _, newValue in
            userProfile.cardBadge = IdentityCardBadge.normalizedForJunior(userProfile.cardBadge, junior: newValue)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Ajustes de tarjeta")
                    .font(LoopFont.black(24))
                    .foregroundColor(.textPrimary)
                Text("Personaliza estilo, interacciones y look de tu card 3D.")
                    .font(LoopFont.regular(13))
                    .foregroundColor(.textSecond)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button("Listo") {
                dismiss()
            }
            .font(LoopFont.bold(13))
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 8)
            .background(Color.loopSurf2.opacity(0.9))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.borderMid, lineWidth: 1)
            )
            .buttonStyle(.plain)
        }
    }

    private func paletteSwatch(_ palette: IdentityCardPalette) -> some View {
        VStack(spacing: 6) {
            Circle()
                .fill(paletteTint(for: palette))
                .frame(width: 18, height: 18)
                .padding(6)
                .background(
                    Circle()
                        .fill(Color.loopSurf2.opacity(0.9))
                )
                .overlay(
                    Circle()
                        .stroke(userProfile.cardPalette == palette ? paletteTint(for: palette) : Color.borderSoft, lineWidth: 1.4)
                )

            Text(palette.rawValue)
                .font(LoopFont.medium(12))
                .foregroundColor(userProfile.cardPalette == palette ? .textPrimary : .textSecond)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    private var avatarSelector: some View {
        let avatars = ["person.circle.fill", "laptopcomputer", "terminal.fill", "cpu.fill", "gamecontroller.fill"]
        return ViewThatFits(in: .vertical) {
            HStack(spacing: Spacing.sm) {
                ForEach(Array(avatars.enumerated()), id: \.offset) { index, symbol in
                    avatarButton(index: index, symbol: symbol)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(Array(avatars.enumerated()), id: \.offset) { index, symbol in
                        avatarButton(index: index, symbol: symbol)
                    }
                }
            }
        }
    }

    private func avatarButton(index: Int, symbol: String) -> some View {
        Button {
            userProfile.avatarIndex = index
        } label: {
            Circle()
                .fill(userProfile.avatarIndex == index ? customizationTint.opacity(0.18) : Color.loopSurf2.opacity(0.9))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: symbol)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(userProfile.avatarIndex == index ? .white : .periwinkle)
                )
                .overlay(
                    Circle()
                        .stroke(userProfile.avatarIndex == index ? customizationTint.opacity(0.56) : Color.borderSoft, lineWidth: 1.3)
                )
        }
        .buttonStyle(.plain)
    }

    private func chipGrid(options: [String], selected: String, tintResolver: @escaping (String) -> Color, onSelect: @escaping (String) -> Void) -> some View {
        ViewThatFits {
            HStack(spacing: Spacing.sm) {
                ForEach(options, id: \.self) { option in
                    Button {
                        onSelect(option)
                    } label: {
                        capsuleOption(
                            option,
                            isSelected: selected == option,
                            tint: tintResolver(option)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(options, id: \.self) { option in
                    Button {
                        onSelect(option)
                    } label: {
                        capsuleOption(
                            option,
                            isSelected: selected == option,
                            tint: tintResolver(option)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func capsuleOption(_ title: String, isSelected: Bool, tint: Color) -> some View {
        Text(title)
            .font(LoopFont.medium(12))
            .foregroundColor(isSelected ? .textPrimary : .textSecond)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? tint.opacity(0.18) : Color.loopSurf2.opacity(0.9))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? tint.opacity(0.4) : Color.borderSoft, lineWidth: 1)
            )
    }

    private func toggleRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: Spacing.md) {
            Text(title)
                .font(LoopFont.semiBold(13))
                .foregroundColor(.textPrimary)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(customizationTint)
        }
    }

    private func paletteTint(for palette: IdentityCardPalette) -> Color {
        switch palette {
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

    private func badgeTint(label: String) -> Color {
        switch label {
        case IdentityCardBadge.creador.rawValue:
            return .coral
        case IdentityCardBadge.enfoque.rawValue:
            return .cerulean
        case IdentityCardBadge.racha.rawValue:
            return .loopGold
        case IdentityCardBadge.mentor.rawValue:
            return .mint
        case IdentityCardBadge.ninja.rawValue:
            return .amethyst
        default:
            return customizationTint
        }
    }

    private var customizationTint: Color {
        paletteTint(for: userProfile.cardPalette)
    }
}
