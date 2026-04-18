import SwiftUI

struct LessonTheoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    let onStartPractice: () -> Void
    var onClose: (() -> Void)?

    @StateObject private var viewModel: LessonTheoryViewModel
    @State private var revealContent = false

    init(
        lesson: LessonPayload,
        courseLanguage: String = "Python",
        initialStepIndex: Int? = nil,
        onStartPractice: @escaping () -> Void,
        onClose: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: LessonTheoryViewModel(
                backendLesson: lesson,
                courseLanguage: courseLanguage,
                initialStepIndex: initialStepIndex,
                difficultyHint: lesson.difficulty
            )
        )
        self.onStartPractice = onStartPractice
        self.onClose = onClose
    }

    var body: some View {
        ZStack {
            AmbientBackground(
                topColor: currentTint,
                bottomColor: secondaryTint
            )

            VStack(spacing: Spacing.md) {
                topBar
                lessonMetaBar
                progressHeader
                stepRail

                if viewModel.steps.isEmpty {
                    emptyState
                } else {
                    TabView(selection: tabSelection) {
                        ForEach(Array(viewModel.steps.enumerated()), id: \.element.id) { index, step in
                            LessonStepRenderer(
                                step: step,
                                stepIndex: index,
                                totalSteps: viewModel.totalSteps,
                                tint: tint(for: index),
                                state: viewModel.renderState(for: step),
                                onPrimaryAction: {
                                    viewModel.triggerPrimaryInteraction(for: step)
                                    HapticManager.shared.impact(.light)
                                },
                                onSelectChoice: { choiceID in
                                    viewModel.selectChoice(choiceID, for: step)
                                    HapticManager.shared.selection()
                                }
                            )
                            .tag(index)
                            .padding(.horizontal, Spacing.lg)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .opacity(revealContent ? 1 : 0)
                    .offset(y: revealContent ? 0 : 16)
                    .animation(LoopAnimation.springSoft, value: revealContent)
                    .animation(LoopAnimation.springSoft, value: viewModel.currentStepIndex)
                }

                bottomNav
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.md)
            }
            .padding(.top, Spacing.lg)
        }
        .onAppear {
            withAnimation(LoopAnimation.springMedium) {
                revealContent = true
            }
            persistTheoryProgress()
        }
        .onChange(of: viewModel.currentStepIndex) { _, _ in
            HapticManager.shared.selection()
            persistTheoryProgress()
        }
    }

    private var tabSelection: Binding<Int> {
        Binding(
            get: { viewModel.currentStepIndex },
            set: { viewModel.handlePageChange(to: $0) }
        )
    }

    private var currentTint: Color {
        tint(for: viewModel.currentStepIndex)
    }

    private var secondaryTint: Color {
        tint(for: viewModel.currentStepIndex + 1).opacity(0.9)
    }

    private var topBar: some View {
        HStack {
            Button {
                HapticManager.shared.impact(.light)
                handleClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.loopSurf2.opacity(0.9))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.borderMid, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cerrar teoria")

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("Teoria microlearning")
                    .font(LoopFont.bold(12))
                    .foregroundColor(.textPrimary)
                Text("\(viewModel.currentStepIndex + 1) de \(viewModel.totalSteps)")
                    .font(LoopFont.regular(12))
                    .foregroundColor(.textSecond)
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    private var lessonMetaBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                heroPill(icon: "number", text: "Leccion \(viewModel.lesson.orderIndex)", color: .periwinkle)
                heroPill(icon: "clock.fill", text: "\(viewModel.lesson.estimatedDuration) min", color: .amethyst)
                heroPill(icon: "bolt.fill", text: "+\(viewModel.lesson.xpReward) XP", color: .coral)
                heroPill(icon: "sparkles", text: viewModel.lesson.difficulty.badgeLabel, color: currentTint)
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(viewModel.lesson.title)
                    .font(LoopFont.black(22))
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
                Spacer(minLength: 0)
                Text("\(Int(viewModel.progressFraction * 100))%")
                    .font(LoopFont.bold(14))
                    .foregroundColor(currentTint)
            }

            HStack(spacing: 6) {
                ForEach(0..<viewModel.totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(segmentStyle(for: index))
                        .frame(height: 6)
                        .frame(maxWidth: index == viewModel.currentStepIndex ? .infinity : 28)
                        .animation(LoopAnimation.springFast, value: viewModel.currentStepIndex)
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    private var stepRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(viewModel.steps.enumerated()), id: \.element.id) { index, step in
                    let renderState = viewModel.renderState(for: step)

                    Button {
                        viewModel.jump(to: index)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: renderState.isCompleted ? "checkmark.circle.fill" : "circle.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text(step.type.shortLabel)
                                .font(LoopFont.bold(11))
                        }
                        .foregroundColor(index == viewModel.currentStepIndex ? .white : .textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.pill)
                                .fill(index == viewModel.currentStepIndex ? tint(for: index) : Color.loopSurf2.opacity(0.84))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.pill)
                                .stroke(
                                    index == viewModel.currentStepIndex
                                        ? tint(for: index).opacity(0.22)
                                        : Color.borderSoft,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    private var emptyState: some View {
        LoopCard(accentColor: .mint, usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Sin teoria disponible")
                    .font(LoopFont.bold(16))
                    .foregroundColor(.textPrimary)
                Text("No llegaron pasos teoricos desde el backend. La pantalla sigue estable y puedes ir directo a ejercicios.")
                    .font(LoopFont.regular(14))
                    .foregroundColor(.textSecond)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    private var bottomNav: some View {
        HStack(spacing: Spacing.md) {
            Button {
                HapticManager.shared.impact(.light)
                viewModel.goToPreviousStep()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 13, weight: .bold))
                    Text("Anterior")
                        .font(LoopFont.bold(14))
                }
                .foregroundColor(viewModel.currentStepIndex == 0 ? .textMuted : .textPrimary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.loopSurf2.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(Color.borderMid, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.currentStepIndex == 0)
            .opacity(viewModel.currentStepIndex == 0 ? 0.55 : 1)

            Button {
                HapticManager.shared.impact(.medium)
                if viewModel.isLastStep {
                    handleStartPractice()
                } else {
                    viewModel.goToNextStep()
                }
            } label: {
                HStack(spacing: 6) {
                    Text(viewModel.isLastStep ? "Ir a ejercicios" : "Siguiente")
                        .font(LoopFont.bold(15))
                    Image(systemName: viewModel.isLastStep ? "sparkles" : "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: viewModel.isLastStep
                            ? [Color.coral, Color.amethyst]
                            : [currentTint, secondaryTint],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                .shadow(color: currentTint.opacity(0.32), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
        }
    }

    private func heroPill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(LoopFont.bold(12))
        }
        .foregroundColor(color)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 7)
        .background(color.opacity(0.14))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.24), lineWidth: 1))
    }

    private func tint(for index: Int) -> Color {
        let palette: [Color] = [.coral, .amethyst, .periwinkle, .loopGold, .mint, .cerulean]
        return palette[abs(index) % palette.count]
    }

    private func segmentStyle(for index: Int) -> AnyShapeStyle {
        if index == viewModel.currentStepIndex {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [currentTint, secondaryTint],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }

        let state = viewModel.renderState(for: viewModel.steps[index])
        if state.isCompleted {
            return AnyShapeStyle(currentTint.opacity(0.5))
        }
        if state.isVisited {
            return AnyShapeStyle(Color.periwinkle.opacity(0.35))
        }
        return AnyShapeStyle(Color.trackInactive)
    }

    private func persistTheoryProgress() {
        appState.saveTheoryProgress(
            lessonID: viewModel.lesson.id,
            stepIndex: viewModel.currentStepIndex,
            totalSteps: viewModel.totalSteps
        )
    }

    private func handleClose() {
        persistTheoryProgress()
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    private func handleStartPractice() {
        appState.savePracticeProgress(
            lessonID: viewModel.lesson.id,
            exerciseIndex: appState.lessonProgress(for: viewModel.lesson.id)?.exerciseIndex ?? 0,
            totalExercises: viewModel.lesson.source.exerciseCount
        )
        onStartPractice()
    }
}

private extension StepType {
    var shortLabel: String {
        switch self {
        case .intro:
            return "Intro"
        case .concept:
            return "Idea"
        case .keyPoints:
            return "Claves"
        case .revealCard:
            return "Reveal"
        case .analogy:
            return "Analog"
        case .exampleCode:
            return "Codigo"
        case .codePrediction:
            return "Predice"
        case .miniQuiz:
            return "Quiz"
        case .trueFalse:
            return "V/F"
        case .tapToReveal:
            return "Tap"
        case .dragMatch:
            return "Match"
        case .summary:
            return "Resumen"
        case .checkpoint:
            return "Check"
        case .completion:
            return "Final"
        }
    }
}
