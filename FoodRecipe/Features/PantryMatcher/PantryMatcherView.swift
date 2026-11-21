import SwiftUI

struct PantryMatcherView: View {
    let allRecipes: [Recipe]
    @ObservedObject var kitchenStore: KitchenStore
    @StateObject private var viewModel = PantryMatcherViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    pantryHeader
                    addCustomPantryItemBar
                    pantryStaplesGrid
                    rankedRecipeMatchesSection
                }
                .padding(16)
            }
            .background(CulinaryTheme.background.ignoresSafeArea())
            .navigationTitle("Smart Pantry Matcher")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var pantryHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("INGREDIENT MATCH ENGINE", systemImage: "refrigerator.fill")
                .font(.caption2.weight(.bold))
                .foregroundStyle(CulinaryTheme.herbEmerald)

            Text("What's in your kitchen?")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(CulinaryTheme.textPrimary)

            Text("Tap the ingredients you have on hand. We'll rank every chef recipe by match percentage and highlight missing items.")
                .font(.caption)
                .foregroundStyle(CulinaryTheme.textSecondary)
        }
    }

    private var addCustomPantryItemBar: some View {
        HStack(spacing: 10) {
            TextField("Add custom ingredient (e.g. Chicken, Feta)...", text: $viewModel.customIngredientInput)
                .foregroundStyle(CulinaryTheme.textPrimary)
                .submitLabel(.done)
                .onSubmit(addCustomIngredient)

            Button(action: addCustomIngredient) {
                Text("Add")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(CulinaryTheme.saffronAccent))
                    .foregroundStyle(Color.black)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(CulinaryTheme.cardBackground)
        )
    }

    private var pantryStaplesGrid: some View {
        let combinedItems = Array(Set(KitchenStore.commonPantryStaples).union(kitchenStore.pantryItems)).sorted()

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Your Active Pantry (\(kitchenStore.pantryItems.count) selected)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(CulinaryTheme.textPrimary)
                Spacer()
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 135), spacing: 8)], spacing: 8) {
                ForEach(combinedItems, id: \.self) { item in
                    let isSelected = kitchenStore.hasPantryItem(item)
                    Button {
                        kitchenStore.togglePantryItem(item)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                                .font(.caption)
                            Text(item)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(isSelected ? CulinaryTheme.herbEmerald.opacity(0.22) : CulinaryTheme.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(isSelected ? CulinaryTheme.herbEmerald : Color.white.opacity(0.06), lineWidth: 1)
                                )
                        )
                        .foregroundStyle(isSelected ? CulinaryTheme.herbEmerald : CulinaryTheme.textSecondary)
                    }
                }
            }
        }
    }

    private var rankedRecipeMatchesSection: some View {
        let matches = viewModel.rankedMatches(recipes: allRecipes, pantryItems: kitchenStore.pantryItems)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Best Recipe Matches (\(matches.count))")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(CulinaryTheme.textPrimary)
                Spacer()
            }

            ForEach(matches) { match in
                NavigationLink {
                    RecipeDetailView(recipe: match.recipe, kitchenStore: kitchenStore)
                } label: {
                    HStack(spacing: 14) {
                        CachedMealImageView(
                            urlString: match.recipe.imageURL,
                            fallbackAssetName: match.recipe.localAssetName,
                            height: 76,
                            cornerRadius: 12
                        )
                        .frame(width: 76)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(match.matchPercentage)% MATCH")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule().fill(
                                            match.matchPercentage >= 70
                                                ? CulinaryTheme.herbEmerald.opacity(0.2)
                                                : CulinaryTheme.carbAmber.opacity(0.2)
                                        )
                                    )
                                    .foregroundStyle(match.matchPercentage >= 70 ? CulinaryTheme.herbEmerald : CulinaryTheme.carbAmber)

                                Spacer()
                                Text("\(match.recipe.totalMinutes)m")
                                    .font(.caption2)
                                    .foregroundStyle(CulinaryTheme.textSecondary)
                            }

                            Text(match.recipe.title)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(CulinaryTheme.textPrimary)
                                .lineLimit(1)

                            if match.missingIngredients.isEmpty {
                                Text("Ready to cook right now — all ingredients available!")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(CulinaryTheme.herbEmerald)
                            } else {
                                Text("Missing \(match.missingIngredients.count): \(match.missingIngredients.map(\.name).joined(separator: ", "))")
                                    .font(.caption2)
                                    .foregroundStyle(CulinaryTheme.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(CulinaryTheme.cardBackground)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func addCustomIngredient() {
        let trimmed = viewModel.customIngredientInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        kitchenStore.addCustomPantryItem(trimmed)
        viewModel.customIngredientInput = ""
    }
}
