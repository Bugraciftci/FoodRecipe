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
            VStack(alignment: .leading) {
                Text(recipe.name).font(.headline)
                Text("Malzemeler: \(recipe.ingredients.joined(separator: ", "))")
            }
        }
        .navigationBarTitle("Yemek Tarifleri")
    }
}

struct RecipesView_Previews: PreviewProvider {
    static var previews: some View {
        RecipesView(viewModel: RecipeFinderViewModel())
    }
}
