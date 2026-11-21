import Foundation

protocol RecipeRepositoryProtocol: Sendable {
    func fetchCatalog(forceRefresh: Bool) async -> [Recipe]
    func searchRemoteMeals(query: String) async -> [Recipe]
}

actor LiveRecipeRepository: RecipeRepositoryProtocol {
    private let session: URLSession
    private var cachedRecipes: [Recipe] = []

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchCatalog(forceRefresh: Bool = false) async -> [Recipe] {
        if !forceRefresh && !cachedRecipes.isEmpty {
            return cachedRecipes
        }

        var catalog = Self.curatedChefCatalog
        let remoteMeals = await searchRemoteMeals(query: "")
        let existingIds = Set(catalog.map(\.id))
        for meal in remoteMeals where !existingIds.contains(meal.id) {
            catalog.append(meal)
        }

        cachedRecipes = catalog
        return catalog
    }

    func searchRemoteMeals(query: String) async -> [Recipe] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://www.themealdb.com/api/json/v1/1/search.php?s=\(encoded)") else {
            return []
        }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 8
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return []
            }
            let decoded = try JSONDecoder().decode(MealDBSearchResponse.self, from: data)
            return (decoded.meals ?? []).compactMap { $0.toDomainRecipe() }
        } catch {
            return []
        }
    }
}

// MARK: - TheMealDB DTO Mapping

private struct MealDBSearchResponse: Decodable {
    let meals: [MealDBItemDTO]?
}

private struct MealDBItemDTO: Decodable {
    let idMeal: String
    let strMeal: String
    let strCategory: String?
    let strArea: String?
    let strInstructions: String?
    let strMealThumb: String?
    let strIngredient1: String?
    let strIngredient2: String?
    let strIngredient3: String?
    let strIngredient4: String?
    let strIngredient5: String?
    let strIngredient6: String?
    let strIngredient7: String?
    let strIngredient8: String?
    let strMeasure1: String?
    let strMeasure2: String?
    let strMeasure3: String?
    let strMeasure4: String?
    let strMeasure5: String?
    let strMeasure6: String?
    let strMeasure7: String?
    let strMeasure8: String?

    func toDomainRecipe() -> Recipe? {
        let rawIngredients: [(String?, String?)] = [
            (strIngredient1, strMeasure1), (strIngredient2, strMeasure2),
            (strIngredient3, strMeasure3), (strIngredient4, strMeasure4),
            (strIngredient5, strMeasure5), (strIngredient6, strMeasure6),
            (strIngredient7, strMeasure7), (strIngredient8, strMeasure8)
        ]

        var ingredients: [IngredientMeasure] = []
        for (idx, pair) in rawIngredients.enumerated() {
            guard let rawName = pair.0?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !rawName.isEmpty else { continue }
            let rawUnit = pair.1?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "1 portion"
            ingredients.append(
                IngredientMeasure(
                    id: "\(idMeal)-ing-\(idx)",
                    name: rawName.capitalized,
                    baseAmount: 1,
                    unit: rawUnit,
                    aisle: Self.inferAisle(for: rawName)
                )
            )
        }

        guard !ingredients.isEmpty else { return nil }

        let sentences = (strInstructions ?? "")
            .replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 12 }

        let steps: [CookingStep] = (sentences.isEmpty ? ["Prepare and cook all ingredients until golden and aromatic."] : sentences)
            .prefix(6)
            .enumerated()
            .map { index, line in
                CookingStep(
                    stepNumber: index + 1,
                    title: "Step \(index + 1)",
                    instruction: line,
                    durationSeconds: (index + 1) * 180,
                    chefTip: index == 0 ? "Keep prep bowls organized (mise en place) for even cooking." : nil
                )
            }

        let cuisine = Self.mapCuisine(area: strArea, category: strCategory)
        let hashSeed = abs(idMeal.hashValue)
        let calories = 380 + (hashSeed % 280)
        let protein = 22 + (hashSeed % 26)
        let carbs = 28 + (hashSeed % 38)
        let fat = 12 + (hashSeed % 18)

