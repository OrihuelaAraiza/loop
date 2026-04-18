import Combine
import SwiftUI
import RiveRuntime

enum LoopyRiveState: Hashable {
    case idle
    case speaking
    case celebrating
    case sad
    case thinking
    case focused
}

enum LoopyRiveVariant {
    case hero
    case compact

    // The current asset exposes a single artboard, so compact uses the same one
    // until the Rive file ships a dedicated small-format artboard.
    var artboardName: String? {
        switch self {
        case .hero:
            return LoopyRiveAsset.heroArtboardName
        case .compact:
            return LoopyRiveAsset.compactArtboardName ?? LoopyRiveAsset.heroArtboardName
        }
    }
}

private enum LoopyRiveAsset {
    static let fileName = "loop"
    static let fileExtension = ".riv"
    static let heroArtboardName = "Artboard"
    static let compactArtboardName: String? = nil

    static let idleAnimation = "Idle"
    static let speakingAnimation = "Hello"
    static let sadAnimation = "Ouch"

    static func animationName(for state: LoopyRiveState) -> String {
        switch state {
        case .idle:
            return idleAnimation
        case .speaking, .celebrating:
            return speakingAnimation
        case .sad:
            return sadAnimation
        case .thinking, .focused:
            return idleAnimation
        }
    }
}

extension LoopyMood {
    var riveState: LoopyRiveState {
        switch self {
        case .idle:
            return .idle
        case .speaking:
            return .speaking
        case .celebrating:
            return .celebrating
        case .sad:
            return .sad
        }
    }
}

extension LoopyExpression {
    var riveState: LoopyRiveState {
        switch self {
        case .idle:
            return .idle
        case .happy:
            return .speaking
        case .thinking:
            return .thinking
        case .sad:
            return .sad
        case .excited:
            return .focused
        case .celebrating:
            return .celebrating
        }
    }
}

@MainActor
private final class LoopyRiveController: ObservableObject {
    @Published private(set) var viewModel: RiveViewModel?
    @Published private(set) var usesFallback = false

    private let variant: LoopyRiveVariant
    private var activeAnimation: String?

    init(initialState: LoopyRiveState, variant: LoopyRiveVariant) {
        self.variant = variant
        buildViewModel(animationName: LoopyRiveAsset.animationName(for: initialState), reduceMotion: false)
    }

    func sync(state: LoopyRiveState, reduceMotion: Bool) {
        let requestedAnimation = LoopyRiveAsset.animationName(for: state)

        if viewModel == nil {
            buildViewModel(animationName: requestedAnimation, reduceMotion: reduceMotion)
            return
        }

        guard let viewModel else {
            usesFallback = true
            return
        }

        let resolvedAnimation: String
        if configure(animationName: requestedAnimation, on: viewModel) {
            resolvedAnimation = requestedAnimation
        } else if configure(animationName: LoopyRiveAsset.idleAnimation, on: viewModel) {
            resolvedAnimation = LoopyRiveAsset.idleAnimation
        } else {
            usesFallback = true
            return
        }

        if reduceMotion {
            viewModel.pause()
        } else {
            viewModel.play(animationName: resolvedAnimation)
        }
    }

    private func buildViewModel(animationName: String, reduceMotion: Bool) {
        do {
            let model = try RiveModel(
                fileName: LoopyRiveAsset.fileName,
                extension: LoopyRiveAsset.fileExtension,
                in: .main,
                loadCdn: false
            )

            let viewModel = RiveViewModel(
                model,
                animationName: animationName,
                fit: .contain,
                alignment: .center,
                autoPlay: !reduceMotion,
                artboardName: variant.artboardName
            )

            self.viewModel = viewModel
            self.activeAnimation = animationName
            self.usesFallback = false

            if reduceMotion {
                viewModel.pause()
            }
        } catch {
            usesFallback = true
        }
    }

    @discardableResult
    private func configure(animationName: String, on viewModel: RiveViewModel) -> Bool {
        guard activeAnimation != animationName else { return true }

        do {
            try viewModel.configureModel(
                artboardName: variant.artboardName,
                animationName: animationName
            )
            activeAnimation = animationName
            return true
        } catch {
            return false
        }
    }
}

struct LoopyRiveAvatar<Fallback: View>: View {
    let state: LoopyRiveState
    let variant: LoopyRiveVariant
    let fallback: Fallback

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var controller: LoopyRiveController

    init(
        state: LoopyRiveState,
        variant: LoopyRiveVariant,
        @ViewBuilder fallback: () -> Fallback
    ) {
        self.state = state
        self.variant = variant
        self.fallback = fallback()
        _controller = StateObject(
            wrappedValue: LoopyRiveController(initialState: state, variant: variant)
        )
    }

    var body: some View {
        Group {
            if controller.usesFallback || controller.viewModel == nil {
                fallback
            } else if let viewModel = controller.viewModel {
                viewModel.view()
            }
        }
        .onAppear {
            controller.sync(state: state, reduceMotion: reduceMotion)
        }
        .onChange(of: state) { _, newState in
            controller.sync(state: newState, reduceMotion: reduceMotion)
        }
        .onChange(of: reduceMotion) { _, newValue in
            controller.sync(state: state, reduceMotion: newValue)
        }
    }
}
