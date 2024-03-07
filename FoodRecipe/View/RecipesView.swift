//
//  RecipesView.swift
//  FoodRecipe
//
//  Created by Muhammed Buğra on 8.02.2024.
//

import SwiftUI

struct RecipesView: View {
    @ObservedObject var viewModel: RecipeFinderViewModel
    
    var body: some View {
        List(viewModel.recipes) { recipe in
            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(recipe.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Malzemeler: \(recipe.ingredients.joined(separator: ", "))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(recipe.instructions) // Tarifin talimatlarını göster
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2) // Önizlemede sadece iki satır göster
                        .truncationMode(.tail)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .shadow(radius: 2)
        }
        .navigationBarTitle("Yemek Tarifleri")
        .navigationBarItems(leading: Button("Geri Dön") {
            // Kullanıcının seçim ekranına geri dönmesini sağlayan action
            viewModel.resetSelectionsAndRecipes()
        })
    }
}

#if DEBUG
struct RecipesView_Previews: PreviewProvider {
    static var previews: some View {
        RecipesView(viewModel: RecipeFinderViewModel.mock)
    }
}

extension RecipeFinderViewModel {
    static var mock: RecipeFinderViewModel {
        let mockViewModel = RecipeFinderViewModel()
        mockViewModel.recipes = [
            Recipe(name: "Domates Çorbası", ingredients: ["Domates", "Soğan", "Sarımsak", "Defne Yaprağı"], instructions: "Domates ve soğanı doğrayın..."),
            Recipe(name: "Karnıyarık", ingredients: ["Patlıcan", "Kıyma", "Domates", "Biber"], instructions: "Patlıcanları közleyin..."),
            Recipe(name: "Meyve Salatası", ingredients: ["Muz", "Elma", "Portakal", "Üzüm"], instructions: "Meyveleri küp küp doğrayın...")
        ]
        return mockViewModel
    }
}

#endif
