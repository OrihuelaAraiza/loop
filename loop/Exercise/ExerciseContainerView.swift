import SwiftUI

struct ExerciseContainerView: View {
    let exercise: ExerciseResponse
    @ObservedObject var viewModel: ExerciseViewModel
    var onSequenceCompleted: () -> Void
    var onClose: () -> Void

    @Environment(\.isJuniorMode) private var isJuniorMode

    var body: some View {
        ZStack {
            LoopMeshBackground()

            VStack(spacing: 0) {
                exerciseHeader

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        promptSection
                        exerciseContent

                        if !exercise.hints.isEmpty {
                            hintsSection
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }

                bottomBar
            }

            if viewModel.showResult {
                ResultOverlayView(
                    result: viewModel.answerResult,
                    exercise: exercise,
                    headline: viewModel.feedbackTitle,
                    isJuniorMode: isJuniorMode,
                    isShowingCorrectAnswer: viewModel.revealedCorrectAnswer,
                    onNext: handlePrimaryAction,
                    onRetry: viewModel.retryCurrentExercise,
                    onShowCorrectAnswer: viewModel.revealCorrectAnswer
                )
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var exerciseHeader: some View {
        HStack(spacing: 16) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.periwinkle)
                    .frame(width: 36, height: 36)
                    .background(Color.loopSurf2.opacity(0.95))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.borderMid, lineWidth: 1))
            }
            .buttonStyle(.plain)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.loopSurf2)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.coral)
                        .frame(width: geo.size.width * viewModel.moduleProgress)
                        .animation(LoopAnimation.springMedium, value: viewModel.moduleProgress)
                }
            }
            .frame(height: 8)

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.loopGold)
                    .font(.system(size: 12))
                Text("+\(exercise.xpReward)")
                    .font(LoopFont.bold(14))
                    .foregroundColor(.loopGold)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.loopGold.opacity(0.14))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.loopBG.opacity(0.96))
    }

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            exerciseTypeBadge

            Text(exercise.prompt)
                .font(LoopFont.bold(LoopLayout.fontSize(base: 20, junior: isJuniorMode)))
                .foregroundColor(.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var exerciseTypeBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: exerciseTypeIcon)
                .font(.system(size: 11, weight: .semibold))
            Text(exerciseTypeLabel)
                .font(LoopFont.semiBold(11))
        }
        .foregroundColor(.periwinkle)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.loopSurf2)
        .clipShape(Capsule())
    }

    private var exerciseTypeIcon: String {
        switch exercise.type {
        case .fillInBlank:
            return "pencil"
        case .dragAndDrop:
            return "hand.draw"
        case .debug:
            return "ladybug"
        case .trivia:
            return "questionmark.circle"
        case .miniProject:
            return "hammer"
        }
    }

    private var exerciseTypeLabel: String {
        switch exercise.type {
        case .fillInBlank:
            return isJuniorMode ? "Completa" : "Rellena el espacio"
        case .dragAndDrop:
            return isJuniorMode ? "Ordena" : "Arrastra y suelta"
        case .debug:
            return isJuniorMode ? "Encuentra el error" : "Debug"
        case .trivia:
            return isJuniorMode ? "Pregunta" : "Trivia"
        case .miniProject:
            return isJuniorMode ? "Crea algo" : "Mini proyecto"
        }
    }

    @ViewBuilder
    private var exerciseContent: some View {
        switch exercise.type {
        case .fillInBlank:
            FillInBlankExerciseView(exercise: exercise, userAnswer: $viewModel.userAnswer)
        case .dragAndDrop:
            DragDropExerciseView(exercise: exercise, userAnswer: $viewModel.userAnswer)
        case .debug:
            DebugExerciseView(exercise: exercise, userAnswer: $viewModel.userAnswer)
        case .trivia:
            TriviaExerciseView(exercise: exercise, userAnswer: $viewModel.userAnswer)
        case .miniProject:
            MiniProjectExerciseView(exercise: exercise, userAnswer: $viewModel.userAnswer)
        }
    }

    private var hintsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(LoopAnimation.springBouncy) {
                    viewModel.revealNextHint()
                }
                HapticManager.shared.impact(.light)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 14))
                        .foregroundColor(.loopGold)
                    Text(viewModel.hintsRevealed == 0
                         ? "Ver pista"
                         : "Ver otra pista (\(exercise.hints.count - viewModel.hintsRevealed) restantes)")
                        .font(LoopFont.semiBold(14))
                        .foregroundColor(.loopGold)
                    Spacer()
                }
                .padding(14)
                .background(Color.loopGold.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.loopGold.opacity(0.3), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.hasMoreHints)

            ForEach(Array(viewModel.revealedHints.enumerated()), id: \.offset) { _, hint in
                Text(hint)
                    .font(LoopFont.regular(14))
                    .foregroundColor(.textSecond)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.loopSurf2)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.borderSoft)
                .frame(height: 1)

            Button {
                Task { await viewModel.submitAnswer(isJuniorMode: isJuniorMode) }
                HapticManager.shared.impact(.medium)
            } label: {
                HStack {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Verificar")
                            .font(LoopFont.bold(17))
                    }
                }
            }
            .buttonStyle(LoopCTAButton())
            .disabled(viewModel.userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSubmitting)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.loopBG)
    }

    private func handlePrimaryAction() {
        if viewModel.answerResult?.isCorrect == true {
            if viewModel.isLastExercise {
                onSequenceCompleted()
            } else {
                _ = viewModel.advanceToNextExercise()
            }
        } else {
            viewModel.retryCurrentExercise()
        }
    }
}
