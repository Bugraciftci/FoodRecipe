import Foundation
import Combine

@MainActor
final class PantryMatcherViewModel: ObservableObject {
    @Published var customIngredientInput: String = ""
    @Published var minimumMatchPercentage: Int = 25

    func rankedMatches(recipes: [Recipe], pantryItems: Set<String>) -> [PantryMatchResult] {
        recipes
            .map { $0.pantryMatchResult(availablePantryItems: pantryItems) }
            .filter { $0.matchPercentage >= minimumMatchPercentage }
            .sorted {
                if $0.matchPercentage == $1.matchPercentage {
                    return $0.missingIngredients.count < $1.missingIngredients.count
                }
                return $0.matchPercentage > $1.matchPercentage
            }
    }
}
