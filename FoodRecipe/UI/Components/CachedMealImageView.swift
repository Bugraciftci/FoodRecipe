import SwiftUI
import UIKit

struct CachedMealImageView: View {
    let urlString: String
    let fallbackAssetName: String?
    var height: CGFloat = 180
    var cornerRadius: CGFloat = 16

    @State private var loadedImage: UIImage?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(CulinaryTheme.elevatedSurface)

            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: height)
                    .clipped()
            } else if let asset = fallbackAssetName, !asset.isEmpty, UIImage(named: asset) != nil {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .padding(24)
                    .frame(height: height)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: isLoading ? "fork.knife.circle.fill" : "photo.on.rectangle.angled")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(CulinaryTheme.saffronAccent)
                    Text(isLoading ? "Loading Culinary Preview..." : "Chef Studio Dish")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(CulinaryTheme.textSecondary)
                }
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .task(id: urlString) {
            isLoading = true
            loadedImage = await RemoteImageCache.shared.image(for: urlString)
            isLoading = false
        }
    }
}
