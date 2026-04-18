import Foundation

struct LessonTheoryMapper {
    let courseLanguage: String
    let difficultyHint: String?

    init(courseLanguage: String, difficultyHint: String? = nil) {
        self.courseLanguage = courseLanguage
        self.difficultyHint = difficultyHint
    }

    func map(_ lesson: BackendLessonDTO) -> LessonUIModel {
        let theoryBlocks = lesson.sortedTheoryBlocks
        let difficulty = LessonDifficulty.resolve(from: lesson.difficulty ?? difficultyHint)
        let progressType = LessonProgressType.resolve(from: lesson.progressType)
        let topic = inferTopic(for: lesson, theoryBlocks: theoryBlocks)

        let stepBuilder = LessonStepBuilder(
            lesson: lesson,
            theoryBlocks: theoryBlocks,
            topic: topic,
            difficulty: difficulty,
            progressType: progressType,
            courseLanguage: courseLanguage
        )

        let steps = stepBuilder.build()

        return LessonUIModel(
            id: lesson.id,
            title: lesson.title,
            topic: topic,
            estimatedDuration: lesson.estimatedMinutes,
            difficulty: difficulty,
            progressType: progressType,
            orderIndex: lesson.orderIndex,
            xpReward: lesson.xpReward,
            steps: steps,
            source: LessonSourceMetadata(
                blockCount: lesson.blocks.count,
                theoryBlockCount: theoryBlocks.count,
                exerciseCount: lesson.exercises.count,
                usedSyntheticSteps: steps.contains { $0.metadata.isSynthetic },
                originalProgressType: lesson.progressType
            )
        )
    }

    private func inferTopic(for lesson: BackendLessonDTO, theoryBlocks: [BackendLessonBlockDTO]) -> String {
        if let topic = lesson.topic, !topic.isEmpty {
            return topic
        }

        if let firstBlockTitle = theoryBlocks.lazy.compactMap(\.title).first, !firstBlockTitle.isEmpty {
            return firstBlockTitle
        }

        let keywords = TextNormalizer.extractKeywords(from: lesson.title)
        if keywords.isEmpty {
            return lesson.title
        }

        return keywords.prefix(3).joined(separator: " · ")
    }
}

private struct LessonStepBuilder {
    let lesson: BackendLessonDTO
    let theoryBlocks: [BackendLessonBlockDTO]
    let topic: String
    let difficulty: LessonDifficulty
    let progressType: LessonProgressType
    let courseLanguage: String

    private let codeInferrer = CodeOutputInferrer()
    private let chunker = PedagogicalTextChunker()
    private let maxExamplesPerBlock = 2

    func build() -> [LessonStepUIModel] {
        var steps: [LessonStepUIModel] = []
        steps.append(makeIntroStep())

        var conceptSummaries: [String] = []
        var collectedKeyPoints: [String] = []

        if theoryBlocks.isEmpty {
            let fallbackSummary = "Hoy la idea principal va a aparecer mientras practicas. Te dejamos una guia breve para entrar ligero a los ejercicios."
            conceptSummaries.append("La practica va a introducir el concepto paso a paso.")
            steps.append(
                makeStep(
                    id: "\(lesson.id)-fallback-concept",
                    type: .concept,
                    title: "Idea principal",
                    subtitle: "Modo express",
                    content: LessonStepContent(
                        body: fallbackSummary,
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
                        footer: "Aun sin teoria larga, vas a entrar con contexto."
                    ),
                    visualSupport: visualSupport(for: .concept, index: 0),
                    interaction: quickConfirmInteraction(
                        prompt: "¿Listo para descubrirlo resolviendo?",
                        ctaLabel: "Seguir"
                    ),
                    reward: reward(xp: 6, badge: "Warm-up", icon: "sparkles"),
                    metadata: metadata(
                        block: nil,
                        orderIndex: 1,
                        estimatedSeconds: 25,
                        isSynthetic: true,
                        tags: ["fallback"]
                    )
                )
            )
        }

        for (blockIndex, block) in theoryBlocks.enumerated() {
            let blockSteps = buildSteps(for: block, blockIndex: blockIndex)
            steps.append(contentsOf: blockSteps)

            let blockSummaries = summarize(block: block)
            conceptSummaries.append(contentsOf: blockSummaries)
            collectedKeyPoints.append(contentsOf: block.keyPoints)
        }

        let takeaways = prioritizedTakeaways(
            summaries: conceptSummaries,
            keyPoints: collectedKeyPoints,
            fallback: [lesson.title, topic]
        )

        steps.append(makeSummaryStep(takeaways: takeaways))
        steps.append(makeCompletionStep(takeaways: takeaways))

        return steps
    }

