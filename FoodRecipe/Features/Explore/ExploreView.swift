import SwiftUI

struct ExploreView: View {
    @ObservedObject var viewModel: ExploreViewModel
    @ObservedObject var kitchenStore: KitchenStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    heroHeader
                    searchAndFilterSection
                    cuisineCarousel
                    recipeGridSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(CulinaryTheme.background.ignoresSafeArea())
            .navigationTitle("Chef Studio")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if viewModel.allRecipes.isEmpty {
                    await viewModel.loadCatalog()
                }
            }
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("LIVE CULINARY & MACRO STUDIO", systemImage: "sparkles")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(CulinaryTheme.saffronAccent)
                Spacer()
                Text("\(viewModel.allRecipes.count) Chef Recipes")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(CulinaryTheme.elevatedSurface))
                    .foregroundStyle(CulinaryTheme.textSecondary)
            }

            Text("What are we cooking today?")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(CulinaryTheme.textPrimary)

            Text("Precision ingredient scaling, step-by-step hands-free timers, and live pantry matching.")
                .font(.subheadline)
                .foregroundStyle(CulinaryTheme.textSecondary)
        }
        .padding(.top, 8)
    }

    private var searchAndFilterSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(CulinaryTheme.textSecondary)
            TextField("Search dishes, cuisines, or ingredients...", text: $viewModel.searchQuery)
                .foregroundStyle(CulinaryTheme.textPrimary)
                .submitLabel(.search)
                .onSubmit {
                    Task { await viewModel.performLiveSearchIfNeeded() }
                }
            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(CulinaryTheme.textSecondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(CulinaryTheme.cardBackground)
        )
    }

    private var cuisineCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(CuisineCategory.allCases) { category in
                    let isSelected = viewModel.selectedCuisine == category
                    Button {
                        viewModel.selectedCuisine = category
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.symbolName)
                                .font(.caption.weight(.semibold))
                            Text(category.rawValue)
                                .font(.caption.weight(.semibold))
                        }
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

    private var recipeGridSection: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.filteredRecipes) { recipe in
                NavigationLink {
                    RecipeDetailView(recipe: recipe, kitchenStore: kitchenStore)
                } label: {
                    recipeCard(recipe)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func recipeCard(_ recipe: Recipe) -> some View {
        let matchResult = recipe.pantryMatchResult(availablePantryItems: kitchenStore.pantryItems)
        let isFav = kitchenStore.isFavorite(recipe.id)

        return VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                CachedMealImageView(
                    urlString: recipe.imageURL,
                    fallbackAssetName: recipe.localAssetName,
                    height: 190,
                    cornerRadius: 16
                )

                HStack(spacing: 8) {
                    Text("\(matchResult.matchPercentage)% Pantry Match")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.black.opacity(0.75)))
                        .foregroundStyle(matchResult.matchPercentage >= 65 ? CulinaryTheme.herbEmerald : CulinaryTheme.carbAmber)

                    Button {
                        kitchenStore.toggleFavorite(recipe.id)
                    } label: {
                        Image(systemName: isFav ? "heart.fill" : "heart")
                            .font(.system(size: 14, weight: .bold))
                            .padding(8)
                            .background(Circle().fill(Color.black.opacity(0.7)))
                            .foregroundStyle(isFav ? CulinaryTheme.proteinRose : .white)
                    }
                }
                .padding(12)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(recipe.cuisine.rawValue.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(CulinaryTheme.saffronAccent)
                    Spacer()
                    Label("\(recipe.totalMinutes) min", systemImage: "clock.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(CulinaryTheme.textSecondary)
                }

                Text(recipe.title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(CulinaryTheme.textPrimary)
                    .lineLimit(1)

                Text(recipe.subtitle)
                    .font(.caption)
                    .foregroundStyle(CulinaryTheme.textSecondary)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    Label("\(recipe.macrosPerServing.calories) kcal", systemImage: "flame.fill")
                        .foregroundStyle(CulinaryTheme.saffronAccent)
                    Label("\(recipe.macrosPerServing.proteinGrams)g Protein", systemImage: "bolt.fill")
                        .foregroundStyle(CulinaryTheme.proteinRose)
                    Label("\(recipe.ingredients.count) items", systemImage: "basket.fill")
                        .foregroundStyle(CulinaryTheme.textSecondary)
                }
                .font(.caption2.weight(.semibold))
                .padding(.top, 4)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(CulinaryTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}