        return Recipe(
            id: "mealdb-\(idMeal)",
            title: strMeal,
            subtitle: "\(strArea ?? "Global") · \(strCategory ?? "Chef Special")",
            cuisine: cuisine,
            prepMinutes: 15,
            cookMinutes: 25,
            defaultServings: 2,
            difficulty: "Medium",
            imageURL: strMealThumb ?? "",
            localAssetName: "dinner",
            macrosPerServing: MacroBreakdown(calories: calories, proteinGrams: protein, carbsGrams: carbs, fatGrams: fat),
            dietaryTags: protein >= 32 ? [.highProtein, .mealPrep] : [.mealPrep],
            ingredients: ingredients,
            steps: steps
        )
    }

    private static func mapCuisine(area: String?, category: String?) -> CuisineCategory {
        let a = (area ?? "").lowercased()
        let c = (category ?? "").lowercased()
        if c.contains("dessert") { return .dessert }
        if a.contains("turkish") { return .turkish }
        if a.contains("italian") { return .italian }
        if a.contains("Greek") || a.contains("greek") || a.contains("moroccan") || a.contains("spanish") { return .mediterranean }
        if a.contains("japanese") || a.contains("chinese") || a.contains("thai") || a.contains("indian") { return .asian }
        return .mediterranean
    }

    private static func inferAisle(for name: String) -> IngredientAisle {
        let lower = name.lowercased()
        if lower.contains("chicken") || lower.contains("beef") || lower.contains("salmon") || lower.contains("lamb") || lower.contains("prawn") {
            return .proteins
        }
        if lower.contains("milk") || lower.contains("cheese") || lower.contains("yogurt") || lower.contains("butter") || lower.contains("egg") {
            return .dairy
        }
        if lower.contains("rice") || lower.contains("pasta") || lower.contains("flour") || lower.contains("bread") || lower.contains("noodle") {
            return .grainsAndPasta
        }
        if lower.contains("oil") || lower.contains("salt") || lower.contains("pepper") || lower.contains("cumin") || lower.contains("paprika") {
            return .spicesAndOils
        }
        return .produce
    }
}

// MARK: - Curated Chef Catalog (Offline-First Seed with Real Meal Photography)

