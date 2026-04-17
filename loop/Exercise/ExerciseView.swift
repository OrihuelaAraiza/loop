import SwiftUI

struct ExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: ExerciseViewModel

    let onCompleted: () -> Void
    var onClose: (() -> Void)?

    init(lesson: LessonPayload? = nil, onCompleted: @escaping () -> Void, onClose: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: ExerciseViewModel(lesson: lesson))
        self.onCompleted = onCompleted
        self.onClose = onClose
    }

    var body: some View {
        ExerciseContainerView(
            exercise: viewModel.currentExercise,
            viewModel: viewModel,
            onSequenceCompleted: handleSequenceCompleted,
            onClose: closeFlow
        )
    }

    private func handleSequenceCompleted() {
        if let lessonID = viewModel.lessonID,
           let token = appState.authSession?.apiToken {
            Task {
                _ = try? await OnboardingAPIClient().completeLesson(token: token, lessonID: lessonID)
                await MainActor.run { appState.refreshTodayLesson() }
            }
        }

        onCompleted()
    }

    private func closeFlow() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
}
