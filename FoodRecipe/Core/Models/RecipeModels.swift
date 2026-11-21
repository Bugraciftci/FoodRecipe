import Foundation

// MARK: - Cuisine & Dietary Taxonomy

enum CuisineCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case all = "All"
    case turkish = "Turkish"
    case mediterranean = "Mediterranean"
    case italian = "Italian"
    case asian = "Asian"
    case highProtein = "High-Protein"
    case quickMeals = "Quick (<20m)"
    case dessert = "Desserts"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .all: return "fork.knife"
        case .turkish: return "flame.fill"
        case .mediterranean: return "leaf.fill"
        case .italian: return "wineglass.fill"
        case .asian: return "takeoutbag.and.cup.and.straw.fill"
        case .highProtein: return "bolt.heart.fill"
        case .quickMeals: return "timer"
        case .dessert: return "birthday.cake.fill"
        }
    }
}

enum DietaryTag: String, CaseIterable, Codable, Identifiable, Sendable {
    case highProtein = "High Protein"
    case lowCarb = "Low Carb"
    case vegetarian = "Vegetarian"
    case glutenFree = "Gluten-Free"
    case quick20Min = "Under 20 Min"
    case mealPrep = "Meal Prep"

    var id: String { rawValue }
}

enum IngredientAisle: String, CaseIterable, Codable, Identifiable, Sendable {
    case produce = "Fresh Produce"
    case proteins = "Meat, Poultry & Seafood"
    case dairy = "Dairy & Eggs"
    case grainsAndPasta = "Grains, Pasta & Bakery"
    case spicesAndOils = "Spices, Herbs & Oils"
    case pantry = "Pantry Essentials"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .produce: return "carrot.fill"
        case .proteins: return "fish.fill"
        case .dairy: return "cup.and.saucer.fill"
        case .grainsAndPasta: return "basket.fill"
        case .spicesAndOils: return "drop.fill"
        case .pantry: return "shippingbox.fill"
        }
    }
}

// MARK: - Ingredient & Macro Models

struct IngredientMeasure: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let baseAmount: Double
    let unit: String
    let aisle: IngredientAisle

    var normalizedKey: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    func formattedAmount(scaleFactor: Double = 1.0) -> String {
        let value = baseAmount * max(scaleFactor, 0.25)
        if value == 0 {
            return unit
        }
        let rounded = (value * 10).rounded() / 10
        let numberString: String
        if rounded.truncatingRemainder(dividingBy: 1) == 0 {
            numberString = String(Int(rounded))
        } else {
            numberString = String(format: "%.1f", rounded)
        }
        return unit.isEmpty ? numberString : "\(numberString) \(unit)"
    }
}

struct MacroBreakdown: Codable, Hashable, Sendable {
    let calories: Int
    let proteinGrams: Int
    let carbsGrams: Int
    let fatGrams: Int

    func scaled(by factor: Double) -> MacroBreakdown {
        let safeFactor = max(factor, 0.25)
        return MacroBreakdown(
            calories: Int((Double(calories) * safeFactor).rounded()),
            proteinGrams: Int((Double(proteinGrams) * safeFactor).rounded()),
            carbsGrams: Int((Double(carbsGrams) * safeFactor).rounded()),
            fatGrams: Int((Double(fatGrams) * safeFactor).rounded())
        )
    }

    var totalMacroGrams: Int {
        max(proteinGrams + carbsGrams + fatGrams, 1)
    }

    var proteinPercentage: Double {
        Double(proteinGrams) / Double(totalMacroGrams)
    }

    var carbsPercentage: Double {
        Double(carbsGrams) / Double(totalMacroGrams)
    }

    var fatPercentage: Double {
        Double(fatGrams) / Double(totalMacroGrams)
    }

    static let zero = MacroBreakdown(calories: 0, proteinGrams: 0, carbsGrams: 0, fatGrams: 0)

    static func + (lhs: MacroBreakdown, rhs: MacroBreakdown) -> MacroBreakdown {
        MacroBreakdown(
            calories: lhs.calories + rhs.calories,
            proteinGrams: lhs.proteinGrams + rhs.proteinGrams,
            carbsGrams: lhs.carbsGrams + rhs.carbsGrams,
            fatGrams: lhs.fatGrams + rhs.fatGrams
        )
    }
}

// MARK: - Cooking Step

struct CookingStep: Identifiable, Codable, Hashable, Sendable {
    var id: Int { stepNumber }
    let stepNumber: Int
    let title: String
    let instruction: String
    let durationSeconds: Int?
    let chefTip: String?

