import SwiftUI
import Vortex

struct ConfettiLayer: View {
    var body: some View {
        VortexViewReader { proxy in
            VortexView(.confetti) {
                Rectangle()
                    .fill(Color.coral)
                    .frame(width: 16, height: 16)
                    .tag("square")
                Circle()
                    .fill(Color.amethyst)
                    .frame(width: 12, height: 12)
                    .tag("circle")
            }
            .onAppear {
                proxy.burst()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    proxy.burst()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    proxy.burst()
                }
            }
        }
    }
}
