import HighlightSwift
import SwiftUI

struct LessonStepRenderer: View {
    let step: LessonStepUIModel
    let stepIndex: Int
    let totalSteps: Int
    let tint: Color
    let state: LessonStepRenderState
    let onPrimaryAction: () -> Void
    let onSelectChoice: (String) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                LessonStepHeader(
                    step: step,
                    stepIndex: stepIndex,
                    totalSteps: totalSteps,
                    tint: tint
                )

                contentSection

                if let interaction = step.interaction {
                    interactionSection(interaction)
                }

                if let reward = step.reward {
                    LessonRewardStrip(reward: reward, tint: tint)
                }
            }
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xl)
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        switch step.type {
        case .intro:
            LessonNarrativeCard(
                title: "Como se va a sentir esta leccion",
                message: step.content.body,
                detail: step.content.detail,
                bullets: [],
                chips: step.content.chips,
                footer: step.content.footer,
                tint: tint,
                showsSceneAccent: true,
                mascotMood: step.visualSupport?.mascotMood
            )
        case .concept, .analogy:
            LessonNarrativeCard(
                title: step.type == .analogy ? "Piensalo asi" : "Idea principal",
                message: step.content.body,
                detail: step.content.detail,
                bullets: [],
                chips: step.content.chips,
                footer: step.content.footer,
                tint: tint,
                showsSceneAccent: false,
                mascotMood: step.visualSupport?.mascotMood
            )
        case .keyPoints:
            LessonNarrativeCard(
                title: "Reten lo esencial",
                message: step.content.body,
                detail: step.content.detail,
                bullets: step.content.bullets,
                chips: step.content.chips,
                footer: step.content.footer,
                tint: tint,
                showsSceneAccent: false,
                mascotMood: step.visualSupport?.mascotMood
            )
        case .revealCard, .tapToReveal:
            LessonNarrativeCard(
                title: "Primero la idea, luego el detalle",
                message: step.content.body,
                detail: step.content.detail,
                bullets: [],
                chips: [],
                footer: state.isRevealed ? nil : "Toca para desplegar la capa oculta.",
                tint: tint,
                showsSceneAccent: true,
                mascotMood: step.visualSupport?.mascotMood
            )
            LessonRevealPanel(
                revealedText: step.content.revealText ?? step.content.expandableText,
                isRevealed: state.isRevealed,
                tint: tint
            )
        case .exampleCode:
            LessonCodeSnippetCard(
                title: step.content.exampleTitle ?? "Ejemplo",
                prompt: step.content.body,
                code: step.content.codeSnippet,
                explanation: step.content.explanation,
                language: step.metadata.language ?? "python",
                tint: tint,
                footer: step.content.footer
            )
        case .codePrediction:
            LessonCodeSnippetCard(
                title: step.content.exampleTitle ?? "Prediccion",
                prompt: step.content.body,
                code: step.content.codeSnippet,
                explanation: step.content.explanation,
                language: step.metadata.language ?? "python",
                tint: tint,
                footer: step.content.footer
            )

            if state.isRevealed || state.evaluation != nil {
                LessonOutputCard(
                    title: step.content.outputTitle ?? "Salida",
                    output: step.content.expectedOutput,
                    explanation: step.content.explanation,
                    tint: state.evaluation?.isCorrect == false ? .loopGold : tint
                )
            }
        case .miniQuiz, .trueFalse:
            LessonNarrativeCard(
                title: "Mini quiz",
                message: step.content.body,
                detail: step.content.detail,
                bullets: [],
                chips: [],
                footer: step.content.footer,
                tint: tint,
                showsSceneAccent: false,
                mascotMood: .thinking
            )
        case .checkpoint:
            LessonNarrativeCard(
                title: "Pausa corta",
                message: step.content.body,
                detail: step.content.detail,
                bullets: [],
                chips: [],
                footer: step.content.footer,
                tint: tint,
                showsSceneAccent: true,
                mascotMood: step.visualSupport?.mascotMood
            )
        case .summary:
            LessonNarrativeCard(
                title: "Mapa mental",
                message: step.content.body,
                detail: step.content.detail,
                bullets: step.content.bullets,
                chips: step.content.chips,
                footer: step.content.footer,
                tint: tint,
                showsSceneAccent: true,
                mascotMood: step.visualSupport?.mascotMood
            )
        case .completion:
            LessonNarrativeCard(
                title: "Teoria completada",
                message: step.content.body,
                detail: step.content.detail,
                bullets: [],
                chips: step.content.chips,
                footer: step.content.footer,
                tint: tint,
                showsSceneAccent: true,
                mascotMood: step.visualSupport?.mascotMood
            )
        case .dragMatch:
            LessonDragMatchPlaceholder(
                message: step.content.body,
                tint: tint
            )
        }
    }

    @ViewBuilder
    private func interactionSection(_ interaction: InteractionModel) -> some View {
        switch interaction.kind {
        case .tapToReveal:
            LessonPrimaryActionCard(
                prompt: interaction.prompt,
                helperText: interaction.helperText,
                buttonTitle: state.isRevealed ? "Revisado" : (interaction.ctaLabel ?? "Revelar"),
                tint: tint,
                isDisabled: state.isRevealed,
                action: onPrimaryAction
            )
        case .quickConfirm:
            LessonPrimaryActionCard(
                prompt: interaction.prompt,
                helperText: interaction.helperText,
                buttonTitle: state.isCompleted ? "Confirmado" : (interaction.ctaLabel ?? "Seguir"),
                tint: tint,
                isDisabled: state.isCompleted,
                action: onPrimaryAction
            )
        case .checklist, .multipleChoice, .trueFalse, .codePrediction:
            LessonChoicesCard(
                prompt: interaction.prompt,
                helperText: interaction.helperText,
                choices: interaction.choices,
                selectedChoiceIDs: state.selectedChoiceIDs,
                tint: tint,
                allowsMultipleSelection: interaction.allowMultipleSelection,
                onSelectChoice: onSelectChoice
            )
        case .dragMatch:
            LessonPrimaryActionCard(
                prompt: interaction.prompt,
                helperText: interaction.helperText ?? "La estructura esta lista para conectar drag & match real mas adelante.",
                buttonTitle: interaction.ctaLabel ?? "Entendido",
                tint: tint,
                isDisabled: state.isCompleted,
                action: onPrimaryAction
            )
        }

        if let evaluation = state.evaluation {
            LessonFeedbackBanner(
                evaluation: evaluation,
                tint: evaluation.isCorrect ? tint : .loopGold
            )
        }
    }
}