    var formattedDuration: String? {
        guard let seconds = durationSeconds, seconds > 0 else { return nil }
        let mins = seconds / 60
        let rem = seconds % 60
        if mins > 0 && rem > 0 {
            return "\(mins)m \(rem)s"
        } else if mins > 0 {
            return "\(mins) min"
        } else {
            return "\(seconds) sec"
        }
    }
}

// MARK: - Core Recipe Entity

struct Recipe: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let cuisine: CuisineCategory
    let prepMinutes: Int
    let cookMinutes: Int
    let defaultServings: Int
    let difficulty: String
    let imageURL: String
    let localAssetName: String?
    let macrosPerServing: MacroBreakdown
    let dietaryTags: [DietaryTag]
    let ingredients: [IngredientMeasure]
    let steps: [CookingStep]

    var totalMinutes: Int {
        prepMinutes + cookMinutes
    }

    func scaleFactor(forServings targetServings: Int) -> Double {
        guard defaultServings > 0 else { return 1.0 }
        return Double(max(targetServings, 1)) / Double(defaultServings)
    }

    func scaledIngredients(forServings targetServings: Int) -> [(ingredient: IngredientMeasure, scaledText: String)] {
        let factor = scaleFactor(forServings: targetServings)
        return ingredients.map { item in
            (item, item.formattedAmount(scaleFactor: factor))
        }
    }

    func totalMacros(forServings targetServings: Int) -> MacroBreakdown {
        macrosPerServing.scaled(by: Double(max(targetServings, 1)))
    }

    func pantryMatchResult(availablePantryItems: Set<String>) -> PantryMatchResult {
        let normalizedPantry = Set(availablePantryItems.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
        var matched: [String] = []
        var missing: [IngredientMeasure] = []

        for ingredient in ingredients {
            let key = ingredient.normalizedKey
            let isMatched = normalizedPantry.contains { pantryItem in
                !pantryItem.isEmpty && (key.contains(pantryItem) || pantryItem.contains(key))
            }
            if isMatched {
                matched.append(ingredient.name)
            } else {
                missing.append(ingredient)
            }
        }

        let total = max(ingredients.count, 1)
        let pct = Int(((Double(matched.count) / Double(total)) * 100.0).rounded())

        return PantryMatchResult(
            recipe: self,
            matchedIngredients: matched,
            missingIngredients: missing,
            matchPercentage: min(max(pct, 0), 100)
        )
    }
}

struct PantryMatchResult: Identifiable, Hashable, Sendable {
    var id: String { recipe.id }
    let recipe: Recipe
    let matchedIngredients: [String]
    let missingIngredients: [IngredientMeasure]
    let matchPercentage: Int

    var isReadyToCook: Bool {
        missingIngredients.isEmpty
    }
}

// MARK: - Meal Planner & Shopping List Models

enum MealDayOfWeek: String, CaseIterable, Codable, Identifiable, Sendable {
    case monday = "Mon"
    case tuesday = "Tue"
    case wednesday = "Wed"
    case thursday = "Thu"
    case friday = "Fri"
    case saturday = "Sat"
    case sunday = "Sun"

    var id: String { rawValue }

    var fullName: String {
        switch self {
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        case .sunday: return "Sunday"
        }
    }
}

enum MealTypeSlot: String, CaseIterable, Codable, Identifiable, Sendable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "leaf.circle.fill"
        }
    }
}

struct PlannedMealEntry: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let day: MealDayOfWeek
    let slot: MealTypeSlot
    let recipeId: String
    var servings: Int

    init(id: UUID = UUID(), day: MealDayOfWeek, slot: MealTypeSlot, recipeId: String, servings: Int = 1) {
        self.id = id
        self.day = day
        self.slot = slot
        self.recipeId = recipeId
        self.servings = servings
    }
}

struct ShoppingListItem: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var quantityText: String
    var aisle: IngredientAisle
    var isChecked: Bool
    var sourceRecipeTitle: String?

    init(
        id: UUID = UUID(),
        name: String,
        quantityText: String,
        aisle: IngredientAisle = .pantry,
        isChecked: Bool = false,
        sourceRecipeTitle: String? = nil
    ) {
        self.id = id
        self.name = name
        self.quantityText = quantityText
        self.aisle = aisle
        self.isChecked = isChecked
        self.sourceRecipeTitle = sourceRecipeTitle
    }
}