    private func buildSteps(for block: BackendLessonBlockDTO, blockIndex: Int) -> [LessonStepUIModel] {
        var steps: [LessonStepUIModel] = []
        let blockTitle = sanitizedTitle(for: block, fallbackIndex: blockIndex + 1)
        let chunks = chunker.chunk(text: block.text)
        var hasInteraction = false

        if chunks.isEmpty, !block.hasRenderableContent {
            steps.append(
                makeStep(
                    id: "\(lesson.id)-block-\(blockIndex)-empty",
                    type: .concept,
                    title: blockTitle,
                    subtitle: "Contenido ligero",
                    content: LessonStepContent(
                        body: "Este bloque no trajo suficiente texto, asi que lo resumimos como una pista breve para no romper el flujo.",
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
                    ),
                    visualSupport: visualSupport(for: .concept, index: blockIndex),
                    interaction: nil,
                    reward: reward(xp: 4, badge: nil, icon: nil),
                    metadata: metadata(
                        block: block,
                        orderIndex: steps.count + 1,
                        estimatedSeconds: 20,
                        isSynthetic: true,
                        tags: ["empty_block"]
                    )
                )
            )
        }

        for (chunkIndex, chunk) in chunks.enumerated() {
            let stepType = stepType(for: chunk)
            let chunkTitle = chunks.count > 1 ? "\(blockTitle) · Parte \(chunkIndex + 1)" : blockTitle
            let shortDetail = chunk.detail.flatMap { detail in
                detail.count <= 120 ? detail : nil
            }
            let hiddenDetail = chunk.detail.flatMap { detail in
                detail.count > 120 ? detail : nil
            }

            steps.append(
                makeStep(
                    id: "\(lesson.id)-block-\(block.id)-chunk-\(chunkIndex)",
                    type: stepType,
                    title: chunkTitle,
                    subtitle: subtitle(for: stepType, chunkIndex: chunkIndex, totalChunks: chunks.count),
                    content: LessonStepContent(
                        body: chunk.summary,
                        detail: shortDetail,
                        bullets: [],
                        exampleTitle: nil,
                        codeSnippet: nil,
                        expectedOutput: nil,
                        outputTitle: nil,
                        explanation: nil,
                        revealText: hiddenDetail,
                        chips: [],
                        expandableText: hiddenDetail,
                        footer: shortDetail == nil && hiddenDetail == nil ? "Paso corto, idea clara." : nil
                    ),
                    visualSupport: visualSupport(for: stepType, index: blockIndex + chunkIndex),
                    interaction: nil,
                    reward: reward(xp: 5, badge: nil, icon: "lightbulb.fill"),
                    metadata: metadata(
                        block: block,
                        orderIndex: steps.count + 1,
                        estimatedSeconds: shortDetail == nil && hiddenDetail == nil ? 20 : 28,
                        isSynthetic: false,
                        tags: ["chunk", block.type.lowercased()],
                        chunkIndex: chunkIndex,
                        totalChunks: chunks.count
                    )
                )
            )

            if let hiddenDetail, !hiddenDetail.isEmpty {
                let revealType: StepType = hiddenDetail.count > 180 ? .revealCard : .tapToReveal
                steps.append(
                    makeStep(
                        id: "\(lesson.id)-block-\(block.id)-reveal-\(chunkIndex)",
                        type: revealType,
                        title: revealType == .revealCard ? "Desbloquea el detalle" : "Toca para descubrir",
                        subtitle: "Una capa mas",
                        content: LessonStepContent(
                            body: chunk.summary,
                            detail: nil,
                            bullets: [],
                            exampleTitle: nil,
                            codeSnippet: nil,
                            expectedOutput: nil,
                            outputTitle: nil,
                            explanation: nil,
                            revealText: hiddenDetail,
                            chips: [],
                            expandableText: hiddenDetail,
                            footer: "Primero la idea central, luego el matiz."
                        ),
                        visualSupport: visualSupport(for: revealType, index: blockIndex + chunkIndex),
                        interaction: InteractionModel(
                            kind: .tapToReveal,
                            prompt: "Revela lo que completa esta idea.",
                            helperText: "Asi evitamos bloques enormes y avanzas en micro-pasos.",
                            choices: [],
                            correctChoiceIDs: [],
                            allowMultipleSelection: false,
                            revealText: hiddenDetail,
                            ctaLabel: "Revelar",
                            feedback: nil
                        ),
                        reward: reward(xp: 4, badge: "Detalle", icon: "eye.fill"),
                        metadata: metadata(
                            block: block,
                            orderIndex: steps.count + 1,
                            estimatedSeconds: 18,
                            isSynthetic: true,
                            tags: ["reveal", block.type.lowercased()],
                            chunkIndex: chunkIndex,
                            totalChunks: chunks.count
                        )
                    )
                )
                hasInteraction = true
            }
        }

        if !block.keyPoints.isEmpty {
            let choices = block.keyPoints.enumerated().map { index, point in
                InteractionChoice(
                    id: "\(block.id)-key-\(index)",
                    title: point,
                    subtitle: nil,
                    matchKey: nil
                )
            }

            steps.append(
                makeStep(
                    id: "\(lesson.id)-block-\(block.id)-key-points",
                    type: .keyPoints,
                    title: "Puntos que conviene retener",
                    subtitle: "Marcarlos ayuda a fijarlos",
                    content: LessonStepContent(
                        body: "Convierte estas ideas en una mini checklist personal antes de seguir.",
                        detail: nil,
                        bullets: block.keyPoints,
                        exampleTitle: nil,
                        codeSnippet: nil,
                        expectedOutput: nil,
                        outputTitle: nil,
                        explanation: nil,
                        revealText: nil,
                        chips: block.keyPoints,
                        expandableText: nil,
                        footer: "Cada tap cuenta como una micro-confirmacion."
                    ),
                    visualSupport: visualSupport(for: .keyPoints, index: blockIndex),
                    interaction: InteractionModel(
                        kind: .checklist,
                        prompt: "Marca cada punto cuando sientas que lo ubicas.",
                        helperText: "No es un examen; es una pausa de retencion.",
                        choices: choices,
                        correctChoiceIDs: Set(choices.map(\.id)),
                        allowMultipleSelection: true,
                        revealText: nil,
                        ctaLabel: nil,
                        feedback: InteractionFeedback(
                            successTitle: "Checklist completa",
                            successMessage: "Ya fijaste lo esencial de este bloque.",
                            retryMessage: nil
                        )
                    ),
                    reward: reward(xp: 8, badge: "Key points", icon: "checkmark.circle.fill"),
                    metadata: metadata(
                        block: block,
                        orderIndex: steps.count + 1,
                        estimatedSeconds: 22,
                        isSynthetic: false,
                        tags: ["key_points", block.type.lowercased()]
                    )
                )
            )
            hasInteraction = true
        }

        let exampleSteps = buildExampleSteps(for: block, blockIndex: blockIndex, offset: steps.count)
        if !exampleSteps.isEmpty {
            hasInteraction = hasInteraction || exampleSteps.contains { $0.interaction != nil }
            steps.append(contentsOf: exampleSteps)
        }

        if !hasInteraction {
            let checkpointBody = summarize(block: block).first ?? "Haz una pausa rapida y confirma que la idea central ya te hizo click."
            steps.append(
                makeStep(
                    id: "\(lesson.id)-block-\(block.id)-checkpoint",
                    type: .checkpoint,
                    title: "Mini checkpoint",
                    subtitle: "Cierre corto de este concepto",
                    content: LessonStepContent(
                        body: checkpointBody,
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
                        footer: "La idea es avanzar con sensacion de progreso."
                    ),
                    visualSupport: visualSupport(for: .checkpoint, index: blockIndex),
                    interaction: quickConfirmInteraction(
                        prompt: "¿Te queda clara esta idea para pasar al siguiente paso?",
                        ctaLabel: "Si, seguir"
                    ),
                    reward: reward(xp: 6, badge: "Checkpoint", icon: "flag.fill"),
                    metadata: metadata(
                        block: block,
                        orderIndex: steps.count + 1,
                        estimatedSeconds: 14,
                        isSynthetic: true,
                        tags: ["checkpoint", block.type.lowercased()]
                    )
                )
            )
        }

        return steps
    }

