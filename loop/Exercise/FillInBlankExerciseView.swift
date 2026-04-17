import SwiftUI

struct FillInBlankExerciseView: View {
    let exercise: ExerciseResponse
    @Binding var userAnswer: String

    @Environment(\.isJuniorMode) private var isJuniorMode
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let template = exercise.codeTemplate {
                codeBlock(template: template)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(isJuniorMode ? "Tu respuesta:" : "Respuesta")
                    .font(LoopFont.semiBold(13))
                    .foregroundColor(.periwinkle)

                HStack {
                    TextField(
                        isJuniorMode ? "Escribe aqui..." : "Escribe tu respuesta",
                        text: $userAnswer
                    )
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(.textPrimary)
                    .focused($isInputFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                    if !userAnswer.isEmpty {
                        Button {
                            userAnswer = ""
                            HapticManager.shared.impact(.light)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.periwinkle)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
                .background(Color.loopSurf2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isInputFocused ? Color.coral : Color.periwinkle.opacity(0.2), lineWidth: isInputFocused ? 2 : 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .animation(LoopAnimation.springFast, value: isInputFocused)
            }
        }
        .onAppear {
            isInputFocused = true
        }
    }

    private func codeBlock(template: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    ForEach([Color.coral, Color.loopGold, Color.mint], id: \.self) { color in
                        Circle().fill(color).frame(width: 10, height: 10)
                    }
                }
                Spacer()
                Text(exercise.language)
                    .font(LoopFont.regular(11))
                    .foregroundColor(.textMuted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.loopSurf1)

            Rectangle()
                .fill(Color.borderSoft)
                .frame(height: 1)

            codeContent(template: template)
                .padding(14)
                .background(Color.loopSurf2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.borderMid, lineWidth: 1)
        )
    }

    private func codeContent(template: String) -> some View {
        let parts = template.components(separatedBy: "___")

        return HStack(spacing: 0) {
            ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                Text(part)
                    .font(.system(size: 15, weight: .regular, design: .monospaced))
                    .foregroundColor(.textPrimary)

                if index < parts.count - 1 {
                    Text(userAnswer.isEmpty ? "___" : userAnswer)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(userAnswer.isEmpty ? Color.coral.opacity(0.72) : .coral)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.coral.opacity(0.15))
                        )
                        .animation(LoopAnimation.springFast, value: userAnswer)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
