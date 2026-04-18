import SwiftUI

struct ExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: ExerciseViewModel

    let onCompleted: () -> Void
    var onClose: (() -> Void)?

    init(
        lesson: LessonPayload? = nil,
        initialExerciseIndex: Int? = nil,
        onCompleted: @escaping () -> Void,
        onClose: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: ExerciseViewModel(lesson: lesson, initialIndex: initialExerciseIndex))
        self.onCompleted = onCompleted
        self.onClose = onClose
    }

    var body: some View {
        Group {
            if let exercise = viewModel.currentExercise {
                ExerciseContainerView(
                    exercise: exercise,
                    viewModel: viewModel,
                    onSequenceCompleted: handleSequenceCompleted,
                    onClose: closeFlow
                )
            } else {
                ExerciseUnavailableView(
                    message: viewModel.loadError ?? "No pudimos cargar ejercicios desde el backend.",
                    onClose: closeFlow
                )
            }
        }
        .onAppear {
            persistProgress()
        }
        .onChange(of: viewModel.currentIndex) { _, _ in
            persistProgress()
        }
    }

    private func handleSequenceCompleted() {
        if let lessonID = viewModel.lessonID {
            appState.recordLessonCompletionLocally(
                lessonID: lessonID,
                lessonTitle: viewModel.lessonTitle,
                xpGained: viewModel.lessonXPReward ?? 0,
                heartsRemaining: appState.gameState.hearts
            )

            Task {
                await appState.completeLesson(lessonID: lessonID, lessonTitle: viewModel.lessonTitle)
            }
        }

        onCompleted()
    }

    private func closeFlow() {
        persistProgress()
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    private func persistProgress() {
        guard let lessonID = viewModel.lessonID, !viewModel.exercises.isEmpty else { return }
        appState.savePracticeProgress(
            lessonID: lessonID,
            exerciseIndex: viewModel.currentIndex,
            totalExercises: viewModel.exercises.count
        )
    }
}

private struct ExerciseUnavailableView: View {
    let message: String
    let onClose: () -> Void

    var body: some View {
        ZStack {
            LoopMeshBackground()

            VStack(spacing: Spacing.lg) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.loopGold)

                VStack(spacing: Spacing.sm) {
                    Text("Ejercicios no disponibles")
                        .font(LoopFont.bold(22))
                        .foregroundColor(.textPrimary)

                    Text(message)
                        .font(LoopFont.regular(14))
                        .foregroundColor(.textSecond)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                LoopCTA(title: "Cerrar", style: .solid(.coral), action: onClose)
            }
            .padding(.horizontal, Spacing.xl)
            .frame(maxWidth: 420)
        }
    }
}