    private func buildExampleSteps(for block: BackendLessonBlockDTO, blockIndex: Int, offset: Int) -> [LessonStepUIModel] {
        let language = block.language ?? courseLanguage
        let codeCandidates = exampleCodeCandidates(for: block)
        guard !codeCandidates.isEmpty else { return nonCodeExampleSteps(for: block, blockIndex: blockIndex, offset: offset) }

        var steps: [LessonStepUIModel] = []

        for (index, example) in codeCandidates.prefix(maxExamplesPerBlock).enumerated() {
            let explanation = nonCodeExampleSummary(for: block.examples)
            steps.append(
                makeStep(
                    id: "\(lesson.id)-block-\(block.id)-example-\(index)",
                    type: .exampleCode,
                    title: "Ejemplo guiado \(index + 1)",
                    subtitle: language.uppercased(),
                    content: LessonStepContent(
                        body: "Mira el snippet como una escena corta: primero observa, luego predice y despues confirma.",
                        detail: nil,
                        bullets: [],
                        exampleTitle: "Ejemplo \(index + 1)",
                        codeSnippet: example,
                        expectedOutput: nil,
                        outputTitle: nil,
                        explanation: explanation,
                        revealText: nil,
                        chips: [language.uppercased()],
                        expandableText: nil,
                        footer: "Busca el patron, no solo la sintaxis."
                    ),
                    visualSupport: visualSupport(for: .exampleCode, index: blockIndex + index),
                    interaction: nil,
                    reward: reward(xp: 7, badge: "Ejemplo", icon: "curlybraces"),
                    metadata: metadata(
                        block: block,
                        orderIndex: offset + steps.count + 1,
                        estimatedSeconds: 28,
                        isSynthetic: false,
                        tags: ["example_code", language.lowercased()],
                        language: language
                    )
                )
            )

            if let predictedOutput = codeInferrer.inferOutput(from: example) {
                let prediction = makePredictionInteraction(
                    output: predictedOutput,
                    stepSeed: "\(block.id)-\(index)"
                )

                steps.append(
                    makeStep(
                        id: "\(lesson.id)-block-\(block.id)-prediction-\(index)",
                        type: .codePrediction,
                        title: "Predice el resultado",
                        subtitle: "Antes de verlo, apuestale al output",
                        content: LessonStepContent(
                            body: "Leer codigo mejora mas cuando te detienes a anticipar lo que va a pasar.",
                            detail: nil,
                            bullets: [],
                            exampleTitle: "Output esperado",
                            codeSnippet: example,
                            expectedOutput: predictedOutput,
                            outputTitle: "Salida esperada",
                            explanation: explanation ?? "La clave esta en seguir la linea que produce salida.",
                            revealText: predictedOutput,
                            chips: [],
                            expandableText: nil,
                            footer: "Feedback inmediato para fijar la intuicion."
                        ),
                        visualSupport: visualSupport(for: .codePrediction, index: blockIndex + index),
                        interaction: prediction,
                        reward: reward(xp: 9, badge: "Prediccion", icon: "bolt.fill"),
                        metadata: metadata(
                            block: block,
                            orderIndex: offset + steps.count + 1,
                            estimatedSeconds: 24,
                            isSynthetic: true,
                            tags: ["code_prediction", language.lowercased()],
                            language: language
                        )
                    )
                )
            }
        }

        return steps
    }

