//
//  SettingsView.swift
//  Moduler
//
//  Created by Muhammed Buğra on 8.03.2024.
//

import SwiftUI
import StoreKit

struct SettingsView: View {

   // @EnvironmentObject var iapService: IAPService
    @AppStorage("isDarkModeEnabled") private var isDarkModeEnabled: Bool = false // @AppStorage kullanımı
    @State private var isShareSheetShowing = false
    @State private var showingPurchaseSheet = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("About us 🌟")) {
                    Button("Rate us ❤️") {
                        SKStoreReviewController.requestReview()
                    }
                    Button("Recommend us to your friends 🚀") {
                        isShareSheetShowing = true
                    }
                }
                
                Section(header: Text("Premium 🥇")) {
                    Button("Become Premium 👑") {
                        showingPurchaseSheet = true
                    }
                    .sheet(isPresented: $showingPurchaseSheet) {
             //           SubscriptionView()
                    }
                    Toggle(isOn: $isDarkModeEnabled) {
                        Text(isDarkModeEnabled ? "Dark Mode" : "Light Mode")
                    }
                }
                
                Section(header: Text("Terms 📜")) {
                    Link("Terms of Use", destination: URL(string: "https://bugraciftci.github.io/EasyEnglishTerms.github.io/")!)
                    Link("Privacy Policy", destination: URL(string: "https://bugraciftci.github.io/EasyEnglishPrivacy.github.io/")!)
                }
                
                Section(header: Text("Questions ❓")) {
                    Link("Contact me on Twitter", destination: URL(string: "https://twitter.com/bugra_ciftci_")!)
                }
            }
            .foregroundColor(Color.primary)
            .navigationTitle("Settings")
            .sheet(isPresented: $isShareSheetShowing) {
                ActivityView(activityItems: ["Check out this amazing app: https://appstore.com"])
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(isDarkModeEnabled ? .dark : .light) // Karanlık mod ayarını burada kullanın
    }
}

struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