private struct LessonStepHeader: View {
    let step: LessonStepUIModel
    let stepIndex: Int
    let totalSteps: Int
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.18))
                    .frame(width: 52, height: 52)

                if let icon = step.visualSupport?.iconName {
                    Image(systemName: icon)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(tint)
                } else {
                    Text("\(stepIndex + 1)")
                        .font(LoopFont.bold(16))
                        .foregroundColor(tint)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    headerPill(text: step.type.displayLabel.uppercased(), tint: tint)
                    headerPill(text: "\(stepIndex + 1)/\(totalSteps)", tint: .periwinkle)
                }

                Text(step.title)
                    .font(LoopFont.black(28))
                    .foregroundColor(.textPrimary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle = step.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(LoopFont.regular(15))
                        .foregroundColor(.textSecond)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func headerPill(text: String, tint: Color) -> some View {
        Text(text)
            .font(LoopFont.bold(11))
            .foregroundColor(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.14))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.22), lineWidth: 1))
    }
}

private struct LessonNarrativeCard: View {
    let title: String
    let message: String
    let detail: String?
    let bullets: [String]
    let chips: [String]
    let footer: String?
    let tint: Color
    let showsSceneAccent: Bool
    let mascotMood: MascotMood?

    var bodyView: some View {
        LoopCard(accentColor: tint, showsSceneAccent: showsSceneAccent, usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(alignment: .center, spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title.uppercased())
                            .font(LoopFont.bold(11))
                            .foregroundColor(tint)
                            .tracking(1.2)

                        Text(message)
                            .font(LoopFont.regular(17))
                            .foregroundColor(.textPrimary)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let mascotMood {
                        LoopyExpressionView(expression: mascotMood.expression, size: 72)
                            .frame(width: 72, height: 72)
                    }
                }

                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(LoopFont.regular(14))
                        .foregroundColor(.textSecond)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !bullets.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        ForEach(Array(bullets.enumerated()), id: \.offset) { index, item in
                            HStack(alignment: .top, spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(tint.opacity(0.16))
                                        .frame(width: 22, height: 22)
                                    Text("\(index + 1)")
                                        .font(LoopFont.bold(11))
                                        .foregroundColor(tint)
                                }
                                Text(item)
                                    .font(LoopFont.regular(14))
                                    .foregroundColor(.textPrimary)
                                    .lineSpacing(4)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }

                if !chips.isEmpty {
                    FlexibleChipCloud(values: chips, tint: tint)
                }

                if let footer, !footer.isEmpty {
                    Text(footer)
                        .font(LoopFont.bold(12))
                        .foregroundColor(.textMuted)
                }
            }
        }
    }

    var body: some View { bodyView }
}

