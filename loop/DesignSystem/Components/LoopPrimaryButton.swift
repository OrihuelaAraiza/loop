import SwiftUI

struct LoopCTA: View {
    let title: String
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(LoopFont.bold(15))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.md)
                        .fill(Color.coral)
                    VStack {
                        LinearGradient(
                            colors: [.white.opacity(0.2), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        Spacer()
                    }
                }
            )
            .scaleEffect(isPressed ? 0.985 : 1)
            .shadow(color: Color.coral.opacity(0.35), radius: isPressed ? 8 : 16, y: isPressed ? 3 : 6)
            .shadow(color: Color.coral.opacity(0.18), radius: isPressed ? 10 : 22, y: 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isPressed)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .buttonStyle(.plain)
    }
}
