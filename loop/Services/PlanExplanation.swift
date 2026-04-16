//
//  PlanExplanation.swift
//  loop
//
//  Tres razones visibles para el plan (Human-Centered AI). MVP: texto determinista.
//

import Foundation

struct PlanExplanation: Equatable {
    let reasons: [String]

    /// Razones mostradas en el paso 7; en producción vendrían del motor de planificación.
    static func placeholder(for profile: UserLearningProfile) -> PlanExplanation {
        _ = profile
        return PlanExplanation(reasons: [
            "Tu tiempo disponible encaja con sesiones cortas para reducir fatiga cognitiva.",
            "Tu objetivo principal prioriza conceptos base antes de proyectos largos.",
            "Tu nivel declarado evita saltos que suelen generar frustración temprana."
        ])
    }
}
