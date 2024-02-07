//
//  LoadingView.swift
//  FoodRecipe
//
//  Created by Muhammed Buğra on 8.02.2024.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            Text("Yemekler Hazırlanıyor...")
                .font(.title2)
                .padding()
            ProgressView()
                .scaleEffect(2)
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    LoadingView()
}
