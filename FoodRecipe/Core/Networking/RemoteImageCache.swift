import Foundation
import UIKit

actor RemoteImageCache {
    static let shared = RemoteImageCache()

    private let memoryCache = NSCache<NSString, UIImage>()
    private var inFlightTasks: [URL: Task<UIImage?, Never>] = [:]
    private let fileManager = FileManager.default
    private let diskDirectory: URL

    init() {
        memoryCache.countLimit = 180
        memoryCache.totalCostLimit = 64 * 1024 * 1024
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        diskDirectory = caches.appendingPathComponent("FoodRecipeMealImages", isDirectory: true)
        try? fileManager.createDirectory(at: diskDirectory, withIntermediateDirectories: true)
    }

    func image(for urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString), !urlString.isEmpty else { return nil }
        let cacheKey = url.absoluteString as NSString

        if let cached = memoryCache.object(forKey: cacheKey) {
            return cached
        }

        let diskURL = diskFileURL(for: url)
        if let data = try? Data(contentsOf: diskURL), let diskImage = UIImage(data: data) {
            memoryCache.setObject(diskImage, forKey: cacheKey, cost: data.count)
            return diskImage
        }

        if let existingTask = inFlightTasks[url] {
            return await existingTask.value
        }

        let task = Task<UIImage?, Never> {
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 12
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse,
                      (200...299).contains(http.statusCode),
                      let downloaded = UIImage(data: data) else {
                    return nil
                }
                try? data.write(to: diskURL, options: .atomic)
                return downloaded
            } catch {
                return nil
            }
        }

        inFlightTasks[url] = task
        let result = await task.value
        inFlightTasks[url] = nil

        if let image = result {
            memoryCache.setObject(image, forKey: cacheKey)
        }
        return result
    }

    private func diskFileURL(for url: URL) -> URL {
        let safeName = url.absoluteString
            .unicodeScalars
            .map { CharacterSet.alphanumerics.contains($0) ? String($0) : "_" }
            .joined()
        let suffix = String(safeName.suffix(90))
        return diskDirectory.appendingPathComponent(suffix + ".img")
    }
}
