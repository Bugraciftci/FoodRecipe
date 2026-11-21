import Foundation
import Combine

@MainActor
final class ExploreViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var selectedCuisine: CuisineCategory = .all
    @Published var selectedDietaryTag: DietaryTag? = nil
    @Published var maxPrepTimeMinutes: Int? = nil
    @Published private(set) var allRecipes: [Recipe] = []
    @Published private(set) var filteredRecipes: [Recipe] = []
    @Published private(set) var isLoading: Bool = false

    private let repository: RecipeRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    init(repository: RecipeRepositoryProtocol) {
        self.repository = repository
        bindFilters()
    }

    func loadCatalog(forceRefresh: Bool = false) async {
        isLoading = true
        let loaded = await repository.fetchCatalog(forceRefresh: forceRefresh)
        allRecipes = loaded
        applyFilters()
        isLoading = false
    }

    func performLiveSearchIfNeeded() async {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else { return }
        let remote = await repository.searchRemoteMeals(query: trimmed)
        let existingIds = Set(allRecipes.map(\.id))
        for item in remote where !existingIds.contains(item.id) {
            allRecipes.append(item)
        }
        applyFilters()
    }

    func applyFilters() {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        filteredRecipes = allRecipes.filter { recipe in
            if selectedCuisine != .all {
                if selectedCuisine == .quickMeals {
                    if recipe.totalMinutes > 20 { return false }
                } else if selectedCuisine == .highProtein {
                    if recipe.macrosPerServing.proteinGrams < 30 { return false }
                } else if recipe.cuisine != selectedCuisine {
                    return false
                }
            }

            if let tag = selectedDietaryTag, !recipe.dietaryTags.contains(tag) {
                return false
            }

            if let maxMinutes = maxPrepTimeMinutes, recipe.totalMinutes > maxMinutes {
                return false
            }

            if !query.isEmpty {
                let matchesTitle = recipe.title.lowercased().contains(query)
                let matchesSubtitle = recipe.subtitle.lowercased().contains(query)
                let matchesIngredient = recipe.ingredients.contains { $0.name.lowercased().contains(query) }
                if !(matchesTitle || matchesSubtitle || matchesIngredient) {
                    return false
                }
            }
            return true
        }
    }

    private func bindFilters() {
        Publishers.CombineLatest4($searchQuery, $selectedCuisine, $selectedDietaryTag, $maxPrepTimeMinutes)
            .debounce(for: .milliseconds(120), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
}
