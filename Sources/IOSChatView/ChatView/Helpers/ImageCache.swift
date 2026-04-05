import CommonCrypto
import UIKit

public final class ImageCache {
    static let shared = ImageCache()

    private let memoryCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 300
        cache.totalCostLimit = 80 * 1024 * 1024
        return cache
    }()

    private let cacheDir: URL
    private let fileManager = FileManager.default
    private var inFlight: [String: [(UIImage?) -> Void]] = [:]
    private let lock = NSLock()

    private init() {
        let dir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ImageCache", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        cacheDir = dir

        NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil, queue: nil) { [weak self] _ in
            self?.memoryCache.removeAllObjects()
        }
    }

    // MARK: - Memory

    func image(forKey key: String) -> UIImage? {
        if let img = memoryCache.object(forKey: key as NSString) { return img }
        // Try disk
        let file = cacheDir.appendingPathComponent(key.sha256ImageName)
        guard let data = try? Data(contentsOf: file), let img = UIImage(data: data) else { return nil }
        memoryCache.setObject(img, forKey: key as NSString)
        return img
    }

    private func store(_ image: UIImage, data: Data, forKey key: String) {
        memoryCache.setObject(image, forKey: key as NSString)
        let file = cacheDir.appendingPathComponent(key.sha256ImageName)
        try? data.write(to: file, options: .atomic)
    }

    // MARK: - Load

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

        let task = URLSession.shared.dataTask(with: requestURL) { [weak self] data, _, _ in
            guard let self, let data, let image = UIImage(data: data) else {
                self?.deliver(url: url, image: nil)
                return
            }
            self.store(image, data: data, forKey: url)
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

// MARK: - SHA256 filename

private extension String {
    var sha256ImageName: String {
        let data = Data(utf8)
        var hash = [UInt8](repeating: 0, count: 32)
        data.withUnsafeBytes { buf in
            _ = CC_SHA256(buf.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
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
