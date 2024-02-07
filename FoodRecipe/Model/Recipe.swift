//
//  Recipe.swift
//  FoodRecipe
//
//  Created by Muhammed Buğra on 8.02.2024.
//

import Foundation

struct Recipe: Identifiable {
    let id = UUID()
    var name: String
    var ingredients: [String]
}

