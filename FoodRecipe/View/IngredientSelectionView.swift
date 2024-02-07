//
//  IngredientSelectionView.swift
//  FoodRecipe
//
//  Created by Muhammed Buğra on 8.02.2024.
//

import SwiftUI

struct IngredientSelectionView: View {
    @ObservedObject var viewModel: RecipeFinderViewModel
    
    var body: some View {
        List(viewModel.allIngredients, id: \.self) { ingredient in
            MultipleSelectionRow(title: ingredient, isSelected: viewModel.selectedIngredients.contains(ingredient)) {
                viewModel.toggleIngredientSelection(ingredient)
            }
        }
        .navigationBarTitle("Malzemeleri Seçin")
        .toolbar {
            Button("Tamam") {
                viewModel.findRecipes()
            }
        }
    }
}

#Preview {
    IngredientSelectionView(viewModel: RecipeFinderViewModel())
}
