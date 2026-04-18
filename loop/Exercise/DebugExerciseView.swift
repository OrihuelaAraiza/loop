import SwiftUI

struct DebugExerciseView: View {
    let exercise: ExerciseResponse
    @Binding var userAnswer: String

    @Environment(\.isJuniorMode) private var isJuniorMode
    @State private var selectedLine: Int?
    @State private var lines: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isJuniorMode ? "Toca la linea que tiene el error:" : "Toca la linea con el error:")
                .font(LoopFont.semiBold(14))
                .foregroundColor(.periwinkle)

            VStack(spacing: 0) {
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

                VStack(spacing: 0) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        CodeLineView(
                            lineNumber: index + 1,
                            code: line,
                            isSelected: selectedLine == index,
                            isJuniorMode: isJuniorMode
                        ) {
                            withAnimation(LoopAnimation.springFast) {
                                selectedLine = index
                                userAnswer = "line:\(index + 1)"
                            }
                            HapticManager.shared.impact(.light)
                        }
                    }
                }
                .background(Color.loopSurf2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.borderMid, lineWidth: 1)
            )

            if let selectedLine {
                HStack(spacing: 8) {
                    Image(systemName: "ladybug.fill")
                        .foregroundColor(.coral)
                        .font(.system(size: 13))
                    Text(isJuniorMode
                         ? "Seleccionaste la línea \(selectedLine + 1)"
                         : "Línea \(selectedLine + 1) seleccionada")
                        .font(LoopFont.semiBold(13))
                        .foregroundColor(.coral)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            lines = exercise.codeTemplate?.components(separatedBy: "\n") ?? []
        }
    }
}

struct CodeLineView: View {
    let lineNumber: Int
    let code: String
    let isSelected: Bool
    let isJuniorMode: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Text("\(lineNumber)")
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundColor(.textMuted)
                    .frame(width: 36, alignment: .trailing)
                    .padding(.trailing, 16)

                Text(code)
                    .font(.system(
                        size: LoopLayout.fontSize(base: 14, junior: isJuniorMode),
                        weight: .regular,
                        design: .monospaced
                    ))
                    .foregroundColor(isSelected ? .coral : .textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    Image(systemName: "ladybug.fill")
                        .foregroundColor(.coral)
                        .font(.system(size: 14))
                        .padding(.trailing, 12)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.vertical, 10)
            .background(isSelected ? Color.coral.opacity(0.1) : Color.clear)
            .overlay(
                Rectangle()
                    .fill(Color.coral)
                    .frame(width: isSelected ? 3 : 0),
                alignment: .leading
            )
            .animation(LoopAnimation.springFast, value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
