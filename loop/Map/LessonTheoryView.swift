import HighlightSwift
import SwiftUI

struct LessonTheoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    let lesson: LessonPayload
    let onStartPractice: () -> Void
    var onClose: (() -> Void)?

    @State private var currentPage: Int = 0
    @State private var revealContent: Bool = false

    private var theoryBlocks: [LessonBlockPayload] {
        lesson.blocks
            .filter { $0.type == "theory" || $0.type == "intro" || $0.type == "example" }
            .sorted { $0.orderIndex < $1.orderIndex }
    }

    private var totalPages: Int {
        max(theoryBlocks.count + 1, 1)
    }

    private var isLastPage: Bool {
        currentPage == totalPages - 1
    }

    private var courseLanguage: String {
        appState.currentCourse?.language ?? "Python"
    }

    var body: some View {
        ZStack {
            AmbientBackground(topColor: .amethyst, bottomColor: .cerulean)

            VStack(spacing: Spacing.md) {
                topBar
                progressHeader

                TabView(selection: $currentPage) {
                    introPage
                        .tag(0)
                        .padding(.horizontal, Spacing.lg)

                    ForEach(Array(theoryBlocks.enumerated()), id: \.element.id) { index, block in
                        theoryPage(block: block, pageIndex: index + 1)
                            .tag(index + 1)
                            .padding(.horizontal, Spacing.lg)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: currentPage)

                bottomNav
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.md)
            }
            .padding(.top, Spacing.lg)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                revealContent = true
            }
        }
        .onChange(of: currentPage) { _, _ in
            HapticManager.shared.selection()
        }
    }

    // MARK: - Header

    private var topBar: some View {
        HStack {
            Button {
                HapticManager.shared.impact(.light)
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
            .accessibilityLabel("Cerrar teoría")

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.periwinkle)
                Text("Teoría · \(currentPage + 1)/\(totalPages)")
                    .font(LoopFont.bold(12))
                    .foregroundColor(.textSecond)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 7)
            .background(Color.loopSurf2.opacity(0.88))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.borderSoft, lineWidth: 1))
        }
        .padding(.horizontal, Spacing.lg)
    }

    private var progressHeader: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< totalPages, id: \.self) { index in
                Capsule()
                    .fill(
                        index == currentPage
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color.coral, Color.amethyst],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            : AnyShapeStyle(
                                index < currentPage ? Color.coral.opacity(0.6) : Color.trackInactive
                            )
                    )
                    .frame(height: 6)
                    .frame(maxWidth: index == currentPage ? .infinity : 36)
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: currentPage)
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Intro Page

    private var introPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                lessonHero

                if theoryBlocks.isEmpty {
                    emptyTheoryCard
                } else {
                    agendaCard
                }

                swipeHint
            }
            .padding(.bottom, Spacing.xl)
        }
        .opacity(revealContent ? 1 : 0)
        .offset(y: revealContent ? 0 : 20)
    }

    private var lessonHero: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                heroPill(icon: "number", text: "Lección \(lesson.orderIndex)", color: .periwinkle)
                heroPill(icon: "clock.fill", text: "\(lesson.estimatedMinutes) min", color: .cerulean)
                heroPill(icon: "bolt.fill", text: "+\(lesson.xpReward) XP", color: .loopGold)
            }

            Text(lesson.title)
                .font(LoopFont.black(32))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.textPrimary, Color.periwinkle],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Text(introSummary)
                .font(LoopFont.regular(16))
                .foregroundColor(.textSecond)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, Spacing.sm)
    }

    private var introSummary: String {
        if theoryBlocks.isEmpty {
            return "Vamos a saltar directo a la práctica con ejercicios personalizados para este tema."
        }

        let count = theoryBlocks.count
        let pluralized = count == 1 ? "concepto" : "conceptos"
        return "Antes de practicar, vamos a revisar \(count) \(pluralized) clave. Deslízate página por página y al final encontrarás ejercicios para reforzar todo."
    }

    private var agendaCard: some View {
        LoopCard(accentColor: .periwinkle, showsSceneAccent: true, usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Text("Agenda")
                        .font(LoopFont.bold(13))
                        .foregroundColor(.periwinkle)
                        .textCase(.uppercase)
                        .tracking(1.1)
                    Spacer()
                    Text("\(theoryBlocks.count) pasos")
                        .font(LoopFont.bold(12))
                        .foregroundColor(.textSecond)
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(Array(theoryBlocks.enumerated()), id: \.element.id) { index, block in
                        agendaRow(index: index + 1, block: block)
                    }
                }
            }
        }
    }

    private func agendaRow(index: Int, block: LessonBlockPayload) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(blockTint(for: index - 1).opacity(0.18))
                    .frame(width: 30, height: 30)
                Text("\(index)")
                    .font(LoopFont.bold(12))
                    .foregroundColor(blockTint(for: index - 1))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(block.title?.isEmpty == false ? block.title! : "Concepto \(index)")
                    .font(LoopFont.bold(14))
                    .foregroundColor(.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if !block.text.isEmpty {
                    Text(block.text)
                        .font(LoopFont.regular(12))
                        .foregroundColor(.textSecond)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            HapticManager.shared.selection()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                currentPage = index
            }
        }
    }

    private var emptyTheoryCard: some View {
        LoopCard(accentColor: .mint, usesGlassSurface: true) {
            HStack(alignment: .top, spacing: Spacing.md) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.mint)
                    .frame(width: 40, height: 40)
                    .background(Color.mint.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sin teoría extra")
                        .font(LoopFont.bold(15))
                        .foregroundColor(.textPrimary)
                    Text("Esta lección se enfoca 100% en práctica. Toca continuar para empezar a resolver ejercicios.")
                        .font(LoopFont.regular(13))
                        .foregroundColor(.textSecond)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var swipeHint: some View {
        HStack(spacing: 6) {
            Image(systemName: "hand.draw.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.textMuted)
            Text(theoryBlocks.isEmpty ? "Toca 'Ir a ejercicios' para continuar" : "Deslízate para avanzar")
                .font(LoopFont.regular(12))
                .foregroundColor(.textMuted)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 8)
        .background(Color.loopSurf1.opacity(0.6))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.borderSoft, lineWidth: 1))
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Theory Pages

    private func theoryPage(block: LessonBlockPayload, pageIndex: Int) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                blockHero(block: block, pageIndex: pageIndex)

                if let snippet = block.codeSnippet, !snippet.isEmpty {
                    codeSnippetSection(snippet: snippet, language: block.language ?? courseLanguage)
                }

                blockBody(block: block, pageIndex: pageIndex)

                if !block.keyPoints.isEmpty {
                    keyPointsSection(points: block.keyPoints, tint: blockTint(for: pageIndex - 1))
                }

                if !block.examples.isEmpty {
                    examplesSection(block: block, pageIndex: pageIndex)
                }
            }
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xl)
        }
        .id(pageIndex)
    }

    private func blockHero(block: LessonBlockPayload, pageIndex: Int) -> some View {
        let tint = blockTint(for: pageIndex - 1)
        let icon = blockIcon(for: pageIndex - 1)

        return VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(tint)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("CONCEPTO \(pageIndex) · \(theoryBlocks.count)")
                        .font(LoopFont.bold(11))
                        .foregroundColor(tint)
                        .tracking(1.1)
                    Text(block.title?.isEmpty == false ? block.title! : "Concepto \(pageIndex)")
                        .font(LoopFont.black(26))
                        .foregroundColor(.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2)
                }
            }
        }
    }

    private func blockBody(block: LessonBlockPayload, pageIndex: Int) -> some View {
        let paragraphs = block.text
            .components(separatedBy: CharacterSet.newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return LoopCard(accentColor: blockTint(for: pageIndex - 1), usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                if paragraphs.isEmpty {
                    Text("Contenido en preparacion...")
                        .font(LoopFont.regular(15))
                        .foregroundColor(.textSecond)
                } else {
                    ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                        Text(paragraph)
                            .font(LoopFont.regular(16))
                            .foregroundColor(.textPrimary)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private func examplesSection(block: LessonBlockPayload, pageIndex: Int) -> some View {
        let tint = blockTint(for: pageIndex - 1)

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(
                icon: "curlybraces",
                title: "Ejemplos",
                tint: tint
            )

            VStack(spacing: Spacing.sm) {
                ForEach(Array(block.examples.enumerated()), id: \.offset) { index, example in
                    exampleCard(text: example, index: index + 1, tint: tint, language: block.language ?? courseLanguage)
                }
            }
        }
    }

    private func exampleCard(text: String, index: Int, tint: Color, language: String) -> some View {
        LoopCard(accentColor: tint.opacity(0.7), usesGlassSurface: true) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("EJEMPLO \(index)")
                        .font(LoopFont.bold(10))
                        .foregroundColor(tint)
                        .tracking(1.2)
                    Spacer()
                    Text(language.uppercased())
                        .font(LoopFont.bold(10))
                        .foregroundColor(.textMuted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.loopSurf2.opacity(0.8))
                        .clipShape(Capsule())
                }

                if looksLikeCode(text) {
                    CodeText(text)
                        .highlightLanguage(highlightLanguage(for: language))
                        .codeTextColors(.theme(.github))
                        .font(.system(size: 13, design: .monospaced))
                        .padding(.vertical, 4)
                } else {
                    Text(text)
                        .font(LoopFont.regular(15))
                        .foregroundColor(.textPrimary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func codeSnippetSection(snippet: String, language: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(icon: "terminal.fill", title: "Codigo", tint: .amethyst)

            LoopCard(accentColor: .amethyst, usesGlassSurface: true) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(language.uppercased())
                        .font(LoopFont.bold(10))
                        .foregroundColor(.amethyst)
                        .tracking(1.2)
                    CodeText(snippet)
                        .highlightLanguage(highlightLanguage(for: language))
                        .codeTextColors(.theme(.github))
                        .font(.system(size: 13, design: .monospaced))
                }
            }
        }
    }

    private func keyPointsSection(points: [String], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionHeader(icon: "sparkles", title: "Puntos clave", tint: .loopGold)

            LoopCard(accentColor: .loopGold, usesGlassSurface: true) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                        HStack(alignment: .top, spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(tint.opacity(0.2))
                                    .frame(width: 22, height: 22)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(tint)
                            }
                            .padding(.top, 2)

                            Text(point)
                                .font(LoopFont.regular(14))
                                .foregroundColor(.textPrimary)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer(minLength: 0)
                        }
                        if index < points.count - 1 {
                            Divider().overlay(Color.borderSoft)
                        }
                    }
                }
            }
        }
    }

    private func sectionHeader(icon: String, title: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(tint)
            Text(title.uppercased())
                .font(LoopFont.bold(12))
                .foregroundColor(tint)
                .tracking(1.2)
        }
    }

    // MARK: - Bottom Navigation

    private var bottomNav: some View {
        HStack(spacing: Spacing.md) {
            Button {
                HapticManager.shared.impact(.light)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    currentPage = max(currentPage - 1, 0)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 13, weight: .bold))
                    Text("Anterior")
                        .font(LoopFont.bold(14))
                }
                .foregroundColor(currentPage == 0 ? .textMuted : .textPrimary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.loopSurf2.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(Color.borderMid, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(currentPage == 0)
            .opacity(currentPage == 0 ? 0.55 : 1)

            Button {
                HapticManager.shared.impact(.medium)
                if isLastPage {
                    onStartPractice()
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        currentPage = min(currentPage + 1, totalPages - 1)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(isLastPage ? "Ir a ejercicios" : "Siguiente")
                        .font(LoopFont.bold(15))
                    Image(systemName: isLastPage ? "sparkles" : "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: isLastPage
                            ? [Color.coral, Color.amethyst]
                            : [Color.periwinkle, Color.cerulean],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                .shadow(color: (isLastPage ? Color.coral : Color.cerulean).opacity(0.35), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private func heroPill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(LoopFont.bold(12))
        }
        .foregroundColor(color)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 7)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.28), lineWidth: 1))
    }

    private func blockTint(for index: Int) -> Color {
        let palette: [Color] = [.coral, .periwinkle, .mint, .amethyst, .cerulean, .loopGold]
        return palette[abs(index) % palette.count]
    }

    private func blockIcon(for index: Int) -> String {
        let icons = [
            "lightbulb.fill",
            "book.closed.fill",
            "sparkles",
            "bolt.fill",
            "flame.fill",
            "star.fill"
        ]
        return icons[abs(index) % icons.count]
    }

    private func looksLikeCode(_ text: String) -> Bool {
        let codeMarkers: [Character] = ["{", "}", "(", ")", "=", ";", "<", ">"]
        let hasMarker = text.contains(where: { codeMarkers.contains($0) })
        let hasMultipleLines = text.contains("\n")
        let hasKeyword = ["def ", "class ", "import ", "function ", "var ", "let ", "const ", "print(", "return "]
            .contains(where: { text.contains($0) })
        return hasMarker || hasMultipleLines || hasKeyword
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
