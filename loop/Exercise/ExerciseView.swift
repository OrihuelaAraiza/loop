import HighlightSwift
import SwiftUI

struct ExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ExerciseViewModel()
    let onCompleted: () -> Void
    var onClose: (() -> Void)?

    var body: some View {
        ZStack {
            AmbientBackground(topColor: .cerulean, bottomColor: .amethyst)
            VStack(spacing: Spacing.lg) {
                topBar
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("FILL IN BLANK")
                        .font(LoopFont.bold(11))
                        .foregroundColor(.coral)
                    Text(viewModel.exercise.question)
                        .font(LoopFont.bold(19))
                        .foregroundColor(.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                codeBlock
                choices
                feedback

                if viewModel.isCorrect == true {
                    LoopCTA(title: "Continuar · +10 XP", action: onCompleted)
                }
                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
        }
    }

    private var topBar: some View {
        HStack(spacing: Spacing.md) {
            Button {
                if let onClose {
                    onClose()
                } else {
                    dismiss()
                }
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
            .accessibilityLabel("Cerrar leccion")

            LoopProgressBar(progress: viewModel.progress, height: 8)
                .frame(height: 8)
            HStack(spacing: 4) {
                ForEach(0 ..< 3, id: \.self) { idx in
                    Image(systemName: idx < viewModel.hearts ? "heart.fill" : "heart")
                        .foregroundColor(idx < viewModel.hearts ? .coral : .textMuted)
                }
            }
        }
    }

    private var codeBlock: some View {
        LoopCard(accentColor: .coral) {
            if let snippet = viewModel.exercise.codeSnippet {
                CodeText(snippet)
                    .highlightLanguage(.python)
                    .codeTextColors(.theme(.github))
                    .codeTextStyle(.card(cornerRadius: 10))
                    .font(.system(size: 14, design: .monospaced))
            }
        }
    }

    private var choices: some View {
        let options = viewModel.exercise.choices ?? []
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                Button {
                    viewModel.submit(choice: index)
                } label: {
                    Text(option)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 12)
                        .background(Color.loopSurf2)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .stroke(borderColor(for: index), lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func borderColor(for index: Int) -> Color {
        guard let selected = viewModel.selectedIndex else { return .borderSoft }
        if selected != index { return .borderSoft }
        return viewModel.isCorrect == true ? .mint : .coral
    }

    @ViewBuilder
    private var feedback: some View {
        if let isCorrect = viewModel.isCorrect {
            LoopCard(accentColor: isCorrect ? .mint : .coral) {
                HStack(alignment: .top, spacing: Spacing.sm) {
                    LoopyView(mood: isCorrect ? .celebrating : .sad).frame(width: 56, height: 56)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isCorrect ? "Respuesta correcta" : "Respuesta incorrecta")
                            .font(LoopFont.bold(14))
                            .foregroundColor(isCorrect ? .mint : .coral)
                        Text(viewModel.exercise.explanation)
                            .font(LoopFont.regular(12))
                            .foregroundColor(.textSecond)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}
