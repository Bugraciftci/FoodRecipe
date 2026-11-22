import XCTest
@testable import FoodRecipe

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

    @MainActor
    func testCookingSessionStepAdvanceAndTimerReset() {
        let recipe = LiveRecipeRepository.curatedChefCatalog[0]
        let vm = CookingSessionViewModel(recipe: recipe, servings: 2)

        XCTAssertEqual(vm.currentStepIndex, 0)
        XCTAssertEqual(vm.remainingSeconds, recipe.steps[0].durationSeconds)
        XCTAssertEqual(vm.formattedRemainingTime, "08:00")

        vm.completeCurrentStepAndAdvance()
        XCTAssertEqual(vm.currentStepIndex, 1)
        XCTAssertTrue(vm.completedStepNumbers.contains(recipe.steps[0].stepNumber))
        XCTAssertEqual(vm.remainingSeconds, recipe.steps[1].durationSeconds)
        XCTAssertEqual(vm.formattedRemainingTime, "03:00")

        vm.goToPreviousStep()
        XCTAssertEqual(vm.currentStepIndex, 0)
        XCTAssertEqual(vm.formattedRemainingTime, "08:00")
    }

    @MainActor
    func testMealPlannerGroupedShoppingItemsByAisle() {
        let vm = MealPlannerViewModel()
        let items = [
            ShoppingListItem(name: "Wild Salmon", quantityText: "360 g", aisle: .proteins),
            ShoppingListItem(name: "Chicken Breast", quantityText: "340 g", aisle: .proteins),
            ShoppingListItem(name: "Avocado", quantityText: "2 whole", aisle: .produce),
            ShoppingListItem(name: "Rolled Oats", quantityText: "100 g", aisle: .grainsAndPasta)
        ]

        let grouped = vm.groupedShoppingItems(from: items)
        XCTAssertEqual(grouped.count, 3)
        XCTAssertEqual(grouped[0].aisle, .produce)
        XCTAssertEqual(grouped[0].items.count, 1)
        XCTAssertEqual(grouped[1].aisle, .proteins)
        XCTAssertEqual(grouped[1].items.count, 2)
        XCTAssertEqual(grouped[2].aisle, .grainsAndPasta)
    }
}