private struct LessonRevealPanel: View {
    let revealedText: String?
    let isRevealed: Bool
    let tint: Color

    var body: some View {
        Group {
            if isRevealed, let revealedText, !revealedText.isEmpty {
                LoopCard(accentColor: tint.opacity(0.8), usesGlassSurface: true) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("CONTENIDO REVELADO")
                            .font(LoopFont.bold(10))
                            .foregroundColor(tint)
                            .tracking(1.2)

                        Text(revealedText)
                            .font(LoopFont.regular(15))
                            .foregroundColor(.textPrimary)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

private struct LessonCodeSnippetCard: View {
    let title: String
    let prompt: String
    let code: String?
    let explanation: String?
    let language: String
    let tint: Color
    let footer: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            LoopCard(accentColor: tint, usesGlassSurface: true) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack {
                        Text(title.uppercased())
                            .font(LoopFont.bold(11))
                            .foregroundColor(tint)
                            .tracking(1.2)
                        Spacer()
                        Text(language.uppercased())
                            .font(LoopFont.bold(10))
                            .foregroundColor(.textMuted)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.loopSurf2.opacity(0.8))
                            .clipShape(Capsule())
                    }

                    Text(prompt)
                        .font(LoopFont.regular(15))
                        .foregroundColor(.textSecond)
                        .fixedSize(horizontal: false, vertical: true)

                    if let code, !code.isEmpty {
                        CodeText(code)
                            .highlightLanguage(highlightLanguage(for: language))
                            .codeTextColors(.theme(.github))
                            .font(.system(size: 13, design: .monospaced))
                            .padding(.vertical, 6)
                    }

                    if let explanation, !explanation.isEmpty {
                        Text(explanation)
                            .font(LoopFont.regular(14))
                            .foregroundColor(.textPrimary)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let footer, !footer.isEmpty {
                        Text(footer)
                            .font(LoopFont.bold(12))
                            .foregroundColor(.textMuted)
                    }
                }
            }
        }
    }

    private func highlightLanguage(for language: String) -> HighlightLanguage {
        switch language.lowercased() {
        case "python":
            return .python
        case "swift":
            return .swift
        case "java":
            return .java
        default:
            return .python
        }
    }
}

private struct LessonOutputCard: View {
    let title: String
    let output: String?
    let explanation: String?
    let tint: Color

