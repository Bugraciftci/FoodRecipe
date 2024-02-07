//
//  RecipeFinderViewModel.swift
//  FoodRecipe
//
//  Created by Muhammed Buğra on 8.02.2024.
//

import Foundation

class RecipeFinderViewModel: ObservableObject {
    @Published var selectedIngredients = Set<String>()
    @Published var recipes: [Recipe] = []
    @Published var isLoading = false
    
    let allIngredients = ["Domates", "Biber", "Soğan", "Sarımsak", "Havuç", "Patates", "Elma", "Muz", "Portakal", "Limon"]
    
    func findRecipes() {
        isLoading = true
        // Simülasyon için gecikme ekleniyor
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // Simülasyon: API yanıtı gibi davranılıyor
            self.recipes = [
                Recipe(name: "Yemek 1", ingredients: ["Domates", "Biber"]),
                Recipe(name: "Yemek 2", ingredients: ["Soğan", "Sarımsak"]),
                Recipe(name: "Yemek 3", ingredients: ["Havuç", "Patates"])
            ]
            self.isLoading = false
        }
    }
    
    func toggleIngredientSelection(_ ingredient: String) {
        if selectedIngredients.contains(ingredient) {
            selectedIngredients.remove(ingredient)
        } else {
            selectedIngredients.insert(ingredient)
        }
    }
}
