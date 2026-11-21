import SwiftUI

struct FavoritesView: View {
    let allRecipes: [Recipe]
    @ObservedObject var kitchenStore: KitchenStore

    private var favoriteRecipes: [Recipe] {
        allRecipes.filter { kitchenStore.isFavorite($0.id) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if favoriteRecipes.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(CulinaryTheme.proteinRose)
                        Text("No Saved Chef Recipes Yet")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(CulinaryTheme.textPrimary)
                        Text("Bookmark your favorite high-protein bowls and Anatolian classics from the Chef Studio tab.")
                            .font(.caption)
                            .foregroundStyle(CulinaryTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 80)
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(favoriteRecipes) { recipe in
                            NavigationLink {
                                RecipeDetailView(recipe: recipe, kitchenStore: kitchenStore)
                            } label: {
                                HStack(spacing: 14) {
                                    CachedMealImageView(
                                        urlString: recipe.imageURL,
                                        fallbackAssetName: recipe.localAssetName,
                                        height: 82,
                                        cornerRadius: 14
                                    )
                                    .frame(width: 82)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(recipe.cuisine.rawValue.uppercased())
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(CulinaryTheme.saffronAccent)
                                        Text(recipe.title)
                                            .font(.subheadline.weight(.bold))
                                            .foregroundStyle(CulinaryTheme.textPrimary)
                                            .lineLimit(1)
                                        Text("\(recipe.macrosPerServing.calories) kcal · \(recipe.macrosPerServing.proteinGrams)g Protein · \(recipe.totalMinutes)m")
                                            .font(.caption2)
                                            .foregroundStyle(CulinaryTheme.textSecondary)
                                    }

                                    Spacer()

                                    Button {
                                        kitchenStore.toggleFavorite(recipe.id)
                                    } label: {
                                        Image(systemName: "heart.fill")
                                            .foregroundStyle(CulinaryTheme.proteinRose)
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
                    .padding(16)
                }
            }
            .background(CulinaryTheme.background.ignoresSafeArea())
            .navigationTitle("Saved Cookbook")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
