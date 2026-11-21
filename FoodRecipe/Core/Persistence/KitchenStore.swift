import Foundation
import Combine

@MainActor
final class KitchenStore: ObservableObject {
    @Published private(set) var favoriteRecipeIds: Set<String> = []
    @Published private(set) var pantryItems: Set<String> = []
    @Published private(set) var plannedMeals: [PlannedMealEntry] = []
    @Published private(set) var shoppingList: [ShoppingListItem] = []
    @Published var dailyCalorieTarget: Int = 2200
    @Published var dailyProteinTargetGrams: Int = 150

    private let defaults: UserDefaults
    private let favoritesKey = "foodrecipe.v2.favorites"
    private let pantryKey = "foodrecipe.v2.pantry"
    private let plannedMealsKey = "foodrecipe.v2.plannedMeals"
    private let shoppingListKey = "foodrecipe.v2.shoppingList"

    static let commonPantryStaples: [String] = [
        "Olive Oil", "Garlic Cloves", "Organic Eggs", "Ripe Vine Tomatoes",
        "Greek Yogurt", "Chicken Breast", "Wild Salmon Fillets", "Jasmine Rice",
        "Tagliatelle Pasta", "Broccoli Florets", "Avocado", "Lemon Juice",
        "Rolled Oats", "Baby Spinach", "Halloumi Cheese", "Cooked Chickpeas",
        "Sourdough Bread", "Low-Sodium Soy Sauce", "Honey"
    ]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadPersistedState()
    }

    // MARK: - Favorites

    func isFavorite(_ recipeId: String) -> Bool {
        favoriteRecipeIds.contains(recipeId)
    }

    func toggleFavorite(_ recipeId: String) {
        if favoriteRecipeIds.contains(recipeId) {
            favoriteRecipeIds.remove(recipeId)
        } else {
            favoriteRecipeIds.insert(recipeId)
        }
        saveCodable(Array(favoriteRecipeIds), forKey: favoritesKey)
    }

    // MARK: - Smart Pantry Inventory

    func hasPantryItem(_ item: String) -> Bool {
        pantryItems.contains(item)
    }

    func togglePantryItem(_ item: String) {
        let trimmed = item.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if pantryItems.contains(trimmed) {
            pantryItems.remove(trimmed)
        } else {
            pantryItems.insert(trimmed)
        }
        saveCodable(Array(pantryItems), forKey: pantryKey)
    }

    func addCustomPantryItem(_ item: String) {
        let trimmed = item.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        pantryItems.insert(trimmed)
        saveCodable(Array(pantryItems), forKey: pantryKey)
    }

    // MARK: - Shopping List Management

    func addIngredientsToShoppingList(_ ingredients: [IngredientMeasure], scaleFactor: Double = 1.0, recipeTitle: String? = nil) {
        for ing in ingredients {
            let formattedQty = ing.formattedAmount(scaleFactor: scaleFactor)
            if let existingIndex = shoppingList.firstIndex(where: { $0.name.caseInsensitiveCompare(ing.name) == .orderedSame && !$0.isChecked }) {
                shoppingList[existingIndex].quantityText = formattedQty
            } else {
                let newItem = ShoppingListItem(
                    name: ing.name,
                    quantityText: formattedQty,
                    aisle: ing.aisle,
                    isChecked: false,
                    sourceRecipeTitle: recipeTitle
                )
                shoppingList.insert(newItem, at: 0)
            }
        }
        saveCodable(shoppingList, forKey: shoppingListKey)
    }

    func toggleShoppingItem(_ id: UUID) {
        guard let idx = shoppingList.firstIndex(where: { $0.id == id }) else { return }
        shoppingList[idx].isChecked.toggle()
        saveCodable(shoppingList, forKey: shoppingListKey)
    }

    func removeShoppingItem(_ id: UUID) {
        shoppingList.removeAll { $0.id == id }
        saveCodable(shoppingList, forKey: shoppingListKey)
    }

    func clearCheckedShoppingItems() {
        shoppingList.removeAll { $0.isChecked }
        saveCodable(shoppingList, forKey: shoppingListKey)
    }

    // MARK: - Weekly Meal Planner

    func assignMeal(day: MealDayOfWeek, slot: MealTypeSlot, recipeId: String, servings: Int = 1) {
        plannedMeals.removeAll { $0.day == day && $0.slot == slot }
        plannedMeals.append(PlannedMealEntry(day: day, slot: slot, recipeId: recipeId, servings: servings))
        saveCodable(plannedMeals, forKey: plannedMealsKey)
    }

    func removePlannedMeal(id: UUID) {
        plannedMeals.removeAll { $0.id == id }
        saveCodable(plannedMeals, forKey: plannedMealsKey)
    }

    func meals(for day: MealDayOfWeek) -> [PlannedMealEntry] {
        plannedMeals.filter { $0.day == day }
    }

    func dailyMacros(for day: MealDayOfWeek, catalog: [Recipe]) -> MacroBreakdown {
        let recipeMap = Dictionary(uniqueKeysWithValues: catalog.map { ($0.id, $0) })
        return meals(for: day).reduce(MacroBreakdown.zero) { acc, entry in
            guard let recipe = recipeMap[entry.recipeId] else { return acc }
            return acc + recipe.totalMacros(forServings: entry.servings)
        }
    }

    // MARK: - Persistence Helpers

    private func loadPersistedState() {
        if let favs: [String] = loadCodable([String].self, forKey: favoritesKey) {
            favoriteRecipeIds = Set(favs)
        } else {
            favoriteRecipeIds = ["tr-ali-nazik-kebab", "med-grilled-salmon-quinoa"]
        }

        if let savedPantry: [String] = loadCodable([String].self, forKey: pantryKey) {
            pantryItems = Set(savedPantry)
        } else {
            pantryItems = [
                "Olive Oil", "Garlic Cloves", "Organic Eggs",
                "Ripe Vine Tomatoes", "Greek Yogurt", "Lemon Juice"
            ]
        }

        if let savedPlan: [PlannedMealEntry] = loadCodable([PlannedMealEntry].self, forKey: plannedMealsKey) {
            plannedMeals = savedPlan
        } else {
            plannedMeals = [
                PlannedMealEntry(day: .monday, slot: .breakfast, recipeId: "tr-menemen-skillet", servings: 1),
                PlannedMealEntry(day: .monday, slot: .lunch, recipeId: "qk-avocado-turkey-club", servings: 1),
                PlannedMealEntry(day: .monday, slot: .dinner, recipeId: "med-grilled-salmon-quinoa", servings: 1),
                PlannedMealEntry(day: .tuesday, slot: .breakfast, recipeId: "ds-protein-oat-berry-pancakes", servings: 1),
                PlannedMealEntry(day: .tuesday, slot: .dinner, recipeId: "tr-ali-nazik-kebab", servings: 1),
                PlannedMealEntry(day: .wednesday, slot: .lunch, recipeId: "med-chickpea-halloumi-salad", servings: 1),
                PlannedMealEntry(day: .wednesday, slot: .dinner, recipeId: "it-truffle-mushroom-tagliatelle", servings: 1)
            ]
        }

        if let savedShopping: [ShoppingListItem] = loadCodable([ShoppingListItem].self, forKey: shoppingListKey) {
            shoppingList = savedShopping
        } else {
            shoppingList = [
                ShoppingListItem(name: "Wild Salmon Fillets", quantityText: "360 g", aisle: .proteins, sourceRecipeTitle: "Aegean Herb-Crusted Salmon"),
                ShoppingListItem(name: "Avocado", quantityText: "2 whole", aisle: .produce, sourceRecipeTitle: "Aegean Herb-Crusted Salmon"),
                ShoppingListItem(name: "Aged Ezine Feta Cheese", quantityText: "120 g", aisle: .dairy, sourceRecipeTitle: "Artisan Turkish Menemen")
            ]
        }
    }

    private func saveCodable<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private func loadCodable<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
