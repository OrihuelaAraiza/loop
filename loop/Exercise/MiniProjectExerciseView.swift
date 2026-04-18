import SwiftUI

struct MiniProjectExerciseView: View {
    let exercise: ExerciseResponse
    @Binding var userAnswer: String

    @Environment(\.isJuniorMode) private var isJuniorMode
    @FocusState private var editorFocused: Bool
    @State private var lineCount = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            projectContext
            codeEditor
            outputPanel
        }
    }

    private var projectContext: some View {
        HStack(spacing: 12) {
            Image(systemName: "hammer.fill")
                .foregroundColor(.amethyst)
                .font(.system(size: 16))
                .frame(width: 36, height: 36)
                .background(Color.amethyst.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(isJuniorMode ? "Tu turno de crear" : "Mini proyecto")
                    .font(LoopFont.bold(14))
                    .foregroundColor(.textPrimary)
                Text(isJuniorMode ? "Escribe tu código y toca Verificar" : "Escribe el código y presiona Verificar")
                    .font(LoopFont.regular(12))
                    .foregroundColor(.textSecond)
            }
        }
        .padding(14)
        .background(Color.amethyst.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.amethyst.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var codeEditor: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    ForEach([Color.coral, Color.loopGold, Color.mint], id: \.self) { color in
                        Circle().fill(color).frame(width: 10, height: 10)
                    }
                }
                Spacer()
                Text("main.py")
                    .font(LoopFont.regular(11))
                    .foregroundColor(.textMuted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.loopSurf1)

            Rectangle()
                .fill(Color.borderSoft)
                .frame(height: 1)

            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(1...max(1, lineCount), id: \.self) { number in
                        Text("\(number)")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.textMuted)
                            .frame(height: 21)
                    }
                }
                .padding(.leading, 12)
                .padding(.trailing, 16)
                .padding(.top, 12)

                TextEditor(text: $userAnswer)
                    .font(.system(
                        size: LoopLayout.fontSize(base: 14, junior: isJuniorMode),
                        weight: .regular,
                        design: .monospaced
                    ))
                    .foregroundColor(.textPrimary)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($editorFocused)
                    .frame(minHeight: 140)
                    .padding(.top, 8)
                    .padding(.trailing, 12)
                    .onChange(of: userAnswer) { _, value in
                        lineCount = max(1, value.components(separatedBy: "\n").count)
                    }
            }
            .background(Color.loopSurf2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(editorFocused ? Color.amethyst.opacity(0.5) : Color.borderMid, lineWidth: editorFocused ? 2 : 1)
        )
        .animation(LoopAnimation.springFast, value: editorFocused)
        .onAppear {
            if let template = exercise.codeTemplate, userAnswer.isEmpty {
                userAnswer = template.replacingOccurrences(of: "___", with: "")
                lineCount = max(1, userAnswer.components(separatedBy: "\n").count)
            }
        }
    }

    private var outputPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "terminal")
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)
                Text("Output")
                    .font(LoopFont.semiBold(12))
                    .foregroundColor(.textMuted)
            }

            Text(isJuniorMode ? "Aquí verás el resultado cuando termines" : "El resultado aparecerá al verificar")
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.textMuted)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.loopSurf1)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
