import SwiftUI
import Charts

struct MealPlannerView: View {
    let allRecipes: [Recipe]
    @ObservedObject var kitchenStore: KitchenStore
    @StateObject private var viewModel = MealPlannerViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    weeklyCalorieChartCard
                    daySelectorBar
                    dayMealsSection
                    smartShoppingListSection
                }
                .padding(16)
            }
            .background(CulinaryTheme.background.ignoresSafeArea())
            .navigationTitle("Macro Meal Planner")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var weeklyCalorieChartCard: some View {
        let chartPoints = viewModel.weeklyChartData(kitchenStore: kitchenStore, catalog: allRecipes)
        let todayMacros = kitchenStore.dailyMacros(for: viewModel.selectedDay, catalog: allRecipes)

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("WEEKLY MACRO & CALORIE TELEMETRY")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(CulinaryTheme.saffronAccent)
                    Text("\(viewModel.selectedDay.fullName): \(todayMacros.calories) / \(kitchenStore.dailyCalorieTarget) kcal")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(CulinaryTheme.textPrimary)
                }
                Spacer()
                Text("\(todayMacros.proteinGrams)g Protein")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(CulinaryTheme.proteinRose.opacity(0.2)))
                    .foregroundStyle(CulinaryTheme.proteinRose)
            }

            Chart(chartPoints) { point in
                BarMark(
                    x: .value("Day", point.day.rawValue),
                    y: .value("Calories", point.calories)
                )
                .foregroundStyle(
                    point.day == viewModel.selectedDay
                        ? CulinaryTheme.saffronAccent
                        : CulinaryTheme.herbEmerald.opacity(0.65)
                )
                .cornerRadius(6)

                RuleMark(y: .value("Target", kitchenStore.dailyCalorieTarget))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Color.white.opacity(0.35))
            }
            .frame(height: 150)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(CulinaryTheme.cardBackground)
        )
    }

    private var daySelectorBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MealDayOfWeek.allCases) { day in
                    let isSelected = viewModel.selectedDay == day
                    Button {
                        viewModel.selectedDay = day
                    } label: {
                        Text(day.rawValue)
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                Capsule()
                                    .fill(isSelected ? CulinaryTheme.saffronAccent : CulinaryTheme.cardBackground)
                            )
                            .foregroundStyle(isSelected ? Color.black : CulinaryTheme.textPrimary)
                    }
                }
            }
        }
    }

    private var dayMealsSection: some View {
        let entries = kitchenStore.meals(for: viewModel.selectedDay)
        let recipeMap = Dictionary(uniqueKeysWithValues: allRecipes.map { ($0.id, $0) })

        return VStack(alignment: .leading, spacing: 12) {
            Text("\(viewModel.selectedDay.fullName) Schedule")
                .font(.headline.weight(.bold))
                .foregroundStyle(CulinaryTheme.textPrimary)

            ForEach(MealTypeSlot.allCases) { slot in
                let slotEntry = entries.first { $0.slot == slot }
                let assignedRecipe = slotEntry.flatMap { recipeMap[$0.recipeId] }

                HStack(spacing: 12) {
                    Image(systemName: slot.symbolName)
                        .font(.title3)
                        .foregroundStyle(CulinaryTheme.saffronAccent)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(slot.rawValue.uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(CulinaryTheme.textSecondary)

                        if let recipe = assignedRecipe {
                            Text(recipe.title)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(CulinaryTheme.textPrimary)
                            Text("\(recipe.macrosPerServing.calories) kcal · \(recipe.macrosPerServing.proteinGrams)g P")
                                .font(.caption2)
                                .foregroundStyle(CulinaryTheme.herbEmerald)
                        } else {
                            Text("No meal scheduled")
                                .font(.caption)
                                .foregroundStyle(CulinaryTheme.textSecondary)
                        }
                    }

                    Spacer()

                    if let entry = slotEntry {
                        Button {
                            kitchenStore.removePlannedMeal(id: entry.id)
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(CulinaryTheme.proteinRose)
                        }
                    } else if let defaultRecipe = allRecipes.first {
                        Button {
                            kitchenStore.assignMeal(day: viewModel.selectedDay, slot: slot, recipeId: defaultRecipe.id, servings: 1)
                        } label: {
                            Label("Assign", systemImage: "plus.circle.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(CulinaryTheme.saffronAccent)
                        }
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(CulinaryTheme.cardBackground)
                )
            }
        }
    }

    private var smartShoppingListSection: some View {
        let grouped = viewModel.groupedShoppingItems(from: kitchenStore.shoppingList)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Smart Aisle Shopping List (\(kitchenStore.shoppingList.count))", systemImage: "cart.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(CulinaryTheme.textPrimary)
                Spacer()
                if kitchenStore.shoppingList.contains(where: \.isChecked) {
                    Button("Clear Checked") {
                        kitchenStore.clearCheckedShoppingItems()
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(CulinaryTheme.saffronAccent)
                }
            }

            if grouped.isEmpty {
                Text("Your shopping list is empty. Add missing ingredients from any recipe detail page.")
                    .font(.caption)
                    .foregroundStyle(CulinaryTheme.textSecondary)
                    .padding(14)
            } else {
                ForEach(grouped, id: \.aisle.id) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Label(section.aisle.rawValue, systemImage: section.aisle.symbolName)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(CulinaryTheme.saffronAccent)

                        ForEach(section.items) { item in
                            Button {
                                kitchenStore.toggleShoppingItem(item.id)
                            } label: {
                                HStack {
                                    Image(systemName: item.isChecked ? "checkmark.square.fill" : "square")
                                        .foregroundStyle(item.isChecked ? CulinaryTheme.herbEmerald : CulinaryTheme.textSecondary)
                                    Text(item.name)
                                        .font(.subheadline)
                                        .strikethrough(item.isChecked)
                                        .foregroundStyle(item.isChecked ? CulinaryTheme.textSecondary : CulinaryTheme.textPrimary)
                                    Spacer()
                                    Text(item.quantityText)
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(CulinaryTheme.saffronAccent)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(CulinaryTheme.cardBackground)
                    )
                }
            }
        }
    }
}
