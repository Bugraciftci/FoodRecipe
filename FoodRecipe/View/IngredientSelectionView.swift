//
//  IngredientSelectionView.swift
//  FoodRecipe
//
//  Created by Muhammed Buğra on 8.02.2024.
//

import SwiftUI

struct IngredientSelectionView: View {
    @ObservedObject var viewModel: RecipeFinderViewModel
    @Binding var isPresenting: Bool // Bu değer, butona tıklandığında güncellenecek
    
    var body: some View {
        List {
            ForEach(viewModel.allIngredients, id: \.self) { ingredient in
                MultipleSelectionRow(title: ingredient, isSelected: viewModel.selectedIngredients.contains(ingredient)) {
                    viewModel.toggleIngredientSelection(ingredient)
                }
            }
        }
        .navigationBarTitle("Malzemeleri Seçin", displayMode: .inline)
        .navigationBarItems(trailing: Button("Tamam") {
            viewModel.findRecipes()
            isPresenting = false // Tarifler bulunduğunda view'ı kapat
        })
    }
}

// Önizleme için aşağıdaki satırları düzenlemeniz gerekebilir
// Özellikle `isPresenting` bağlamasını doğru bir şekilde sağlamanız önemlidir
struct IngredientSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        IngredientSelectionView(viewModel: RecipeFinderViewModel(), isPresenting: .constant(true))
    }
}
