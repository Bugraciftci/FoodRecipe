import XCTest

final class FoodRecipeTests: XCTestCase {

    func testDynamicPortionScalingDoublesIngredientsAndMacros() {
        let sample = LiveRecipeRepository.curatedChefCatalog[0] // defaultServings == 2
        let scaledForFour = sample.scaledIngredients(forServings: 4)
        let macrosForFour = sample.totalMacros(forServings: 4)

        XCTAssertEqual(sample.defaultServings, 2)
        XCTAssertEqual(scaledForFour.first?.scaledText, "640 g")
        XCTAssertEqual(macrosForFour.calories, sample.macrosPerServing.calories * 4)
        XCTAssertEqual(macrosForFour.proteinGrams, sample.macrosPerServing.proteinGrams * 4)
    }

    func testPantryMatchPercentageAndMissingIngredientsCalculation() {
        let menemen = LiveRecipeRepository.curatedChefCatalog[1] // 6 ingredients
        let pantry: Set<String> = [
            "Organic Eggs",
            "Ripe Vine Tomatoes",
            "Extra Virgin Olive Oil"
        ]

        let match = menemen.pantryMatchResult(availablePantryItems: pantry)
        XCTAssertEqual(match.matchedIngredients.count, 3)
        XCTAssertEqual(match.missingIngredients.count, 3)
        XCTAssertEqual(match.matchPercentage, 50)
        XCTAssertFalse(match.isReadyToCook)
    }

    @MainActor
    func testPantryMatcherViewModelRanksHighestMatchFirst() {
        let vm = PantryMatcherViewModel()
        vm.minimumMatchPercentage = 0

        let pantry: Set<String> = [
            "Sliced Roasted Turkey Breast",
            "Sourdough Bread",
            "Ripe Avocado",
            "Greek Yogurt Herb Spread",
            "Ripe Vine Tomatoes"
        ]

        let ranked = vm.rankedMatches(recipes: LiveRecipeRepository.curatedChefCatalog, pantryItems: pantry)
        XCTAssertFalse(ranked.isEmpty)
        XCTAssertEqual(ranked.first?.recipe.id, "qk-avocado-turkey-club")
        XCTAssertEqual(ranked.first?.matchPercentage, 100)
        XCTAssertTrue(ranked.first?.isReadyToCook == true)
    }

    @MainActor
    func testKitchenStoreWeeklyMacroAggregationAndShoppingDeduplication() {
        let suiteName = "FoodRecipeTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let store = KitchenStore(defaults: defaults)

        let salmon = LiveRecipeRepository.curatedChefCatalog[2]
        store.assignMeal(day: .friday, slot: .dinner, recipeId: salmon.id, servings: 2)

        let fridayMacros = store.dailyMacros(for: .friday, catalog: LiveRecipeRepository.curatedChefCatalog)
        XCTAssertEqual(fridayMacros.calories, salmon.macrosPerServing.calories * 2)
        XCTAssertEqual(fridayMacros.proteinGrams, salmon.macrosPerServing.proteinGrams * 2)

        let countBefore = store.shoppingList.count
        store.addIngredientsToShoppingList(salmon.ingredients, scaleFactor: 1.0, recipeTitle: salmon.title)
        XCTAssertGreaterThan(store.shoppingList.count, countBefore)
    }
}
