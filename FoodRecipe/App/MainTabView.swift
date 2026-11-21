import SwiftUI

struct MainTabView: View {
    @ObservedObject var container: AppContainer
    @StateObject private var exploreViewModel: ExploreViewModel

    init(container: AppContainer) {
        self.container = container
        _exploreViewModel = StateObject(wrappedValue: ExploreViewModel(repository: container.repository))
    }

    var body: some View {
        TabView {
            ExploreView(viewModel: exploreViewModel, kitchenStore: container.kitchenStore)
                .tabItem {
                    Label("Studio", systemImage: "fork.knife")
                }

            PantryMatcherView(allRecipes: exploreViewModel.allRecipes, kitchenStore: container.kitchenStore)
                .tabItem {
                    Label("Pantry Match", systemImage: "refrigerator.fill")
                }

            MealPlannerView(allRecipes: exploreViewModel.allRecipes, kitchenStore: container.kitchenStore)
                .tabItem {
                    Label("Meal Plan", systemImage: "chart.bar.doc.horizontal.fill")
                }

            FavoritesView(allRecipes: exploreViewModel.allRecipes, kitchenStore: container.kitchenStore)
                .tabItem {
                    Label("Cookbook", systemImage: "heart.text.square.fill")
                }
        }
        .tint(CulinaryTheme.saffronAccent)
        .preferredColorScheme(.dark)
    }
}
