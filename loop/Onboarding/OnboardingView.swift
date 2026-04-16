import SwiftUI

struct OnboardingFlow: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            AmbientBackground(topColor: .amethyst, bottomColor: .cerulean)

            VStack(spacing: 0) {
                LoopSegmentedProgress(currentStep: viewModel.step, totalSteps: viewModel.totalSteps)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, Spacing.md)
                stepContent
            }
        }
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

private struct OnboardingContainer<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content

    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                Text(title)
                    .font(LoopFont.black(28))
                    .foregroundColor(.textPrimary)
                Text(subtitle)
                    .font(LoopFont.regular(15))
                    .foregroundColor(.textSecond)
                content
            }
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.section)
        }
        .padding(.horizontal, Spacing.xl)
    }
}

private struct OnboardingWelcomeView: View {
    let next: () -> Void

    var body: some View {
        OnboardingContainer(
            title: "Bienvenido a Loop",
            subtitle: "Aprende programación con retos diarios y un plan adaptado a tu ritmo."
        ) {
            HStack(alignment: .top, spacing: Spacing.md) {
                LoopyView(mood: .speaking)
                LoopyBubbleView(text: "Te guiaré paso a paso para que construyas constancia real.")
            }

            LoopCard(accentColor: .coral) {
                featureRow(icon: "star.fill", title: "Rutas claras", detail: "Progreso visual por módulos.")
                featureRow(icon: "bolt.fill", title: "Sesiones cortas", detail: "Lecciones de alto impacto.")
                featureRow(icon: "checkmark.circle.fill", title: "Feedback inmediato", detail: "Corrección al instante.")
            }

            LoopCTA(title: "Continuar", action: next)
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

    var body: some View {
        OnboardingContainer(title: "Tu identidad", subtitle: "Cuéntame tu nombre y elige un avatar.") {
            LoopCard {
                TextField("Tu nombre", text: $viewModel.userProfile.name)
                    .font(LoopFont.medium(16))
                    .foregroundColor(.textPrimary)
                    .textInputAutocapitalization(.words)
                Divider().overlay(Color.borderSoft)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: Spacing.sm) {
                    ForEach(0 ..< avatars.count, id: \.self) { index in
                        Button {
                            viewModel.userProfile.avatarIndex = index
                        } label: {
                            ZStack {
                                Circle().fill(Color.loopSurf2)
                                Image(systemName: avatars[index]).foregroundColor(.periwinkle)
                            }
                            .frame(height: 52)
                            .overlay(Circle().stroke(index == viewModel.userProfile.avatarIndex ? Color.coral : Color.borderSoft, lineWidth: 2))
                        }.buttonStyle(.plain)
                    }
                }
            }
            LoopCTA(title: "Continuar") { viewModel.next() }
        }
    }
}

private struct OnboardingAgeView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        OnboardingContainer(title: "Rango de edad", subtitle: "Esto nos ayuda a ajustar el ritmo y ejemplos.") {
            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(AgeRange.allCases) { age in
                    chip(
                        title: age.rawValue,
                        selected: viewModel.userProfile.ageRange == age
                    ) { viewModel.userProfile.ageRange = age }
                }
            }
            LoopCTA(title: "Continuar") { viewModel.next() }
        }
    }

    private func chip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(LoopFont.semiBold(13))
                .foregroundColor(selected ? .white : .periwinkle)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selected ? Color.coral : Color.loopSurf2)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(selected ? Color.coral : Color.borderSoft, lineWidth: 1))
        }.buttonStyle(.plain)
    }
}

private struct OnboardingGoalView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingContainer(title: "Objetivo principal", subtitle: "Elegimos una ruta basada en lo que quieres lograr.") {
            VStack(spacing: Spacing.sm) {
                goalCard(.createApps, icon: "rocket.fill", detail: "Construir tus propias apps")
                goalCard(.getJob, icon: "briefcase.fill", detail: "Prepararte para entrevistas")
                goalCard(.passClasses, icon: "graduationcap.fill", detail: "Mejorar en materias técnicas")
                goalCard(.curiosity, icon: "sparkles", detail: "Explorar por interés personal")
            }
            LoopCTA(title: "Continuar") { viewModel.next() }
        }
    }

    private func goalCard(_ goal: LearningGoal, icon: String, detail: String) -> some View {
        Button {
            viewModel.userProfile.goal = goal
        } label: {
            LoopCard(accentColor: viewModel.userProfile.goal == goal ? .coral : .clear) {
                HStack {
                    Image(systemName: icon).foregroundColor(.periwinkle)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.rawValue).font(LoopFont.bold(15)).foregroundColor(.textPrimary)
                        Text(detail).font(LoopFont.regular(13)).foregroundColor(.textSecond)
                    }
                    Spacer()
                    Image(systemName: viewModel.userProfile.goal == goal ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(viewModel.userProfile.goal == goal ? .mint : .textMuted)
                }
            }
        }.buttonStyle(.plain)
    }
}