    private func nonCodeExampleSteps(for block: BackendLessonBlockDTO, blockIndex: Int, offset: Int) -> [LessonStepUIModel] {
        let textExamples = block.examples
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !textExamples.isEmpty else { return [] }

        return textExamples.prefix(maxExamplesPerBlock).enumerated().map { index, example in
            makeStep(
                id: "\(lesson.id)-block-\(block.id)-text-example-\(index)",
                type: .tapToReveal,
                title: "Ejemplo rapido \(index + 1)",
                subtitle: "Caso concreto",
                content: LessonStepContent(
                    body: TextNormalizer.firstSentence(in: example) ?? example,
                    detail: nil,
                    bullets: [],
                    exampleTitle: "Caso \(index + 1)",
                    codeSnippet: nil,
                    expectedOutput: nil,
                    outputTitle: nil,
                    explanation: nil,
                    revealText: example,
                    chips: [],
                    expandableText: example,
                    footer: "Un ejemplo concreto suele retener mejor que un bloque abstracto."
                ),
                visualSupport: visualSupport(for: .tapToReveal, index: blockIndex + index),
                interaction: InteractionModel(
                    kind: .tapToReveal,
                    prompt: "Toca para desplegar el caso completo.",
                    helperText: nil,
                    choices: [],
                    correctChoiceIDs: [],
                    allowMultipleSelection: false,
                    revealText: example,
                    ctaLabel: "Ver ejemplo",
                    feedback: nil
                ),
                reward: reward(xp: 5, badge: "Ejemplo", icon: "sparkles"),
                metadata: metadata(
                    block: block,
                    orderIndex: offset + index + 1,
                    estimatedSeconds: 16,
                    isSynthetic: true,
                    tags: ["tap_example", block.type.lowercased()]
                )
            )
        }
    }

    private func makeIntroStep() -> LessonStepUIModel {
        let exerciseCount = lesson.exercises.count
        let theoryCount = max(theoryBlocks.count, 1)
        let stepEstimate = max(theoryCount * 2 + 2, 5)
        let promiseParts = [
            theoryBlocks.isEmpty ? nil : "\(theoryCount) ideas cortas",
            theoryBlocks.contains(where: { !$0.keyPoints.isEmpty }) ? "checkpoints ligeros" : nil,
            theoryBlocks.contains(where: { $0.codeSnippet != nil || !$0.examples.isEmpty }) ? "ejemplos guiados" : nil
        ].compactMap { $0 }
        let promiseLine = promiseParts.isEmpty ? "avanzar en pasos cortos" : promiseParts.joined(separator: " · ")
        let body = "Esta leccion deja de verse como un bloque largo: aqui avanzas con \(promiseLine) antes de pasar a \(exerciseCount) ejercicios."

        return makeStep(
            id: "\(lesson.id)-intro",
            type: .intro,
            title: lesson.title,
            subtitle: "\(topic) · \(stepEstimate) micro-pasos",
            content: LessonStepContent(
                body: body,
                detail: "Duracion estimada: \(lesson.estimatedMinutes) min. XP potencial: +\(lesson.xpReward).",
                bullets: [],
                exampleTitle: nil,
                codeSnippet: nil,
                expectedOutput: nil,
                outputTitle: nil,
                explanation: nil,
                revealText: nil,
                chips: [
                    "Leccion \(lesson.orderIndex)",
                    difficulty.badgeLabel,
                    "\(lesson.estimatedMinutes) min"
                ],
                expandableText: nil,
                footer: theoryBlocks.isEmpty ? "Hoy la practica lleva la delantera." : "Desliza o usa los botones para ir paso a paso."
            ),
            visualSupport: VisualSupport(
                animationType: .float,
                animationAssetName: nil,
                illustrationName: nil,
                iconName: "book.closed.fill",
                mascotMood: .speaking,
                emphasisStyle: .hero,
                backgroundVariant: .heroGlow
            ),
            interaction: nil,
            reward: reward(xp: 4, badge: "Inicio", icon: "sparkles"),
            metadata: metadata(
                block: nil,
                orderIndex: 0,
                estimatedSeconds: 20,
                isSynthetic: true,
                tags: ["intro"]
            )
        )
    }

