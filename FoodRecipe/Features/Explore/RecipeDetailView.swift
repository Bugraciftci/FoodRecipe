import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    @ObservedObject var kitchenStore: KitchenStore

    @State private var selectedServings: Int
    @State private var isPresentingCookingMode = false
    @State private var showAddedShoppingBanner = false

    init(recipe: Recipe, kitchenStore: KitchenStore) {
        self.recipe = recipe
        self.kitchenStore = kitchenStore
        _selectedServings = State(initialValue: recipe.defaultServings)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                CachedMealImageView(
                    urlString: recipe.imageURL,
                    fallbackAssetName: recipe.localAssetName,
                    height: 240,
                    cornerRadius: 20
                )

                titleAndMetaSection
                MacroRingBadge(macros: recipe.totalMacros(forServings: selectedServings))
                servingsScalerSection
                ingredientsSection
                cookingStepsPreviewSection
            }
            .padding(16)
        }
        .background(CulinaryTheme.background.ignoresSafeArea())
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    kitchenStore.toggleFavorite(recipe.id)
                } label: {
                    Image(systemName: kitchenStore.isFavorite(recipe.id) ? "heart.fill" : "heart")
                        .foregroundStyle(kitchenStore.isFavorite(recipe.id) ? CulinaryTheme.proteinRose : .white)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomActionBar
        }
        .fullScreenCover(isPresented: $isPresentingCookingMode) {
            CookingSessionView(
                viewModel: CookingSessionViewModel(recipe: recipe, servings: selectedServings)
            )
        }
    }

    private var titleAndMetaSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(recipe.cuisine.rawValue.uppercased())
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(CulinaryTheme.saffronAccent.opacity(0.2)))
                    .foregroundStyle(CulinaryTheme.saffronAccent)

                ForEach(recipe.dietaryTags) { tag in
                    Text(tag.rawValue)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(CulinaryTheme.elevatedSurface))
                        .foregroundStyle(CulinaryTheme.textSecondary)
                }
            }

            Text(recipe.title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(CulinaryTheme.textPrimary)

            Text(recipe.subtitle)
                .font(.subheadline)
                .foregroundStyle(CulinaryTheme.textSecondary)

            HStack(spacing: 18) {
                Label("Prep \(recipe.prepMinutes)m", systemImage: "scissors")
                Label("Cook \(recipe.cookMinutes)m", systemImage: "flame.fill")
                Label(recipe.difficulty, systemImage: "chart.bar.fill")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(CulinaryTheme.textSecondary)
            .padding(.top, 4)
        }
    }

    private var servingsScalerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Dynamic Portion Scaler")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(CulinaryTheme.textPrimary)
                Text("All ingredient weights and macros scale automatically")
                    .font(.caption2)
                    .foregroundStyle(CulinaryTheme.textSecondary)
            }
            Spacer()
            HStack(spacing: 12) {
                Button {
                    if selectedServings > 1 { selectedServings -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(CulinaryTheme.saffronAccent)
                }

                Text("\(selectedServings) Servings")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(CulinaryTheme.textPrimary)
                    .frame(minWidth: 82)

                Button {
                    if selectedServings < 12 { selectedServings += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(CulinaryTheme.saffronAccent)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(CulinaryTheme.cardBackground)
        )
    }

    private var ingredientsSection: some View {
        let matchResult = recipe.pantryMatchResult(availablePantryItems: kitchenStore.pantryItems)
        let scaledList = recipe.scaledIngredients(forServings: selectedServings)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ingredients (\(scaledList.count))")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(CulinaryTheme.textPrimary)
                Spacer()
                if !matchResult.missingIngredients.isEmpty {
                    Button {
                        kitchenStore.addIngredientsToShoppingList(
                            matchResult.missingIngredients,
                            scaleFactor: recipe.scaleFactor(forServings: selectedServings),
                            recipeTitle: recipe.title
                        )
                        showAddedShoppingBanner = true
                    } label: {
                        Label("Add \(matchResult.missingIngredients.count) Missing to Cart", systemImage: "cart.badge.plus")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(CulinaryTheme.saffronAccent)
                    }
                }
            }

            if showAddedShoppingBanner {
                Label("Missing ingredients added to your Smart Shopping List!", systemImage: "checkmark.seal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CulinaryTheme.herbEmerald)
            }

            ForEach(scaledList, id: \.ingredient.id) { item in
                let inPantry = matchResult.matchedIngredients.contains(item.ingredient.name)
                HStack {
                    Image(systemName: inPantry ? "checkmark.circle.fill" : "circle.dashed")
                        .foregroundStyle(inPantry ? CulinaryTheme.herbEmerald : CulinaryTheme.carbAmber)
                    Text(item.ingredient.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(CulinaryTheme.textPrimary)
                    Spacer()
                    Text(item.scaledText)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(CulinaryTheme.saffronAccent)
                }
                .padding(.vertical, 6)
                Divider().background(Color.white.opacity(0.06))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(CulinaryTheme.cardBackground)
        )
    }

    private var cookingStepsPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Step-by-Step Chef Instructions")
                .font(.headline.weight(.bold))
                .foregroundStyle(CulinaryTheme.textPrimary)

            ForEach(recipe.steps) { step in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("STEP \(step.stepNumber)")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(CulinaryTheme.saffronAccent))
                            .foregroundStyle(Color.black)

                        Text(step.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(CulinaryTheme.textPrimary)

                        Spacer()
                        if let duration = step.formattedDuration {
                            Label(duration, systemImage: "timer")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(CulinaryTheme.herbEmerald)
                        }
                    }

                    Text(step.instruction)
                        .font(.subheadline)
                        .foregroundStyle(CulinaryTheme.textSecondary)

                    if let tip = step.chefTip {
                        Label(tip, systemImage: "lightbulb.fill")
                            .font(.caption2)
                            .foregroundStyle(CulinaryTheme.carbAmber)
                            .padding(.top, 2)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(CulinaryTheme.elevatedSurface)
                )
            }
        }
        .padding(.bottom, 70)
    }

    private var bottomActionBar: some View {
        HStack(spacing: 12) {
            Button {
                kitchenStore.assignMeal(day: .monday, slot: .dinner, recipeId: recipe.id, servings: selectedServings)
            } label: {
                Label("Plan Meal", systemImage: "calendar.badge.plus")
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(CulinaryTheme.elevatedSurface)
                    )
                    .foregroundStyle(CulinaryTheme.textPrimary)
            }

            Button {
                isPresentingCookingMode = true
            } label: {
                Label("Start Cooking Mode", systemImage: "play.fill")
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(CulinaryTheme.heroGradient)
                    )
                    .foregroundStyle(Color.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}
