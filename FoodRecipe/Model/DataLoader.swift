//
//  DataLoader.swift
//  FoodRecipe
//
//  Created by Muhammed Buğra on 8.03.2024.
//

import Foundation

// DataLoader sınıfı yalnızca veri yükleme işlemleri için sorumlu olacak.
struct DataLoader {
    func loadAllIngredients() -> [String] {
        // Gerçek bir uygulamada burada bir API isteği yapılır
        return ["Domates", "Biber", "Soğan", "Sarımsak", "Havuç", "Patates", "Elma", "Muz", "Portakal", "Limon", "Tavuk", "Sığır Eti"]
    }
    
    func loadRecipes(with ingredients: [String]) -> [Recipe] {
        // Bu metod, seçilen malzemelere göre yemek tariflerini döndürür
        // Gerçek bir uygulamada burada bir API isteği yapılabilir
        return [
            Recipe(name: "Yemek 1", ingredients: ["Domates", "Biber"], instructions: "Tarif 1 adımları burada yer alacak."),
            Recipe(name: "Yemek 2", ingredients: ["Soğan", "Sarımsak"], instructions: "Tarif 2 adımları burada yer alacak."),
            Recipe(name: "Yemek 3", ingredients: ["Havuç", "Patates"], instructions: "Tarif 3 adımları burada yer alacak.")
            // Diğer tarifleri ekleyin
        ]
    }
}