    var body: some View {
        LoopCard(accentColor: tint, usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(title.uppercased())
                    .font(LoopFont.bold(10))
                    .foregroundColor(tint)
                    .tracking(1.2)

                Text(output ?? "Sin salida inferida")
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundColor(.textPrimary)
                    .padding(.vertical, 4)

                if let explanation, !explanation.isEmpty {
                    Text(explanation)
                        .font(LoopFont.regular(13))
                        .foregroundColor(.textSecond)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct LessonChoicesCard: View {
    let prompt: String
    let helperText: String?
    let choices: [InteractionChoice]
    let selectedChoiceIDs: Set<String>
    let tint: Color
    let allowsMultipleSelection: Bool
    let onSelectChoice: (String) -> Void

    var body: some View {
        LoopCard(accentColor: tint, usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(prompt)
                    .font(LoopFont.bold(15))
                    .foregroundColor(.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if let helperText, !helperText.isEmpty {
                    Text(helperText)
                        .font(LoopFont.regular(13))
                        .foregroundColor(.textSecond)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: Spacing.sm) {
                    ForEach(choices) { choice in
                        LoopChip(
                            title: choice.title,
                            icon: icon(for: choice.id),
                            subtitle: choice.subtitle,
                            isSelected: selectedChoiceIDs.contains(choice.id),
                            tint: tint,
                            fullWidth: true
                        ) {
                            onSelectChoice(choice.id)
                        }
                    }
                }

                Text(allowsMultipleSelection ? "Puedes marcar varias." : "Toca una opcion para responder.")
                    .font(LoopFont.bold(12))
                    .foregroundColor(.textMuted)
            }
        }
    }

    private func icon(for id: String) -> String {
        if selectedChoiceIDs.contains(id) {
            return allowsMultipleSelection ? "checkmark.circle.fill" : "checkmark.circle"
        }
        return allowsMultipleSelection ? "circle" : "smallcircle.filled.circle"
    }
}

private struct LessonPrimaryActionCard: View {
    let prompt: String
    let helperText: String?
    let buttonTitle: String
    let tint: Color
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        LoopCard(accentColor: tint, usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(prompt)
                    .font(LoopFont.bold(15))
                    .foregroundColor(.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if let helperText, !helperText.isEmpty {
                    Text(helperText)
                        .font(LoopFont.regular(13))
                        .foregroundColor(.textSecond)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: action) {
                    HStack(spacing: 8) {
                        Text(buttonTitle)
                            .font(LoopFont.bold(14))
                        Image(systemName: isDisabled ? "checkmark" : "sparkles")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: isDisabled
                                ? [Color.loopSurf3, Color.loopSurf2]
                                : [tint, Color.coral],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                }
                .buttonStyle(.plain)
                .disabled(isDisabled)
                .opacity(isDisabled ? 0.65 : 1)
            }
        }
    }
}

private struct LessonFeedbackBanner: View {
    let evaluation: LessonInteractionEvaluation
    let tint: Color

    var body: some View {
        LoopCard(accentColor: tint, usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: evaluation.isCorrect ? "checkmark.seal.fill" : "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(tint)

                    Text(evaluation.title)
                        .font(LoopFont.bold(14))
                        .foregroundColor(.textPrimary)
                }

                Text(evaluation.message)
                    .font(LoopFont.regular(13))
                    .foregroundColor(.textSecond)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct LessonRewardStrip: View {
    let reward: RewardModel
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            if let iconName = reward.iconName {
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                if let badgeText = reward.badgeText, !badgeText.isEmpty {
                    Text(badgeText.uppercased())
                        .font(LoopFont.bold(10))
                        .foregroundColor(tint)
                        .tracking(1.1)
                }

                if let celebrationText = reward.celebrationText, !celebrationText.isEmpty {
                    Text(celebrationText)
                        .font(LoopFont.bold(13))
                        .foregroundColor(.textPrimary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 10)
        .background(tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct LessonDragMatchPlaceholder: View {
    let message: String
    let tint: Color

    var bodyView: some View {
        LoopCard(accentColor: tint, usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("DRAG & MATCH")
                    .font(LoopFont.bold(11))
                    .foregroundColor(tint)
                    .tracking(1.2)

                Text(message)
                    .font(LoopFont.regular(15))
                    .foregroundColor(.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("La arquitectura ya deja entrar emparejamiento, tarjetas y assets interactivos sin reescribir la pantalla.")
                    .font(LoopFont.regular(13))
                    .foregroundColor(.textSecond)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    var body: some View { bodyView }
}

private struct FlexibleChipCloud: View {
    let values: [String]
    let tint: Color

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 88), spacing: Spacing.sm, alignment: .leading)],
            alignment: .leading,
            spacing: Spacing.sm
        ) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                Text(value)
                    .font(LoopFont.bold(11))
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(tint.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(tint.opacity(0.18), lineWidth: 1))
            }
        }
    }
}

private extension StepType {
    var displayLabel: String {
        switch self {
        case .intro:
            return "Intro"
        case .concept:
            return "Concepto"
        case .keyPoints:
            return "Clave"
        case .revealCard:
            return "Reveal"
        case .analogy:
            return "Analogia"
        case .exampleCode:
            return "Codigo"
        case .codePrediction:
            return "Prediccion"
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

private extension MascotMood {
    var expression: LoopyExpression {
        switch self {
        case .idle:
            return .idle
        case .speaking:
            return .happy
        case .thinking:
            return .thinking
        case .celebrating:
            return .celebrating
        case .focused:
            return .excited
        }
    }
}
