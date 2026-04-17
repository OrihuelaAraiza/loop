import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var juniorMode = JuniorModeManager.shared
    @State private var notificationsEnabled = true
    @State private var hapticsEnabled = true
    @State private var soundEnabled = true
    @State private var reduceMotion = false
    @State private var analyticsEnabled = true

    @State private var showSignOutConfirm = false
    @State private var showResetConfirm = false

    var body: some View {
        ZStack {
            AmbientBackground(topColor: .amethyst, bottomColor: .cerulean)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    header
                    accountSection
                    learningSection
                    appSection
                    dangerSection
                    footer
                }
                .padding(Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
        }
        .alert("Cerrar sesion", isPresented: $showSignOutConfirm) {
            Button("Cerrar sesion", role: .destructive) {
                appState.signOut()
                dismiss()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Volveras a la pantalla de inicio de sesion. Tu progreso local se mantiene guardado.")
        }
        .alert("Reiniciar onboarding", isPresented: $showResetConfirm) {
            Button("Reiniciar", role: .destructive) {
                appState.resetForOnboarding()
                dismiss()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se borrara tu perfil, racha y XP local, y volveras al flujo de onboarding. Util para pruebas.")
        }
        .onAppear {
            if juniorMode.isActive {
                appState.userProfile.cardBadge = IdentityCardBadge.normalizedForJunior(
                    appState.userProfile.cardBadge,
                    junior: true
                )
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Ajustes")
                    .font(LoopFont.black(26))
                    .foregroundColor(.textPrimary)
                Text("Personaliza notificaciones, cuenta y experiencia de aprendizaje.")
                    .font(LoopFont.regular(13))
                    .foregroundColor(.textSecond)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button("Listo") {
                dismiss()
            }
            .font(LoopFont.bold(13))
            .foregroundColor(.textPrimary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 8)
            .background(Color.loopSurf2.opacity(0.9))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.borderMid, lineWidth: 1))
            .buttonStyle(.plain)
        }
    }

    // MARK: - Cuenta

    private var accountSection: some View {
        settingsCard(title: "Cuenta", icon: "person.crop.circle.fill", tint: .periwinkle) {
            VStack(spacing: Spacing.sm) {
                infoRow(label: "Nombre", value: displayName)
                divider
                infoRow(label: "Email", value: appState.authSession?.email ?? "Sin correo")
                divider
                infoRow(label: "Metodo", value: providerLabel)
                divider
                infoRow(label: "ID", value: shortID)
            }
        }
    }

    private var displayName: String {
        let trimmed = appState.userProfile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        return appState.authSession?.displayName ?? "Loop Learner"
    }

    private var providerLabel: String {
        switch appState.authSession?.provider {
        case .apple: return "Apple ID"
        case .password: return "Email y contrasena"
        case .mockApple: return "Modo demo"
        case .none: return "Sin sesion"
        }
    }

    private var shortID: String {
        guard let id = appState.authSession?.userID, !id.isEmpty else { return "—" }
        return String(id.prefix(12)) + "…"
    }

    // MARK: - Aprendizaje

    private var learningSection: some View {
        settingsCard(title: "Aprendizaje", icon: "graduationcap.fill", tint: .mint) {
            VStack(spacing: Spacing.sm) {
                stepperRow(
                    label: "Minutos por sesion",
                    value: appState.userProfile.minutesPerDay,
                    range: 5 ... 60,
                    step: 5,
                    suffix: "min"
                ) { newValue in
                    appState.userProfile.minutesPerDay = newValue
                }
                divider
                stepperRow(
                    label: "Meta diaria de XP",
                    value: appState.gameState.dailyGoal,
                    range: 10 ... 100,
                    step: 5,
                    suffix: LoopCopy.xpLabel(junior: juniorMode.isActive)
                ) { newValue in
                    appState.gameState.dailyGoal = newValue
                }
                divider
                activeDaysRow
                divider
                toggleRow(
                    title: "Modo Junior",
                    subtitle: "Adapta copy y presentacion para perfiles menores de 13.",
                    isOn: Binding(
                        get: { juniorMode.isActive },
                        set: { newValue in
                            juniorMode.isActive = newValue
                            if newValue {
                                appState.userProfile.cardBadge = IdentityCardBadge.normalizedForJunior(
                                    appState.userProfile.cardBadge,
                                    junior: true
                                )
                            }
                        }
                    )
                )
            }
        }
    }

    private var activeDaysRow: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Dias activos")
                .font(LoopFont.semiBold(13))
                .foregroundColor(.textSecond)

            HStack(spacing: Spacing.xs) {
                ForEach(Weekday.allCases) { day in
                    let isOn = appState.userProfile.activeDays.contains(day)
                    Button {
                        toggleDay(day)
                    } label: {
                        Text(day.rawValue)
                            .font(LoopFont.bold(12))
                            .foregroundColor(isOn ? .white : .textSecond)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(
                                Capsule()
                                    .fill(isOn ? Color.coral.opacity(0.8) : Color.loopSurf2.opacity(0.9))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(isOn ? Color.coral.opacity(0.3) : Color.borderSoft, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func toggleDay(_ day: Weekday) {
        var days = appState.userProfile.activeDays
        if days.contains(day) {
            days.remove(day)
        } else {
            days.insert(day)
        }
        appState.userProfile.activeDays = days
    }

    // MARK: - App

    private var appSection: some View {
        settingsCard(title: "App", icon: "slider.horizontal.3", tint: .cerulean) {
            VStack(spacing: Spacing.sm) {
                toggleRow(title: "Notificaciones", subtitle: "Recordatorios de racha y retos.", isOn: $notificationsEnabled)
                divider
                toggleRow(title: "Sonido", subtitle: "Efectos al completar lecciones.", isOn: $soundEnabled)
                divider
                toggleRow(title: "Vibracion", subtitle: "Feedback haptico en interacciones.", isOn: $hapticsEnabled)
                divider
                toggleRow(title: "Reducir movimiento", subtitle: "Minimiza animaciones y parallax.", isOn: $reduceMotion)
                divider
                toggleRow(title: "Compartir analiticas", subtitle: "Ayuda a mejorar Loop de forma anonima.", isOn: $analyticsEnabled)
            }
        }
    }

    // MARK: - Peligro / Pruebas

    private var dangerSection: some View {
        settingsCard(title: "Cuenta y pruebas", icon: "exclamationmark.shield.fill", tint: .coral) {
            VStack(spacing: Spacing.sm) {
                actionRow(
                    title: "Cerrar sesion",
                    subtitle: "Volveras a la pantalla de inicio de sesion.",
                    icon: "rectangle.portrait.and.arrow.right",
                    tint: .coral
                ) {
                    showSignOutConfirm = true
                }

                divider

                actionRow(
                    title: "Reiniciar onboarding",
                    subtitle: "Borra tu progreso local y vuelve al flujo inicial.",
                    icon: "arrow.counterclockwise.circle.fill",
                    tint: .loopGold
                ) {
                    showResetConfirm = true
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 4) {
            Text("loop")
                .font(LoopFont.black(16))
                .foregroundColor(.textPrimary)
            Text("Version 0.1 · Build interno")
                .font(LoopFont.regular(11))
                .foregroundColor(.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.sm)
    }

    // MARK: - Building blocks

    private func settingsCard<Content: View>(title: String, icon: String, tint: Color, @ViewBuilder content: @escaping () -> Content) -> some View {
        LoopCard(accentColor: tint.opacity(0.55), usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(tint)
                        .frame(width: 28, height: 28)
                        .background(tint.opacity(0.16))
                        .clipShape(Circle())
                    Text(title)
                        .font(LoopFont.bold(16))
                        .foregroundColor(.textPrimary)
                }

                content()
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.borderSoft)
            .frame(height: 1)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(LoopFont.semiBold(13))
                .foregroundColor(.textSecond)
            Spacer()
            Text(value)
                .font(LoopFont.medium(13))
                .foregroundColor(.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(LoopFont.semiBold(14))
                    .foregroundColor(.textPrimary)
                Text(subtitle)
                    .font(LoopFont.regular(12))
                    .foregroundColor(.textSecond)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.coral)
        }
    }

    private func stepperRow(label: String, value: Int, range: ClosedRange<Int>, step: Int, suffix: String, onChange: @escaping (Int) -> Void) -> some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            Text(label)
                .font(LoopFont.semiBold(14))
                .foregroundColor(.textPrimary)
            Spacer()
            HStack(spacing: Spacing.sm) {
                Button {
                    let newValue = max(range.lowerBound, value - step)
                    if newValue != value { onChange(newValue) }
                } label: {
                    stepperButton(icon: "minus")
                }
                .buttonStyle(.plain)

                Text("\(value) \(suffix)")
                    .font(LoopFont.bold(13))
                    .foregroundColor(.textPrimary)
                    .frame(minWidth: 64)

                Button {
                    let newValue = min(range.upperBound, value + step)
                    if newValue != value { onChange(newValue) }
                } label: {
                    stepperButton(icon: "plus")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func stepperButton(icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.textPrimary)
            .frame(width: 30, height: 30)
            .background(Color.loopSurf2.opacity(0.9))
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.borderMid, lineWidth: 1))
    }

    private func actionRow(title: String, subtitle: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(tint)
                    .frame(width: 32, height: 32)
                    .background(tint.opacity(0.16))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(LoopFont.bold(14))
                        .foregroundColor(.textPrimary)
                    Text(subtitle)
                        .font(LoopFont.regular(12))
                        .foregroundColor(.textSecond)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.textMuted)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsSheet().environmentObject(AppState())
}