    private func makeSummaryStep(takeaways: [String]) -> LessonStepUIModel {
        makeStep(
            id: "\(lesson.id)-summary",
            type: .summary,
            title: "Resumen express",
            subtitle: "Lo que conviene llevarte",
            content: LessonStepContent(
                body: "Antes de practicar, deja estas ideas bien visibles en tu cabeza.",
                detail: nil,
                bullets: takeaways,
                exampleTitle: nil,
                codeSnippet: nil,
                expectedOutput: nil,
                outputTitle: nil,
                explanation: nil,
                revealText: nil,
                chips: takeaways.prefix(3).map { $0 },
                expandableText: nil,
                footer: "Si recuerdas esto, los ejercicios entran con menos friccion."
            ),
            visualSupport: visualSupport(for: .summary, index: theoryBlocks.count + 1),
            interaction: quickConfirmInteraction(
                prompt: "¿Ya tienes claras las ideas que quieres probar?",
                ctaLabel: "Lo tengo"
            ),
            reward: reward(xp: 10, badge: "Resumen", icon: "checkmark.seal.fill"),
            metadata: metadata(
                block: nil,
                orderIndex: 9996,
                estimatedSeconds: 18,
                isSynthetic: true,
                tags: ["summary"]
            )
        )
    }

    private func makeCompletionStep(takeaways: [String]) -> LessonStepUIModel {
        let headline = takeaways.first ?? "Ya transformaste teoria pesada en pasos cortos."

        return makeStep(
            id: "\(lesson.id)-completion",
            type: .completion,
            title: "Listo para practicar",
            subtitle: "\(lesson.exercises.count) ejercicios te esperan",
            content: LessonStepContent(
                body: headline,
                detail: "Terminaste la parte teorica en formato microlearning. Lo siguiente es reforzarlo con accion y feedback inmediato.",
                bullets: [],
                exampleTitle: nil,
                codeSnippet: nil,
                expectedOutput: nil,
                outputTitle: nil,
                explanation: nil,
                revealText: nil,
                chips: [
                    "+\(lesson.xpReward) XP",
                    "\(lesson.exercises.count) ejercicios",
                    progressType.rawValue.capitalized
                ],
                expandableText: nil,
                footer: "La practica deberia sentirse como continuidad, no como cambio brusco."
            ),
            visualSupport: VisualSupport(
                animationType: .pulse,
                animationAssetName: nil,
                illustrationName: nil,
                iconName: "flag.checkered",
                mascotMood: .celebrating,
                emphasisStyle: .success,
                backgroundVariant: .reward
            ),
            interaction: nil,
            reward: reward(xp: lesson.xpReward, badge: "Completado", icon: "star.fill"),
            metadata: metadata(
                block: nil,
                orderIndex: 9997,
                estimatedSeconds: 14,
                isSynthetic: true,
                tags: ["completion"]
            )
        )
    }

    private func summarize(block: BackendLessonBlockDTO) -> [String] {
        var items = block.keyPoints
        if items.isEmpty {
            items = chunker.chunk(text: block.text).map(\.summary)
        }
        return items.map { TextNormalizer.trimmed($0) }.filter { !$0.isEmpty }
    }

    private func prioritizedTakeaways(summaries: [String], keyPoints: [String], fallback: [String]) -> [String] {
        let ordered = (keyPoints + summaries + fallback)
            .map { TextNormalizer.trimmed($0) }
            .filter { !$0.isEmpty }

        var seen = Set<String>()
        let unique = ordered.filter { item in
            let normalized = item.lowercased()
            guard !seen.contains(normalized) else { return false }
            seen.insert(normalized)
            return true
        }

        return Array(unique.prefix(4))
    }

    private func sanitizedTitle(for block: BackendLessonBlockDTO, fallbackIndex: Int) -> String {
        if let title = block.title, !title.isEmpty {
            return title
        }

        if let sentence = TextNormalizer.firstSentence(in: block.text), !sentence.isEmpty {
            return sentence.count > 42 ? "Concepto \(fallbackIndex)" : sentence
        }

        return "Concepto \(fallbackIndex)"
    }

