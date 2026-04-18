import Foundation
import Testing
@testable import loop

@MainActor
struct LessonTheoryMapperTests {
    @Test func mapsFlatBackendLessonIntoMicrolearningSteps() throws {
        let json = """
        {
          "id": "lesson-1",
          "title": "Variables en Python",
          "difficulty": "beginner",
          "order_index": 3,
          "estimated_minutes": 8,
          "xp_reward": 25,
          "blocks": [
            {
              "id": "block-1",
              "type": "theory",
              "title": "Que es una variable",
              "order_index": 1,
              "content": {
                "text": "Una variable guarda un valor para reutilizarlo mas tarde. Piensa en ella como una etiqueta pegada a una caja. Si cambias lo que hay dentro, la etiqueta sigue apuntando a ese valor.",
                "key_points": [
                  "Guarda datos para usarlos despues.",
                  "Tiene un nombre que facilita leer el codigo."
                ],
                "examples": [
                  "nombre = \\"Ana\\"\\nprint(nombre)"
                ],
                "language": "python"
              }
            }
          ],
          "exercises": []
        }
        """

        let data = try #require(json.data(using: .utf8))
        let dto = try JSONDecoder().decode(BackendLessonDTO.self, from: data)
        let model = LessonTheoryMapper(courseLanguage: "Python").map(dto)

        #expect(model.title == "Variables en Python")
        #expect(model.difficulty == .starter)
        #expect(model.steps.first?.type == .intro)
        #expect(model.steps.contains { $0.type == .concept })
        #expect(model.steps.contains { $0.type == .keyPoints })
        #expect(model.steps.contains { $0.type == .exampleCode })
        #expect(model.steps.contains { $0.type == .codePrediction })
        #expect(model.steps.contains { $0.type == .summary })
        #expect(model.steps.last?.type == .completion)

        let predictionStep = try #require(model.steps.first { $0.type == .codePrediction })
        #expect(predictionStep.content.expectedOutput == "Ana")
    }
}
