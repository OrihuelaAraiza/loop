//
//  UserLearningProfile.swift
//  loop
//
//  Perfil recolectado en onboarding (pasos 2–6). Paso 7 llenará el plan explicado.
//

import Foundation

struct UserLearningProfile: Equatable {
    var displayName: String = ""
    var avatarId: String = ""
    var ageRangeLabel: String = ""
    var primaryGoalId: String = ""
    var knowledgeLevel: String = ""
    var weeklyMinutes: Int = 0
    var practiceWeekdays: Set<Int> = [] // 1 = domingo ... 7 = sábado (ajustable luego)
}
