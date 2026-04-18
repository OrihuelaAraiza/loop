import Foundation

enum LessonDifficulty: String, Codable, CaseIterable, Hashable {
    case starter
    case intermediate
    case advanced
    case adaptive

    static func resolve(from rawValue: String?) -> LessonDifficulty {
        guard let rawValue else { return .starter }

        switch rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "beginner", "easy", "starter", "basic":
            return .starter
        case "intermediate", "medium":
            return .intermediate
        case "advanced", "hard":
            return .advanced
        default:
            return .adaptive
        }
    }

    var badgeLabel: String {
        switch self {
        case .starter:
            return "Ligero"
        case .intermediate:
            return "En progreso"
        case .advanced:
            return "Profundo"
        case .adaptive:
            return "Adaptativo"
        }
    }
}

enum LessonProgressType: String, Codable, Hashable {
    case linear
    case checkpoint
    case mastery

    static func resolve(from rawValue: String?) -> LessonProgressType {
        guard let rawValue else { return .linear }

        switch rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "checkpoint", "checkpoints":
            return .checkpoint
        case "mastery", "mastery_path":
            return .mastery
        default:
            return .linear
        }
    }
}

enum StepType: String, Codable, CaseIterable, Hashable {
    case intro
    case concept
    case keyPoints = "key_points"
    case revealCard = "reveal_card"
    case analogy
    case exampleCode = "example_code"
    case codePrediction = "code_prediction"
    case miniQuiz = "mini_quiz"
    case trueFalse = "true_false"
    case tapToReveal = "tap_to_reveal"
    case dragMatch = "drag_match"
    case summary
    case checkpoint
    case completion
}

enum AnimationType: String, Codable, Hashable {
    case lottie
    case rive
    case pulse
    case shimmer
    case float
}

enum MascotMood: String, Codable, Hashable {
    case idle
    case speaking
    case thinking
    case celebrating
    case focused
}

enum EmphasisStyle: String, Codable, Hashable {
    case standard
    case hero
    case playful
    case highlight
    case success
    case challenge
}

enum BackgroundVariant: String, Codable, Hashable {
    case defaultSurface
    case heroGlow
    case spotlight
    case codeLab
    case reward
    case quiet
}

struct VisualSupport: Hashable {
    let animationType: AnimationType?
    let animationAssetName: String?
    let illustrationName: String?
    let iconName: String?
    let mascotMood: MascotMood?
    let emphasisStyle: EmphasisStyle?
    let backgroundVariant: BackgroundVariant?
}

enum InteractionKind: String, Codable, Hashable {
    case tapToReveal
    case checklist
    case multipleChoice
    case trueFalse
    case codePrediction
    case dragMatch
    case quickConfirm
}

struct InteractionChoice: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String?
    let matchKey: String?
}

struct InteractionFeedback: Hashable {
    let successTitle: String
    let successMessage: String
    let retryMessage: String?
}

struct InteractionModel: Hashable {
    let kind: InteractionKind
    let prompt: String
    let helperText: String?
    let choices: [InteractionChoice]
    let correctChoiceIDs: Set<String>
    let allowMultipleSelection: Bool
    let revealText: String?
    let ctaLabel: String?
    let feedback: InteractionFeedback?
}

struct RewardModel: Hashable {
    let xp: Int
    let badgeText: String?
    let celebrationText: String?
    let iconName: String?
}

struct LessonStepContent: Hashable {
    let body: String
    let detail: String?
    let bullets: [String]
    let exampleTitle: String?
    let codeSnippet: String?
    let expectedOutput: String?
    let outputTitle: String?
    let explanation: String?
    let revealText: String?
    let chips: [String]
    let expandableText: String?
    let footer: String?

    static let empty = LessonStepContent(
        body: "",
        detail: nil,
        bullets: [],
        exampleTitle: nil,
        codeSnippet: nil,
        expectedOutput: nil,
        outputTitle: nil,
        explanation: nil,
        revealText: nil,
        chips: [],
        expandableText: nil,
        footer: nil
    )
}

struct LessonStepMetadata: Hashable {
    let sourceBlockID: String?
    let sourceType: String?
    let orderIndex: Int
    let estimatedSeconds: Int
    let isSynthetic: Bool
    let tags: [String]
    let language: String?
    let chunkIndex: Int?
    let totalChunks: Int?
}

struct LessonStepUIModel: Identifiable, Hashable {
    let stepId: String
    let type: StepType
    let title: String
    let subtitle: String?
    let content: LessonStepContent
    let visualSupport: VisualSupport?
    let interaction: InteractionModel?
    let reward: RewardModel?
    let metadata: LessonStepMetadata

    var id: String { stepId }
}

struct LessonSourceMetadata: Hashable {
    let blockCount: Int
    let theoryBlockCount: Int
    let exerciseCount: Int
    let usedSyntheticSteps: Bool
    let originalProgressType: String?
}

struct LessonUIModel: Identifiable, Hashable {
    let id: String
    let title: String
    let topic: String
    let estimatedDuration: Int
    let difficulty: LessonDifficulty
    let progressType: LessonProgressType
    let orderIndex: Int
    let xpReward: Int
    let steps: [LessonStepUIModel]
    let source: LessonSourceMetadata
}
