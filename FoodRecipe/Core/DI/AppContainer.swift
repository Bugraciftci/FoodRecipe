import Foundation

@MainActor
final class AppContainer: ObservableObject {
    let repository: RecipeRepositoryProtocol
    let kitchenStore: KitchenStore

    init(
        repository: RecipeRepositoryProtocol = LiveRecipeRepository(),
        kitchenStore: KitchenStore? = nil
    ) {
        self.repository = repository
        self.kitchenStore = kitchenStore ?? KitchenStore()
    }
}
