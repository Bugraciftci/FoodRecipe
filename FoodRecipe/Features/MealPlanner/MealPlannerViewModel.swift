import Foundation
import Combine

struct DailyCalorieChartPoint: Identifiable, Sendable {
    var id: String { day.rawValue }
    let day: MealDayOfWeek
    let calories: Int
    let proteinGrams: Int
}

@MainActor
final class MealPlannerViewModel: ObservableObject {
    @Published var selectedDay: MealDayOfWeek = .monday
    @Published var isShowingShoppingList: Bool = false

    func weeklyChartData(kitchenStore: KitchenStore, catalog: [Recipe]) -> [DailyCalorieChartPoint] {
        MealDayOfWeek.allCases.map { day in
            let macros = kitchenStore.dailyMacros(for: day, catalog: catalog)
            return DailyCalorieChartPoint(day: day, calories: macros.calories, proteinGrams: macros.proteinGrams)
        }
    }

    func groupedShoppingItems(from items: [ShoppingListItem]) -> [(aisle: IngredientAisle, items: [ShoppingListItem])] {
        IngredientAisle.allCases.compactMap { aisle in
            let matches = items.filter { $0.aisle == aisle }
            return matches.isEmpty ? nil : (aisle, matches)
        }
    }
}
