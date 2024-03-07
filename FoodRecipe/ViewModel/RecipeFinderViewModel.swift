//
//  RecipeFinderViewModel.swift
//  FoodRecipe
//
//  Created by Muhammed Buğra on 8.02.2024.
//

import Foundation

// ViewModel, View ile Model arasında veri akışını yönetir.
class RecipeFinderViewModel: ObservableObject {
    @Published var selectedIngredients = Set<String>()
    @Published var recipes: [Recipe] = []
    @Published var isLoading = false
    
    private let dataLoader: DataLoader
    
    init(dataLoader: DataLoader = DataLoader()) {
        self.dataLoader = dataLoader
        loadIngredients()
    }
    
    var allIngredients: [String] = []
    
    func loadIngredients() {
        self.allIngredients = dataLoader.loadAllIngredients()
    }
    
    func findRecipes() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.recipes = self.dataLoader.loadRecipes(with: Array(self.selectedIngredients))
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
    
    func resetSelectionsAndRecipes() {
        self.selectedIngredients.removeAll()
        self.recipes.removeAll()
        // Kullanıcıyı seçim ekranına geri getir
    }
}
