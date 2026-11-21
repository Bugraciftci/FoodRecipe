import SwiftUI

struct MacroRingBadge: View {
    let macros: MacroBreakdown

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(CulinaryTheme.elevatedSurface, lineWidth: 8)
                    .frame(width: 64, height: 64)

                Circle()
                    .trim(from: 0, to: CGFloat(macros.proteinPercentage))
                    .stroke(CulinaryTheme.proteinRose, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 64, height: 64)

                VStack(spacing: 0) {
                    Text("\(macros.calories)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(CulinaryTheme.textPrimary)
                    Text("kcal")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(CulinaryTheme.textSecondary)
                }
            }

            HStack(spacing: 12) {
                macroColumn(label: "Protein", grams: macros.proteinGrams, color: CulinaryTheme.proteinRose)
                macroColumn(label: "Carbs", grams: macros.carbsGrams, color: CulinaryTheme.carbAmber)
                macroColumn(label: "Fat", grams: macros.fatGrams, color: CulinaryTheme.fatCyan)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(CulinaryTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }

    private func macroColumn(label: String, grams: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 7, height: 7)
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(CulinaryTheme.textSecondary)
            }
            Text("\(grams)g")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(CulinaryTheme.textPrimary)
        }
    }
}
