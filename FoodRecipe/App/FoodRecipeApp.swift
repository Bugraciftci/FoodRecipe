import SwiftUI

@main
struct FoodRecipeApp: App {
    @StateObject private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            MainTabView(container: container)
        }
    }
}
