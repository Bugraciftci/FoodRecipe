//
//  RecipeDetailView.swift
//  FoodRecipe
//
//  Created by Muhammed Buğra on 8.03.2024.
//

import SwiftUI

struct RecipeDetailView: View {
    var recipe: Recipe
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(recipe.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Malzemeler:")
                    .font(.title2)
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: 5) {
                    ForEach(recipe.ingredients, id: \.self) { ingredient in
                        HStack {
                            Image(systemName: "circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 8))
                            Text(ingredient)
                        }
                        .padding(.vertical, 2)
                    }
                }

                Text("Tarif:")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(recipe.instructions)
                    .padding(.vertical, 2)
                    .lineSpacing(5) // Satır aralığını artırın
            }
            .padding()
        }
        .navigationBarTitle(recipe.name, displayMode: .inline)
    }
}


#if DEBUG

struct RecipeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RecipeDetailView(recipe: Recipe(name: "Karnıyarık", ingredients: ["Patlıcan", "Kıyma", "Domates", "Biber"], instructions: "Patlıcanları alacalı soyun ve tuzlu suda bekletin. Kıymayı soğan, sarımsak ve baharatlarla kavurun. Domates ve biberi ekleyin. Patlıcanları kızartın ve içlerini kıymalı harçla doldurun. Fırında pişirin."))
        }
    }
}

extension RecipeFinderViewModel {
    static var mock1: RecipeFinderViewModel {
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
