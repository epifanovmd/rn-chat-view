import UIKit

final class ImageCache {
    static let shared = ImageCache()

    private let memoryCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 300
        cache.totalCostLimit = 80 * 1024 * 1024
        return cache
    }()

    private let urlCache: URLCache = {
        URLCache(memoryCapacity: 20 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024)
    }()

    private var inFlight: [String: [(UIImage?) -> Void]] = [:]
    private let lock = NSLock()

    private init() {
        NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil, queue: nil) { [weak self] _ in
            self?.memoryCache.removeAllObjects()
        }
    }

    func image(forKey key: String) -> UIImage? {
        memoryCache.object(forKey: key as NSString)
    }

    func store(_ image: UIImage, forKey key: String) {
        memoryCache.setObject(image, forKey: key as NSString, cost: image.pngData()?.count ?? 0)
    }

    @discardableResult
    func load(url: String, completion: @escaping (UIImage?) -> Void) -> URLSessionDataTask? {
        if let cached = image(forKey: url) {
            completion(cached)
            return nil
        }

        lock.lock()
        if inFlight[url] != nil {
            inFlight[url]?.append(completion)
            lock.unlock()
            return nil
        }
        inFlight[url] = [completion]
        lock.unlock()

        guard let requestURL = URL(string: url) else {
            deliver(url: url, image: nil)
            return nil
        }

        let request = URLRequest(url: requestURL, cachePolicy: .returnCacheDataElseLoad)
        if let cached = urlCache.cachedResponse(for: request),
           let image = UIImage(data: cached.data) {
            store(image, forKey: url)
            deliver(url: url, image: image)
            return nil
        }

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, _ in
            guard let self, let data, let response, let image = UIImage(data: data) else {
                self?.deliver(url: url, image: nil)
                return
            }
            let cached = CachedURLResponse(response: response, data: data)
            self.urlCache.storeCachedResponse(cached, for: request)
            self.store(image, forKey: url)
            self.deliver(url: url, image: image)
        }
        task.resume()
        return task
    }

    private func deliver(url: String, image: UIImage?) {
        lock.lock()
        let handlers = inFlight.removeValue(forKey: url) ?? []
        lock.unlock()
        DispatchQueue.main.async {
            handlers.forEach { $0(image) }
        }
    }
}

// MARK: - UIImageView Extension

extension UIImageView {
    private static var taskKey = "ImageCache.Task"

    func loadChatImage(url: String?, placeholder: UIImage? = nil) {
        cancelImageLoad()
        image = placeholder

        guard let url, !url.isEmpty else { return }

        if let cached = ImageCache.shared.image(forKey: url) {
            image = cached
            return
        }

        let task = ImageCache.shared.load(url: url) { [weak self] loaded in
            guard let self else { return }
            if let loaded {
                UIView.transition(with: self, duration: 0.15, options: .transitionCrossDissolve) {
                    self.image = loaded
                }
            }
        }
        objc_setAssociatedObject(self, &Self.taskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func cancelImageLoad() {
        (objc_getAssociatedObject(self, &Self.taskKey) as? URLSessionDataTask)?.cancel()
        objc_setAssociatedObject(self, &Self.taskKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