    private func exampleCodeCandidates(for block: BackendLessonBlockDTO) -> [String] {
        var seen = Set<String>()
        var values: [String] = []

        let candidates = [block.codeSnippet] + block.examples

        for candidate in candidates {
            guard let candidate else { continue }
            let trimmed = TextNormalizer.trimmed(candidate)
            guard !trimmed.isEmpty else { continue }
            guard looksLikeCode(trimmed) else { continue }
            guard seen.insert(trimmed).inserted else { continue }
            values.append(trimmed)
        }

        return values
    }

    private func nonCodeExampleSummary(for examples: [String]) -> String? {
        examples
            .map { TextNormalizer.trimmed($0) }
            .first(where: { !$0.isEmpty && !looksLikeCode($0) })
    }

    private func stepType(for chunk: PedagogicalChunk) -> StepType {
        let lowered = chunk.summary.lowercased()
        if lowered.contains("imagina") || lowered.contains("piensalo como") || lowered.contains("es como") {
            return .analogy
        }
        return .concept
    }

    private func subtitle(for type: StepType, chunkIndex: Int, totalChunks: Int) -> String? {
        switch type {
        case .analogy:
            return "Una forma facil de visualizarlo"
        default:
            guard totalChunks > 1 else { return "Paso corto \(chunkIndex + 1)" }
            return "Bloque \(chunkIndex + 1) de \(totalChunks)"
        }
    }

    private func visualSupport(for stepType: StepType, index: Int) -> VisualSupport {
        let iconName: String
        let mood: MascotMood
        let emphasis: EmphasisStyle
        let background: BackgroundVariant

        switch stepType {
        case .intro:
            iconName = "book.closed.fill"
            mood = .speaking
            emphasis = .hero
            background = .heroGlow
        case .concept:
            iconName = "lightbulb.fill"
            mood = .focused
            emphasis = .standard
            background = .spotlight
        case .analogy:
            iconName = "wand.and.stars"
            mood = .thinking
            emphasis = .playful
            background = .spotlight
        case .keyPoints:
            iconName = "checkmark.circle.fill"
            mood = .focused
            emphasis = .highlight
            background = .defaultSurface
        case .revealCard, .tapToReveal:
            iconName = "eye.fill"
            mood = .thinking
            emphasis = .playful
            background = .quiet
        case .exampleCode:
            iconName = "curlybraces"
            mood = .focused
            emphasis = .challenge
            background = .codeLab
        case .codePrediction:
            iconName = "terminal.fill"
            mood = .thinking
            emphasis = .challenge
            background = .codeLab
        case .miniQuiz, .trueFalse, .checkpoint, .dragMatch:
            iconName = "bolt.fill"
            mood = .focused
            emphasis = .challenge
            background = .defaultSurface
        case .summary:
            iconName = "checkmark.seal.fill"
            mood = .speaking
            emphasis = .highlight
            background = .spotlight
        case .completion:
            iconName = "star.fill"
            mood = .celebrating
            emphasis = .success
            background = .reward
        }

        return VisualSupport(
            animationType: index.isMultiple(of: 3) ? .float : nil,
            animationAssetName: nil,
            illustrationName: nil,
            iconName: iconName,
            mascotMood: mood,
            emphasisStyle: emphasis,
            backgroundVariant: background
        )
    }

    private func reward(xp: Int, badge: String?, icon: String?) -> RewardModel? {
        guard xp > 0 || badge != nil || icon != nil else { return nil }
        return RewardModel(
            xp: xp,
            badgeText: badge,
            celebrationText: xp > 0 ? "+\(xp) XP de teoria" : nil,
            iconName: icon
        )
    }

    private func quickConfirmInteraction(prompt: String, ctaLabel: String) -> InteractionModel {
        InteractionModel(
            kind: .quickConfirm,
            prompt: prompt,
            helperText: nil,
            choices: [],
            correctChoiceIDs: [],
            allowMultipleSelection: false,
            revealText: nil,
            ctaLabel: ctaLabel,
            feedback: InteractionFeedback(
                successTitle: "Listo",
                successMessage: "Seguimos con el siguiente micro-paso.",
                retryMessage: nil
            )
        )
    }

    private func makePredictionInteraction(output: String, stepSeed: String) -> InteractionModel {
        let choices = CodePredictionChoiceFactory.makeChoices(for: output, seed: stepSeed)
        let correctChoiceIDs = Set(choices.filter { $0.title == output }.map(\.id))

        return InteractionModel(
            kind: .codePrediction,
            prompt: "¿Que salida produce este codigo?",
            helperText: "Elige una opcion y recibe feedback al instante.",
            choices: choices,
            correctChoiceIDs: correctChoiceIDs,
            allowMultipleSelection: false,
            revealText: output,
            ctaLabel: nil,
            feedback: InteractionFeedback(
                successTitle: "Bien leido",
                successMessage: "Tu prediccion coincide con el output esperado.",
                retryMessage: "Vuelve a mirar la linea que produce salida."
            )
        )
    }

