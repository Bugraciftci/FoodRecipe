//
//  ContentView.swift
//  FoodRecipe
//
//  Created by Muhammed Buğra on 8.02.2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RecipeFinderViewModel()
    
    var body: some View {
        NavigationView {
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.recipes.isEmpty {
                IngredientSelectionView(viewModel: viewModel)
            } else {
                RecipesView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    ContentView()
}
