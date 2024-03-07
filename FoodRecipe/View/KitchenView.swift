//
//  KitchenView.swift
//  FoodRecipe
//
//  Created by Muhammed Buğra on 8.03.2024.
//

import SwiftUI

struct KitchenView: View {
    @ObservedObject var viewModel: RecipeFinderViewModel
    @State private var showSettings = false
    @State private var showFavorites = false
    @State private var isPresentingIngredientSelection = true

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.recipes.isEmpty {
                    IngredientSelectionView(viewModel: viewModel, isPresenting: $isPresentingIngredientSelection)
                } else {
                    RecipesView(viewModel: viewModel)
                }
            }
            .navigationBarTitle("Mutfak", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showFavorites.toggle()
                    }) {
                        Image(systemName: "star.fill")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSettings.toggle()
                    }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showFavorites) {
                FavoritesView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

struct KitchenView_Previews: PreviewProvider {
    static var previews: some View {
        KitchenView(viewModel: RecipeFinderViewModel())
    }
}