    private func makeStep(
        id: String,
        type: StepType,
        title: String,
        subtitle: String?,
        content: LessonStepContent,
        visualSupport: VisualSupport?,
        interaction: InteractionModel?,
        reward: RewardModel?,
        metadata: LessonStepMetadata
    ) -> LessonStepUIModel {
        LessonStepUIModel(
            stepId: id,
            type: type,
            title: title,
            subtitle: subtitle,
            content: content,
            visualSupport: visualSupport,
            interaction: interaction,
            reward: reward,
            metadata: metadata
        )
    }

    private func metadata(
        block: BackendLessonBlockDTO?,
        orderIndex: Int,
        estimatedSeconds: Int,
        isSynthetic: Bool,
        tags: [String],
        language: String? = nil,
        chunkIndex: Int? = nil,
        totalChunks: Int? = nil
    ) -> LessonStepMetadata {
        LessonStepMetadata(
            sourceBlockID: block?.id,
            sourceType: block?.type,
            orderIndex: orderIndex,
            estimatedSeconds: estimatedSeconds,
            isSynthetic: isSynthetic,
            tags: tags,
            language: language ?? block?.language,
            chunkIndex: chunkIndex,
            totalChunks: totalChunks
        )
    }

    private func looksLikeCode(_ text: String) -> Bool {
        let codeMarkers: [String] = [
            "{", "}", "(", ")", "=", "==", ":", ";", "->", "def ", "class ",
            "import ", "return ", "print(", "let ", "var ", "const ", "func ",
            "console.log", "System.out", "fmt."
        ]
        return codeMarkers.contains(where: { text.contains($0) }) || text.contains("\n")
    }
}

private struct PedagogicalChunk: Hashable {
    let summary: String
    let detail: String?
}

private struct PedagogicalTextChunker {
    private let targetCharacters = 220
    private let hardLimit = 320
    private let maxChunks = 4

    func chunk(text: String) -> [PedagogicalChunk] {
        let normalized = TextNormalizer.normalizeParagraphs(in: text)
        guard !normalized.isEmpty else { return [] }

        let sentences = TextNormalizer.sentences(in: normalized)
        guard !sentences.isEmpty else {
            return [PedagogicalChunk(summary: normalized, detail: nil)]
        }

        var groups: [[String]] = []
        var current: [String] = []
        var currentLength = 0

        for sentence in sentences {
            let sentenceLength = sentence.count
            let shouldAppend = current.isEmpty ||
                currentLength + sentenceLength <= targetCharacters ||
                (currentLength < 120 && currentLength + sentenceLength <= hardLimit) ||
                TextNormalizer.shouldStayAttached(previous: current.last, next: sentence)

            if shouldAppend {
                current.append(sentence)
                currentLength += sentenceLength
            } else {
                groups.append(current)
                current = [sentence]
                currentLength = sentenceLength
            }
        }

        if !current.isEmpty {
            groups.append(current)
        }

        groups = compress(groups)

        return groups.compactMap { group in
            let text = group.joined(separator: " ")
            let summary = group.first ?? text
            let detail = group.dropFirst().joined(separator: " ")
            let trimmedSummary = TextNormalizer.trimmed(summary)
            guard !trimmedSummary.isEmpty else { return nil }
            let trimmedDetail = TextNormalizer.trimmed(detail)
            return PedagogicalChunk(
                summary: trimmedSummary,
                detail: trimmedDetail.isEmpty ? nil : trimmedDetail
            )
        }
    }

    private func compress(_ groups: [[String]]) -> [[String]] {
        guard groups.count > maxChunks else { return groups }

        var compressed = groups
        while compressed.count > maxChunks {
            let overflow = compressed.removeLast()
            compressed[compressed.count - 1].append(contentsOf: overflow)
        }
        return compressed
    }
}

private enum TextNormalizer {
    static func normalizeParagraphs(in text: String) -> String {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return lines.joined(separator: " ")
    }

    static func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func sentences(in text: String) -> [String] {
        let normalized = normalizeParagraphs(in: text)
        guard !normalized.isEmpty else { return [] }

        let pattern = #"(?<=[.!?])\s+"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: normalized.utf16.count)
        let matches = regex?.matches(in: normalized, range: range) ?? []

        guard !matches.isEmpty else { return [normalized] }

        var result: [String] = []
        var previousIndex = normalized.startIndex

        for match in matches {
            guard let range = Range(match.range, in: normalized) else { continue }
            let sentence = String(normalized[previousIndex..<range.lowerBound])
            let trimmedSentence = trimmed(sentence)
            if !trimmedSentence.isEmpty {
                result.append(trimmedSentence)
            }
            previousIndex = range.upperBound
        }

        let trailing = String(normalized[previousIndex...])
        let trimmedTrailing = trimmed(trailing)
        if !trimmedTrailing.isEmpty {
            result.append(trimmedTrailing)
        }

        return result
    }

    static func firstSentence(in text: String) -> String? {
        sentences(in: text).first
    }

