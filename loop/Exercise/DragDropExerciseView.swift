import SwiftUI

struct DragDropExerciseView: View {
    let exercise: ExerciseResponse
    @Binding var userAnswer: String

    @Environment(\.isJuniorMode) private var isJuniorMode
    @State private var availableTokens: [CodeToken] = []
    @State private var placedTokens: [CodeToken] = []

    var body: some View {
        VStack(spacing: 24) {
            dropZone

            HStack {
                Rectangle()
                    .fill(Color.borderSoft)
                    .frame(height: 1)
                Text(isJuniorMode ? "Tokens disponibles" : "Arrastra desde aquí")
                    .font(LoopFont.regular(12))
                    .foregroundColor(.textMuted)
                    .fixedSize()
                Rectangle()
                    .fill(Color.borderSoft)
                    .frame(height: 1)
            }

            tokenBag
        }
        .onAppear(perform: setupTokens)
        .onChange(of: placedTokens) { _, _ in
            updateAnswer()
        }
    }

    private var dropZone: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isJuniorMode ? "Ordena el código aquí:" : "Tu solución")
                .font(LoopFont.semiBold(13))
                .foregroundColor(.periwinkle)

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.loopSurf2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(placedTokens.isEmpty ? Color.borderSoft : Color.coral.opacity(0.4), lineWidth: 1)
                    )

                if placedTokens.isEmpty {
                    Text(isJuniorMode ? "Arrastra las piezas aquí" : "Arrastra los tokens aquí")
                        .font(LoopFont.regular(14))
                        .foregroundColor(.textMuted)
                        .padding()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(placedTokens) { token in
                            PlacedTokenView(token: token, isJuniorMode: isJuniorMode) {
                                withAnimation(LoopAnimation.springFast) {
                                    removeFromPlaced(token)
                                }
                                HapticManager.shared.impact(.light)
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(minHeight: 120)
            .dropDestination(for: String.self) { items, _ in
                guard let id = items.first else { return false }
                handleDrop(id: id)
                return true
            }
        }
    }

    private var tokenBag: some View {
        FlowLayout(spacing: 8) {
            ForEach(availableTokens) { token in
                DraggableTokenView(token: token, isJuniorMode: isJuniorMode)
                    .draggable(token.id)
                    .onTapGesture {
                        withAnimation(LoopAnimation.springFast) {
                            moveToPlaced(token)
                        }
                        HapticManager.shared.impact(.light)
                    }
            }
        }
    }

    private func setupTokens() {
        guard availableTokens.isEmpty, placedTokens.isEmpty else { return }
        let options = exercise.options ?? []
        availableTokens = options.map { CodeToken(text: $0) }.shuffled()
    }

    private func handleDrop(id: String) {
        guard let token = availableTokens.first(where: { $0.id == id }) ?? placedTokens.first(where: { $0.id == id }) else {
            return
        }

        withAnimation(LoopAnimation.springFast) {
            moveToPlaced(token)
        }
        HapticManager.shared.impact(.medium)
    }

    private func moveToPlaced(_ token: CodeToken) {
        availableTokens.removeAll { $0.id == token.id }
        if !placedTokens.contains(where: { $0.id == token.id }) {
            placedTokens.append(token)
        }
    }

    private func removeFromPlaced(_ token: CodeToken) {
        placedTokens.removeAll { $0.id == token.id }
        availableTokens.append(token)
    }

    private func updateAnswer() {
        userAnswer = placedTokens.map(\.text).joined(separator: "|")
    }
}

struct CodeToken: Identifiable, Hashable {
    let id: String
    let text: String

    init(id: String = UUID().uuidString, text: String) {
        self.id = id
        self.text = text
    }
}

struct DraggableTokenView: View {
    let token: CodeToken
    let isJuniorMode: Bool

    var body: some View {
        Text(token.text)
            .font(.system(
                size: LoopLayout.fontSize(base: 14, junior: isJuniorMode),
                weight: .medium,
                design: .monospaced
            ))
            .foregroundColor(.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.cerulean.opacity(0.22))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.cerulean, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PlacedTokenView: View {
    let token: CodeToken
    let isJuniorMode: Bool
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(token.text)
                .font(.system(
                    size: LoopLayout.fontSize(base: 14, junior: isJuniorMode),
                    weight: .medium,
                    design: .monospaced
                ))
                .foregroundColor(.textPrimary)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.periwinkle)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.coral.opacity(0.18))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.coral.opacity(0.5), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .transition(.scale.combined(with: .opacity))
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { row in
            row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
        }.reduce(0) { $0 + $1 + spacing }
        return CGSize(width: proposal.width ?? 0, height: max(0, height - spacing))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: ProposedViewSize(bounds.size), subviews: subviews)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0

            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }

            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var currentRowWidth: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentRowWidth + size.width + spacing > maxWidth && !(rows.last?.isEmpty ?? true) {
                rows.append([])
                currentRowWidth = 0
            }

            rows[rows.count - 1].append(subview)
            currentRowWidth += size.width + spacing
        }

        return rows
    }
}
