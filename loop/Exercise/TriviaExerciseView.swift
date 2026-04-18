import Combine
import SwiftUI

struct TriviaExerciseView: View {
    let exercise: ExerciseResponse
    @Binding var userAnswer: String

    @Environment(\.isJuniorMode) private var isJuniorMode
    @State private var timeRemaining = 30
    @State private var timerActive = true
    @State private var selectedOption: String?
    @State private var timedOut = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            timerView

            if let options = exercise.options {
                VStack(spacing: 12) {
                    ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                        TriviaOptionButton(
                            option: option,
                            index: index,
                            isSelected: selectedOption == option,
                            isJuniorMode: isJuniorMode,
                            isDisabled: timedOut
                        ) {
                            guard !timedOut else { return }
                            withAnimation(LoopAnimation.springFast) {
                                selectedOption = option
                                userAnswer = option
                                timerActive = false
                            }
                            HapticManager.shared.selection()
                        }
                    }
                }
            }

            if timedOut {
                Text(isJuniorMode
                     ? "Se acabó el tiempo. Toca Verificar para ver la explicación."
                     : "Tiempo agotado. Toca Verificar para revisar la respuesta.")
                    .font(LoopFont.regular(13))
                    .foregroundColor(.textSecond)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onReceive(timer) { _ in
            guard timerActive && timeRemaining > 0 else { return }
            timeRemaining -= 1
            if timeRemaining == 0 {
                timerActive = false
                timedOut = true
                userAnswer = ExerciseAnswerSentinel.timedOut
                HapticManager.shared.error()
            }
        }
    }

    private var timerView: some View {
        HStack(spacing: 12) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.loopSurf2)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(timerColor)
                        .frame(width: geo.size.width * Double(timeRemaining) / 30.0)
                        .animation(.linear(duration: 1), value: timeRemaining)
                }
            }
            .frame(height: 6)

            Text("\(timeRemaining)s")
                .font(LoopFont.bold(14))
                .foregroundColor(timerColor)
                .monospacedDigit()
                .frame(width: 34)
        }
    }

    private var timerColor: Color {
        if timeRemaining > 20 { return .cerulean }
        if timeRemaining > 10 { return .loopGold }
        return .coral
    }
}

struct TriviaOptionButton: View {
    let option: String
    let index: Int
    let isSelected: Bool
    let isJuniorMode: Bool
    let isDisabled: Bool
    let action: () -> Void

    private let letters = ["A", "B", "C", "D"]

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(letters[safe: index] ?? "")
                    .font(LoopFont.bold(13))
                    .foregroundColor(isSelected ? .white : .periwinkle)
                    .frame(width: 28, height: 28)
                    .background(isSelected ? Color.coral : Color.loopSurf2)
                    .clipShape(Circle())

                Text(option)
                    .font(isSelected
                          ? LoopFont.bold(LoopLayout.fontSize(base: 15, junior: isJuniorMode))
                          : LoopFont.semiBold(LoopLayout.fontSize(base: 15, junior: isJuniorMode)))
                    .foregroundColor(isSelected ? .textPrimary : .periwinkle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.coral)
                        .font(.system(size: 18))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: LoopLayout.cornerRadius(junior: isJuniorMode))
                    .fill(isSelected ? Color.coral.opacity(0.12) : Color.loopSurf2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LoopLayout.cornerRadius(junior: isJuniorMode))
                    .stroke(isSelected ? Color.coral : Color.periwinkle.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .opacity(isDisabled && !isSelected ? 0.6 : 1)
        .animation(LoopAnimation.springFast, value: isSelected)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