    static func shouldStayAttached(previous: String?, next: String) -> Bool {
        guard let previous else { return false }
        let previousTrimmed = trimmed(previous)
        let nextTrimmed = trimmed(next)
        if previousTrimmed.hasSuffix(":") || previousTrimmed.lowercased().contains("por ejemplo") {
            return true
        }
        if previousTrimmed.count < 70 && nextTrimmed.count < 90 {
            return true
        }
        return false
    }

    static func extractKeywords(from text: String) -> [String] {
        trimmed(text)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .map { $0.lowercased() }
            .filter { $0.count >= 4 }
    }
}

private struct CodePredictionChoiceFactory {
    static func makeChoices(for output: String, seed: String) -> [InteractionChoice] {
        let normalized = output.trimmingCharacters(in: .whitespacesAndNewlines)
        let distractors = [
            "No imprime nada",
            normalized.hasPrefix("\"") ? String(normalized.dropFirst().dropLast()) : "\"\(normalized)\"",
            normalized.contains("\n") ? normalized.replacingOccurrences(of: "\n", with: " ") : "\(normalized)!",
            normalized.uppercased() == normalized ? normalized.lowercased() : normalized.uppercased()
        ]

        var uniqueValues: [String] = []
        for value in [normalized] + distractors {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            guard !uniqueValues.contains(trimmed) else { continue }
            uniqueValues.append(trimmed)
        }

        let options = Array(uniqueValues.prefix(3))
        let correctIndex = abs(seed.hashValue) % max(options.count, 1)

        var ordered = options.filter { $0 != normalized }
        let correctChoice = InteractionChoice(id: "\(seed)-correct", title: normalized, subtitle: nil, matchKey: nil)

        if ordered.count >= 2 {
            ordered.insert(normalized, at: min(correctIndex, ordered.count))
        } else {
            ordered.append(normalized)
        }

        return ordered.prefix(3).enumerated().map { index, value in
            InteractionChoice(
                id: value == normalized ? correctChoice.id : "\(seed)-option-\(index)",
                title: value,
                subtitle: nil,
                matchKey: nil
            )
        }
    }
}

private struct CodeOutputInferrer {
    func inferOutput(from code: String) -> String? {
        let lines = code
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else { return nil }

        let assignments = variableAssignments(from: lines)

        for line in lines.reversed() {
            guard let expression = printedExpression(in: line) else { continue }
            return resolve(expression: expression, assignments: assignments)
        }

        return nil
    }

    private func variableAssignments(from lines: [String]) -> [String: String] {
        var assignments: [String: String] = [:]

        for line in lines {
            let patterns = [
                #"^(?:let|var|const)\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$"#,
                #"^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$"#
            ]

            for pattern in patterns {
                guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
                let range = NSRange(location: 0, length: line.utf16.count)
                guard let match = regex.firstMatch(in: line, range: range),
                      let keyRange = Range(match.range(at: 1), in: line),
                      let valueRange = Range(match.range(at: 2), in: line) else {
                    continue
                }

                let key = String(line[keyRange])
                let value = String(line[valueRange]).trimmingCharacters(in: .whitespaces)
                assignments[key] = value
                break
            }
        }

        return assignments
    }

    private func printedExpression(in line: String) -> String? {
        let patterns = [
            #"print\((.+)\)"#,
            #"console\.log\((.+)\)"#,
            #"System\.out\.println\((.+)\)"#,
            #"fmt\.Println\((.+)\)"#
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(location: 0, length: line.utf16.count)
            guard let match = regex.firstMatch(in: line, range: range),
                  let valueRange = Range(match.range(at: 1), in: line) else {
                continue
            }
            return String(line[valueRange]).trimmingCharacters(in: .whitespaces)
        }

        return nil
    }

    private func resolve(expression: String, assignments: [String: String]) -> String? {
        let trimmed = expression.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let literal = resolveLiteral(trimmed) {
            return literal
        }

        if let variableValue = assignments[trimmed], let resolved = resolveLiteral(variableValue) {
            return resolved
        }

        let parts = trimmed.components(separatedBy: "+").map {
            $0.trimmingCharacters(in: .whitespaces)
        }

        if parts.count > 1 {
            let resolvedParts = parts.compactMap { part -> String? in
                if let literal = resolveLiteral(part) {
                    return literal
                }
                if let assignment = assignments[part] {
                    return resolveLiteral(assignment)
                }
                return nil
            }
            if resolvedParts.count == parts.count {
                return resolvedParts.joined()
            }
        }

        return nil
    }

    private func resolveLiteral(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if (trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"")) ||
            (trimmed.hasPrefix("'") && trimmed.hasSuffix("'")) {
            return String(trimmed.dropFirst().dropLast())
        }

        if ["true", "false", "True", "False"].contains(trimmed) {
            return trimmed
        }

        if Int(trimmed) != nil || Double(trimmed) != nil {
            return trimmed
        }

        return nil
    }
}