extension LiveRecipeRepository {
    static let curatedChefCatalog: [Recipe] = [
        Recipe(
            id: "tr-ali-nazik-kebab",
            title: "Ali Nazik Smoked Eggplant & Lamb Bowl",
            subtitle: "Anatolian Charred Eggplant & Garlic Yogurt",
            cuisine: .turkish,
            prepMinutes: 15,
            cookMinutes: 20,
            defaultServings: 2,
            difficulty: "Medium",
            imageURL: "https://www.themealdb.com/images/media/meals/1529444830.jpg",
            localAssetName: "dinner",
            macrosPerServing: MacroBreakdown(calories: 490, proteinGrams: 38, carbsGrams: 22, fatGrams: 26),
            dietaryTags: [.highProtein, .glutenFree],
            ingredients: [
                IngredientMeasure(id: "an-1", name: "Lean Diced Lamb", baseAmount: 320, unit: "g", aisle: .proteins),
                IngredientMeasure(id: "an-2", name: "Roasted Eggplant", baseAmount: 2, unit: "whole", aisle: .produce),
                IngredientMeasure(id: "an-3", name: "Strained Greek Yogurt", baseAmount: 220, unit: "g", aisle: .dairy),
                IngredientMeasure(id: "an-4", name: "Garlic Cloves", baseAmount: 3, unit: "cloves", aisle: .produce),
                IngredientMeasure(id: "an-5", name: "Olive Oil", baseAmount: 2, unit: "tbsp", aisle: .spicesAndOils),
                IngredientMeasure(id: "an-6", name: "Aleppo Chili Flakes", baseAmount: 1.5, unit: "tsp", aisle: .spicesAndOils)
            ],
            steps: [
                CookingStep(stepNumber: 1, title: "Char & Mash Eggplants", instruction: "Roast eggplants until skins blister and flesh is smoky and soft. Peel and mash finely with a pinch of sea salt.", durationSeconds: 480, chefTip: "Drain excess liquid from the eggplant so the yogurt base stays creamy."),
                CookingStep(stepNumber: 2, title: "Whip Garlic Yogurt Base", instruction: "Fold crushed garlic and warm mashed eggplant into strained yogurt over ultra-low heat.", durationSeconds: 180, chefTip: "Keep heat low so the yogurt never separates."),
                CookingStep(stepNumber: 3, title: "Sear Spiced Lamb", instruction: "Sear diced lamb in olive oil over high heat until caramelized, then bloom Aleppo chili flakes and paprika in sizzling butter.", durationSeconds: 360, chefTip: "Plate the warm smoky eggplant yogurt first and spoon the lamb directly over the center.")
            ]
        ),
        Recipe(
            id: "tr-menemen-skillet",
            title: "Artisan Turkish Menemen Skillet",
            subtitle: "Simmered Vine Tomatoes, Charred Peppers & Eggs",
            cuisine: .turkish,
            prepMinutes: 8,
            cookMinutes: 12,
            defaultServings: 2,
            difficulty: "Easy",
            imageURL: "https://www.themealdb.com/images/media/meals/1550440197.jpg",
            localAssetName: "fried-egg",
            macrosPerServing: MacroBreakdown(calories: 340, proteinGrams: 21, carbsGrams: 14, fatGrams: 22),
            dietaryTags: [.highProtein, .vegetarian, .glutenFree, .quick20Min],
            ingredients: [
                IngredientMeasure(id: "mn-1", name: "Organic Eggs", baseAmount: 4, unit: "large", aisle: .dairy),
                IngredientMeasure(id: "mn-2", name: "Ripe Vine Tomatoes", baseAmount: 3, unit: "medium", aisle: .produce),
                IngredientMeasure(id: "mn-3", name: "Green Sivri Peppers", baseAmount: 2, unit: "whole", aisle: .produce),
                IngredientMeasure(id: "mn-4", name: "Extra Virgin Olive Oil", baseAmount: 2, unit: "tbsp", aisle: .spicesAndOils),
                IngredientMeasure(id: "mn-5", name: "Aged Ezine Feta Cheese", baseAmount: 60, unit: "g", aisle: .dairy),
                IngredientMeasure(id: "mn-6", name: "Oregano & Urfa Pepper", baseAmount: 1, unit: "tsp", aisle: .spicesAndOils)
            ],
            steps: [
                CookingStep(stepNumber: 1, title: "Sweat Green Peppers", instruction: "Slice peppers thinly and sauté in olive oil over medium heat until blistered and fragrant.", durationSeconds: 180, chefTip: "Use a wide copper or cast-iron pan for optimal evaporation."),
                CookingStep(stepNumber: 2, title: "Reduce Grated Tomatoes", instruction: "Add grated tomatoes and simmer until thickened into a rich, jammy sauce.", durationSeconds: 300, chefTip: nil),
                CookingStep(stepNumber: 3, title: "Fold Eggs Gently", instruction: "Crack eggs directly into the skillet, crumble feta cheese, and fold softly for 90 seconds so curds remain silky.", durationSeconds: 90, chefTip: "Remove from heat while still glossy; carryover heat finishes the eggs.")
            ]
        ),
        Recipe(
            id: "med-grilled-salmon-quinoa",
            title: "Aegean Herb-Crusted Salmon & Quinoa Power Bowl",
            subtitle: "Omega-3 Wild Salmon, Lemon Tahini & Crisp Greens",
            cuisine: .highProtein,
            prepMinutes: 10,
            cookMinutes: 14,
            defaultServings: 2,
            difficulty: "Easy",
            imageURL: "https://www.themealdb.com/images/media/meals/1548772327.jpg",
            localAssetName: "broccoli",
            macrosPerServing: MacroBreakdown(calories: 540, proteinGrams: 46, carbsGrams: 34, fatGrams: 24),
            dietaryTags: [.highProtein, .glutenFree, .mealPrep],
            ingredients: [
                IngredientMeasure(id: "sm-1", name: "Wild Salmon Fillets", baseAmount: 360, unit: "g", aisle: .proteins),
                IngredientMeasure(id: "sm-2", name: "Cooked Tri-Color Quinoa", baseAmount: 200, unit: "g", aisle: .grainsAndPasta),
                IngredientMeasure(id: "sm-3", name: "Broccoli Florets", baseAmount: 180, unit: "g", aisle: .produce),
                IngredientMeasure(id: "sm-4", name: "Avocado", baseAmount: 1, unit: "whole", aisle: .produce),
                IngredientMeasure(id: "sm-5", name: "Lemon Juice", baseAmount: 2, unit: "tbsp", aisle: .produce),
                IngredientMeasure(id: "sm-6", name: "Olive Oil", baseAmount: 1.5, unit: "tbsp", aisle: .spicesAndOils)
            ],
            steps: [
                CookingStep(stepNumber: 1, title: "Season & Sear Salmon", instruction: "Pat salmon fillets dry, season with sea salt, garlic, and dill, and sear skin-side down until crisp.", durationSeconds: 300, chefTip: "Press gently with a spatula for the first 20 seconds so the skin stays flat."),
                CookingStep(stepNumber: 2, title: "Char Broccoli Florets", instruction: "Toss broccoli with olive oil andlemon zest and roast or pan-char until tender-crisp.", durationSeconds: 240, chefTip: nil),
                CookingStep(stepNumber: 3, title: "Assemble Macro Bowl", instruction: "Layer warm quinoa, charred broccoli, sliced avocado, and flaked salmon. Drizzle with lemon olive oil dressing.", durationSeconds: 120, chefTip: nil)
            ]
        ),
        Recipe(
            id: "it-truffle-mushroom-tagliatelle",
            title: "Tuscan Garlic Herb Chicken & Tagliatelle",
            subtitle: "Seared Chicken Breast, Sun-Dried Tomatoes & Spinach",
            cuisine: .italian,
            prepMinutes: 10,
            cookMinutes: 18,
            defaultServings: 2,
            difficulty: "Medium",
            imageURL: "https://www.themealdb.com/images/media/meals/ustsqw1468250014.jpg",
            localAssetName: "spaghetti",
            macrosPerServing: MacroBreakdown(calories: 560, proteinGrams: 44, carbsGrams: 52, fatGrams: 18),
            dietaryTags: [.highProtein, .mealPrep],
            ingredients: [
                IngredientMeasure(id: "it-1", name: "Chicken Breast", baseAmount: 340, unit: "g", aisle: .proteins),
                IngredientMeasure(id: "it-2", name: "Tagliatelle Pasta", baseAmount: 180, unit: "g", aisle: .grainsAndPasta),
                IngredientMeasure(id: "it-3", name: "Baby Spinach", baseAmount: 100, unit: "g", aisle: .produce),
                IngredientMeasure(id: "it-4", name: "Parmigiano Reggiano", baseAmount: 45, unit: "g", aisle: .dairy),
                IngredientMeasure(id: "it-5", name: "Garlic Cloves", baseAmount: 3, unit: "cloves", aisle: .produce),
                IngredientMeasure(id: "it-6", name: "Olive Oil", baseAmount: 1.5, unit: "tbsp", aisle: .spicesAndOils)
            ],
            steps: [
                CookingStep(stepNumber: 1, title: "Boil Pasta Al Dente", instruction: "Cook tagliatelle in generously salted boiling water until 1 minute shy of al dente. Reserve 1/2 cup starchy pasta water.", durationSeconds: 480, chefTip: "Starchy pasta water is the secret emulsifier for a glossy sauce."),
                CookingStep(stepNumber: 2, title: "Golden Sear Chicken", instruction: "Pan-sear seasoned chicken breast cutlets for 4 minutes per side until golden brown, then slice into strips.", durationSeconds: 360, chefTip: nil),
                CookingStep(stepNumber: 3, title: "Emulsify Garlic Spinach Sauce", instruction: "Sauté garlic, wilt baby spinach with pasta water and grated Parmigiano, and toss with tagliatelle and sliced chicken.", durationSeconds: 150, chefTip: nil)
            ]
        ),
        Recipe(
            id: "as-teriyaki-glazed-chicken-bowl",
            title: "Tokyo Ginger Teriyaki Chicken & Edamame Rice",
            subtitle: "High-Protein Glazed Thighs, Steamed Jasmine & Sesame",
            cuisine: .asian,
            prepMinutes: 10,
            cookMinutes: 15,
            defaultServings: 2,
            difficulty: "Easy",
            imageURL: "https://www.themealdb.com/images/media/meals/wvpsxx1468256321.jpg",
            localAssetName: "noodles",
            macrosPerServing: MacroBreakdown(calories: 510, proteinGrams: 42, carbsGrams: 54, fatGrams: 13),
            dietaryTags: [.highProtein, .mealPrep],
            ingredients: [
                IngredientMeasure(id: "as-1", name: "Chicken Breast or Thigh", baseAmount: 350, unit: "g", aisle: .proteins),
                IngredientMeasure(id: "as-2", name: "Jasmine Rice", baseAmount: 180, unit: "g", aisle: .grainsAndPasta),
                IngredientMeasure(id: "as-3", name: "Shelled Edamame", baseAmount: 120, unit: "g", aisle: .produce),
                IngredientMeasure(id: "as-4", name: "Low-Sodium Soy Sauce", baseAmount: 3, unit: "tbsp", aisle: .pantry),
                IngredientMeasure(id: "as-5", name: "Fresh Ginger & Garlic", baseAmount: 1, unit: "tbsp", aisle: .produce),
                IngredientMeasure(id: "as-6", name: "Honey", baseAmount: 1.5, unit: "tbsp", aisle: .pantry)
            ],
            steps: [
                CookingStep(stepNumber: 1, title: "Crisp the Chicken", instruction: "Sear bite-sized chicken pieces in a hot wok or skillet until golden on all sides.", durationSeconds: 300, chefTip: "Avoid overcrowding the wok so the chicken sears instead of steaming."),
                CookingStep(stepNumber: 2, title: "Simmer Ginger Teriyaki Glaze", instruction: "Pour in soy sauce, grated ginger, garlic, and honey. Simmer for 3 minutes until thick and lacquered.", durationSeconds: 180, chefTip: nil),
                CookingStep(stepNumber: 3, title: "Serve with Edamame Rice", instruction: "Spoon over warm jasmine rice with steamed edamame and toasted sesame seeds.", durationSeconds: 90, chefTip: nil)
            ]
        ),
        Recipe(
            id: "qk-avocado-turkey-club",
            title: "10-Minute Protein Turkey & Avocado Sourdough Club",
            subtitle: "Toasted Artisan Sourdough, Smoked Turkey & Herb Aioli",
            cuisine: .quickMeals,
            prepMinutes: 7,
            cookMinutes: 5,
            defaultServings: 1,
            difficulty: "Easy",
            imageURL: "https://www.themealdb.com/images/media/meals/xr0n4r1576788363.jpg",
            localAssetName: "sandwich",
            macrosPerServing: MacroBreakdown(calories: 445, proteinGrams: 37, carbsGrams: 36, fatGrams: 16),
            dietaryTags: [.highProtein, .quick20Min],
            ingredients: [
                IngredientMeasure(id: "qk-1", name: "Sliced Roasted Turkey Breast", baseAmount: 140, unit: "g", aisle: .proteins),
                IngredientMeasure(id: "qk-2", name: "Sourdough Bread", baseAmount: 2, unit: "slices", aisle: .grainsAndPasta),
                IngredientMeasure(id: "qk-3", name: "Ripe Avocado", baseAmount: 0.5, unit: "whole", aisle: .produce),
                IngredientMeasure(id: "qk-4", name: "Greek Yogurt Herb Spread", baseAmount: 2, unit: "tbsp", aisle: .dairy),
                IngredientMeasure(id: "qk-5", name: "Ripe Vine Tomatoes", baseAmount: 4, unit: "slices", aisle: .produce)
            ],
            steps: [
                CookingStep(stepNumber: 1, title: "Toast Sourdough Slices", instruction: "Toast sourdough slices in a dry skillet until crisp on the exterior and chewy inside.", durationSeconds: 150, chefTip: nil),
                CookingStep(stepNumber: 2, title: "Layer Protein & Avocado", instruction: "Spread Greek yogurt herb aioli, layer turkey breast, mashed avocado, and seasoned tomato slices.", durationSeconds: 120, chefTip: "Season the tomato and avocado directly with flaky salt and cracked pepper.")
            ]
        ),
        Recipe(
            id: "ds-protein-oat-berry-pancakes",
            title: "Fluffy Ricotta & Whey Protein Berry Pancakes",
            subtitle: "Post-Workout Golden Stack with Warm Wild Berries",
            cuisine: .dessert,
            prepMinutes: 6,
            cookMinutes: 10,
            defaultServings: 2,
            difficulty: "Easy",
            imageURL: "https://www.themealdb.com/images/media/meals/sywswr1511383814.jpg",
            localAssetName: "pancake",
            macrosPerServing: MacroBreakdown(calories: 390, proteinGrams: 31, carbsGrams: 42, fatGrams: 10),
            dietaryTags: [.highProtein, .vegetarian, .quick20Min],
            ingredients: [
                IngredientMeasure(id: "pc-1", name: "Rolled Oats", baseAmount: 100, unit: "g", aisle: .grainsAndPasta),
                IngredientMeasure(id: "pc-2", name: "Organic Eggs", baseAmount: 2, unit: "large", aisle: .dairy),
                IngredientMeasure(id: "pc-3", name: "Ricotta or Cottage Cheese", baseAmount: 120, unit: "g", aisle: .dairy),
                IngredientMeasure(id: "pc-4", name: "Vanilla Whey or Greek Yogurt", baseAmount: 45, unit: "g", aisle: .dairy),
                IngredientMeasure(id: "pc-5", name: "Fresh Mixed Berries", baseAmount: 120, unit: "g", aisle: .produce)
            ],
            steps: [
                CookingStep(stepNumber: 1, title: "Whisk High-Protein Batter", instruction: "Blend rolled oats, eggs, ricotta, and vanilla protein into a smooth, pourable pancake batter.", durationSeconds: 120, chefTip: "Let the batter rest for 2 minutes so the oat flour hydrates."),
                CookingStep(stepNumber: 2, title: "Griddle Golden Pancakes", instruction: "Cook silver-dollar pancakes on a medium-low nonstick griddle for 2 minutes per side until bubbles form.", durationSeconds: 240, chefTip: nil),
                CookingStep(stepNumber: 3, title: "Top with Warm Berries", instruction: "Stack pancakes and crown with warm crushed berries and a touch of pure honey.", durationSeconds: 60, chefTip: nil)
            ]
        ),
        Recipe(
            id: "med-chickpea-halloumi-salad",
            title: "Cypriot Seared Halloumi & Roasted Chickpea Bowl",
            subtitle: "Crispy Spiced Chickpeas, Pomegranate & Mint Dressing",
            cuisine: .mediterranean,
            prepMinutes: 10,
            cookMinutes: 10,
            defaultServings: 2,
            difficulty: "Easy",
            imageURL: "https://www.themealdb.com/images/media/meals/wvqpwt1468339226.jpg",
            localAssetName: "broccoli",
            macrosPerServing: MacroBreakdown(calories: 465, proteinGrams: 26, carbsGrams: 38, fatGrams: 22),
            dietaryTags: [.vegetarian, .glutenFree, .quick20Min],
            ingredients: [
                IngredientMeasure(id: "hl-1", name: "Halloumi Cheese", baseAmount: 180, unit: "g", aisle: .dairy),
                IngredientMeasure(id: "hl-2", name: "Cooked Chickpeas", baseAmount: 240, unit: "g", aisle: .pantry),
                IngredientMeasure(id: "hl-3", name: "Cucumber & Cherry Tomatoes", baseAmount: 250, unit: "g", aisle: .produce),
                IngredientMeasure(id: "hl-4", name: "Olive Oil", baseAmount: 1.5, unit: "tbsp", aisle: .spicesAndOils),
                IngredientMeasure(id: "hl-5", name: "Lemon Juice", baseAmount: 2, unit: "tbsp", aisle: .produce)
            ],
            steps: [
                CookingStep(stepNumber: 1, title: "Crisp Spiced Chickpeas", instruction: "Toss chickpeas with cumin, paprika, and olive oil in a skillet until crunchy.", durationSeconds: 240, chefTip: nil),
                CookingStep(stepNumber: 2, title: "Golden Sear Halloumi", instruction: "Pan-sear sliced halloumi for 90 seconds per side until a deep golden crust forms.", durationSeconds: 180, chefTip: "Serve immediately while halloumi is warm and squeaky-soft."),
                CookingStep(stepNumber: 3, title: "Toss with Citrus Mint", instruction: "Combine diced cucumber, tomatoes, crispy chickpeas, and halloumi with lemon-olive oil dressing.", durationSeconds: 90, chefTip: nil)
            ]
        )
    ]
}
