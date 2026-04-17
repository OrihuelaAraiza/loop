import SwiftUI

struct ExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ExerciseViewModel()

    let onCompleted: () -> Void
    var onClose: (() -> Void)?

    var body: some View {
        ExerciseContainerView(
            exercise: viewModel.currentExercise,
            viewModel: viewModel,
            onSequenceCompleted: onCompleted,
            onClose: closeFlow
        )
    }

    private func closeFlow() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
}
