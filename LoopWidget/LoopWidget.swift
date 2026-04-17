// LoopWidget.swift
//
// Widget pequeno/mediano con streak + XP diario.
//
// SETUP MANUAL EN XCODE (no se pudo auto-crear el target sin riesgo de romper el proyecto):
//
// 1. File > New > Target > Widget Extension. Nombre: "LoopWidget". Sin intent.
// 2. Borra los archivos placeholder que genere Xcode (LoopWidget.swift default, Provider, etc.).
// 3. Arrastra ESTE archivo y LoopWidgetProvider.swift al target "LoopWidget".
// 4. Crea un App Group: "group.com.loop.shared"
//    - En el target "loop" (app) > Signing & Capabilities > + Capability > App Groups > tilde "group.com.loop.shared".
//    - Haz lo mismo en el target "LoopWidget".
// 5. En loop/AppState.swift cambia `UserDefaults.standard` por el helper `LoopSharedDefaults.shared`
//    (ver LoopSharedDefaults.swift). Luego app y widget comparten los mismos datos.
// 6. En Shared/LoopWidgetSnapshot.swift esta el modelo que el widget lee.
//    La app lo debe escribir despues de cada cambio de progreso (hook en AppState.persistGameState()).

import SwiftUI
import WidgetKit

struct LoopWidgetEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let dailyXP: Int
    let targetXP: Int
    let userName: String

    static let placeholder = LoopWidgetEntry(
        date: Date(),
        streak: 0,
        dailyXP: 0,
        targetXP: 20,
        userName: "coder"
    )
}

struct LoopWidgetView: View {
    let entry: LoopWidgetEntry

    private let prussian = Color(red: 25/255, green: 29/255, blue: 50/255)
    private let gold = Color(red: 244/255, green: 185/255, blue: 66/255)
    private let periwinkle = Color(red: 173/255, green: 189/255, blue: 255/255)
    private let cerulean = Color(red: 28/255, green: 110/255, blue: 140/255)
    private let trackInactive = Color(red: 42/255, green: 47/255, blue: 80/255)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundColor(gold)
                    .font(.system(size: 14, weight: .bold))
                Text("\(entry.streak) dias")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(gold)
            }

            Text(entry.userName)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text("\(entry.dailyXP)/\(entry.targetXP) XP")
                    .font(.system(size: 11))
                    .foregroundColor(periwinkle)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(trackInactive)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(cerulean)
                            .frame(
                                width: geo.size.width * min(1, Double(entry.dailyXP) / Double(max(entry.targetXP, 1)))
                            )
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(14)
        .containerBackground(prussian, for: .widget)
    }
}

struct LoopWidget: Widget {
    let kind = "LoopWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LoopWidgetProvider()) { entry in
            LoopWidgetView(entry: entry)
        }
        .configurationDisplayName("Loop")
        .description("Tu racha y progreso diario.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