private struct OnboardingLevelView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingContainer(title: "Nivel actual", subtitle: "Selecciona tu punto de partida real.") {
            VStack(spacing: Spacing.sm) {
                ForEach(Level.allCases) { level in
                    Button {
                        viewModel.userProfile.knowledgeLevel = level
                    } label: {
                        HStack {
                            Text(level.rawValue)
                                .font(LoopFont.semiBold(14))
                                .foregroundColor(.textPrimary)
                            Spacer()
                            if viewModel.userProfile.knowledgeLevel == level {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.mint)
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.md)
                        .background(Color.loopSurf2)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        .overlay(RoundedRectangle(cornerRadius: Radius.md).stroke(Color.borderMid, lineWidth: 1))
                    }.buttonStyle(.plain)
                }
            }

            Toggle(isOn: $viewModel.wantsPlacementTest) {
                Text("Hacer mini test de placement (3 preguntas)")
                    .font(LoopFont.regular(13))
                    .foregroundColor(.textSecond)
            }
            .tint(.coral)

            LoopCTA(title: "Continuar") { viewModel.next() }
        }
    }
}

private struct OnboardingTimeView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    private let minuteOptions = [5, 10, 15, 20, 30]

    var body: some View {
        OnboardingContainer(title: "Tiempo disponible", subtitle: "Define tu ritmo semanal para mantener consistencia.") {
            HStack(spacing: Spacing.sm) {
                ForEach(minuteOptions, id: \.self) { option in
                    Button {
                        viewModel.userProfile.minutesPerDay = option
                    } label: {
                        Text("\(option)m")
                            .font(LoopFont.bold(13))
                            .foregroundColor(viewModel.userProfile.minutesPerDay == option ? .white : .periwinkle)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(viewModel.userProfile.minutesPerDay == option ? Color.coral : Color.loopSurf2)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: Spacing.sm) {
                ForEach(Weekday.allCases) { day in
                    Button {
                        if viewModel.userProfile.activeDays.contains(day) {
                            viewModel.userProfile.activeDays.remove(day)
                        } else {
                            viewModel.userProfile.activeDays.insert(day)
                        }
                    } label: {
                        Text(day.rawValue)
                            .font(LoopFont.bold(12))
                            .foregroundColor(viewModel.userProfile.activeDays.contains(day) ? .white : .textSecond)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(viewModel.userProfile.activeDays.contains(day) ? Color.coral : Color.loopSurf2)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                    }.buttonStyle(.plain)
                }
            }

            LoopCTA(title: "Generar plan") {
                viewModel.generatePlan()
                viewModel.next()
            }
        }
    }
}

private struct OnboardingPlanView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let finish: () -> Void
    @State private var showReasons = false

    var body: some View {
        let plan = viewModel.userProfile.generatedPlan ?? PlanGenerator.generatePlan(from: viewModel.userProfile)
        OnboardingContainer(title: "Tu plan está listo", subtitle: "Se genera al final del onboarding con tus datos reales.") {
            LoopCard(accentColor: .amethyst) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("\(plan.language.rawValue) · Módulo \(plan.startModule)")
                        .font(LoopFont.bold(17))
                        .foregroundColor(.textPrimary)
                    Text("\(plan.dailyLessons) lección diaria · \(plan.weeksEstimated) semanas estimadas")
                        .font(LoopFont.regular(14))
                        .foregroundColor(.textSecond)
                }
            }

            LoopCard(accentColor: .periwinkle) {
                Text("Por qué este plan")
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

            LoopCTA(title: "Comenzar") { finish() }
        }
        .onAppear { showReasons = true }
    }
}

#Preview {
    OnboardingFlow().environmentObject(AppState())
}
