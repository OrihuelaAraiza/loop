import Foundation
import Combine

struct MapConcept: Identifiable {
    let id = UUID()
    let title: String
    let state: MapNode.NodeState
}

final class MapViewModel: ObservableObject {
    @Published var concepts: [MapConcept] = [
        .init(title: "Variables", state: .done),
        .init(title: "Condicionales", state: .done),
        .init(title: "Bucles", state: .current),
        .init(title: "Funciones", state: .next),
        .init(title: "Listas", state: .locked),
    ]
}
