//
//  LoadingView.swift
//  FoodRecipe
//
//  Created by Muhammed Buğra on 8.02.2024.
//

import SwiftUI

struct LoadingView: View {
    // İmajları burada belirtin
    let images = ["broccoli", "cookies", "noodles", "fried-egg", "pancake", "sandwich", "spaghetti"]

    // Aktif imajın indexini tutacak state
    @State private var activeImageIndex = 0

    var body: some View {
        VStack {
            Text("Cooking up something delicious...")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.medium)
                .padding()

            // Carousel için imaj geçişleri
            TabView(selection: $activeImageIndex) {
                ForEach(0..<images.count, id: \.self) { index in
                    Image(images[index])
                        .resizable()
                        .scaledToFit()
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 100) // İmajın boyutunu ayarlayın
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
                    activeImageIndex = (activeImageIndex + 1) % images.count
                }
            }
        }
        .navigationBarHidden(true)
        .background(Image("mutfak"))
    }
}

#Preview {
    LoadingView()
}
