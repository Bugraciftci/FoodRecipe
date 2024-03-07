//
//  MultipleSelectionRow.swift
//  FoodRecipe
//
//  Created by Muhammed Buğra on 8.02.2024.
//

import Foundation
import SwiftUI

struct MultipleSelectionRow: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark").foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}

struct MultipleSelectionRowView_Previews: PreviewProvider {
    static var previews: some View {
        MultipleSelectionRow(title: "Tomato", isSelected: true) {
        }
    }
}
