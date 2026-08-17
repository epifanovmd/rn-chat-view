import CommonCrypto
import ImageIO
import UIKit

/// Токен отмены загрузки. Отмена снимает только подписку этого вызова —
/// общий сетевой запрос продолжает жить для остальных подписчиков.
final class ImageLoadToken {
    private(set) var isCancelled = false
    func cancel() { isCancelled = true }
}

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
    private var inFlight: [String: [(token: ImageLoadToken?, completion: (UIImage?) -> Void)]] = [:]
    private let lock = NSLock()

    /// Вся дисковая работа (чтение, запись, очистка) — вне main thread.
    private let diskQueue = DispatchQueue(label: "IOSChatView.ImageCache.disk", qos: .utility)

    /// Лимит disk-кеша; при превышении удаляются самые старые файлы.
    private let maxDiskBytes = 150 * 1024 * 1024
    /// Максимальная сторона декодированной картинки (тумбнейлы чата).
    private static let maxPixelSize = 1600

    private init() {
        let dir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ImageCache", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        cacheDir = dir

        NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil, queue: nil) { [weak self] _ in
            self?.memoryCache.removeAllObjects()
        }

        diskQueue.async { [weak self] in self?.trimDiskCache() }
    }

    // MARK: - Память

    /// Синхронная проверка только memory-кеша — безопасно для main thread.
    func cachedImage(forKey key: String) -> UIImage? {
        memoryCache.object(forKey: key as NSString)
    }

    private func storeInMemory(_ image: UIImage, forKey key: String) {
        memoryCache.setObject(image, forKey: key as NSString, cost: Self.cost(of: image))
    }

    private static func cost(of image: UIImage) -> Int {
        if let cg = image.cgImage {
            return cg.bytesPerRow * cg.height
        }
        let scale = image.scale
        return Int(image.size.width * scale * image.size.height * scale * 4)
    }

    // MARK: - Загрузка

    /// Возвращает токен отмены; `nil` — если картинка отдана синхронно из памяти.
    @discardableResult
    func load(url: String, completion: @escaping (UIImage?) -> Void) -> ImageLoadToken? {
        if let cached = cachedImage(forKey: url) {
            completion(cached)
            return nil
        }

        let token = ImageLoadToken()

        lock.lock()
        if inFlight[url] != nil {
            inFlight[url]?.append((token, completion))
            lock.unlock()
            return token
        }
        inFlight[url] = [(token, completion)]
        lock.unlock()

        diskQueue.async { [weak self] in
            guard let self else { return }

            let file = self.cacheDir.appendingPathComponent(url.sha256ImageName)
            if let data = try? Data(contentsOf: file),
               let image = Self.decodeDownsampled(data: data) {
                // LRU: отмечаем файл как недавно использованный
                try? self.fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: file.path)
                self.storeInMemory(image, forKey: url)
                self.deliver(url: url, image: image)
                return
            }

            guard let requestURL = URL(string: url) else {
                self.deliver(url: url, image: nil)
                return
            }

            let task = URLSession.shared.dataTask(with: requestURL) { [weak self] data, _, _ in
                guard let self, let data, let image = Self.decodeDownsampled(data: data) else {
                    self?.deliver(url: url, image: nil)
                    return
                }
                self.storeInMemory(image, forKey: url)
                self.diskQueue.async { [weak self] in
                    guard let self else { return }
                    try? data.write(to: file, options: .atomic)
                    self.trimDiskCache()
                }
                self.deliver(url: url, image: image)
            }
            task.resume()
        }
        return token
    }

    private func deliver(url: String, image: UIImage?) {
        lock.lock()
        let handlers = inFlight.removeValue(forKey: url) ?? []
        lock.unlock()
        DispatchQueue.main.async {
            for (token, completion) in handlers where token?.isCancelled != true {
                completion(image)
            }
        }
    }

    // MARK: - Декодирование с downsampling

    /// Декодирует с ограничением максимальной стороны — полноразмерные фото
    /// не раздувают память под тумбнейлы чата.
    private static func decodeDownsampled(data: Data) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            return UIImage(data: data)
        }
        let thumbOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOptions) else {
            return UIImage(data: data)
        }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - Очистка disk-кеша

    /// Вызывается на diskQueue. Удаляет самые старые файлы, пока размер
    /// не опустится до 70% лимита.
    private func trimDiskCache() {
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDir, includingPropertiesForKeys: keys, options: .skipsHiddenFiles
        ) else { return }

        var entries: [(url: URL, size: Int, date: Date)] = []
        var total = 0
        for file in files {
            guard let values = try? file.resourceValues(forKeys: Set(keys)) else { continue }
            let size = values.fileSize ?? 0
            total += size
            entries.append((file, size, values.contentModificationDate ?? .distantPast))
        }

        guard total > maxDiskBytes else { return }

        let targetBytes = maxDiskBytes * 7 / 10
        for entry in entries.sorted(by: { $0.date < $1.date }) {
            guard total > targetBytes else { break }
            try? fileManager.removeItem(at: entry.url)
            total -= entry.size
        }
    }
}

// MARK: - SHA256 имя файла

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

// MARK: - Расширение UIImageView

extension UIImageView {
    private static var tokenKey: UInt8 = 0

    func loadChatImage(url: String?, placeholder: UIImage? = nil) {
        cancelImageLoad()
        image = placeholder

        guard let url, !url.isEmpty else { return }

        if let cached = ImageCache.shared.cachedImage(forKey: url) {
            image = cached
            return
        }

        let token = ImageCache.shared.load(url: url) { [weak self] loaded in
            guard let self else { return }
            if let loaded {
                UIView.transition(with: self, duration: 0.15, options: .transitionCrossDissolve) {
                    self.image = loaded
                }
            }
        }
        objc_setAssociatedObject(self, &Self.tokenKey, token, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func cancelImageLoad() {
        (objc_getAssociatedObject(self, &Self.tokenKey) as? ImageLoadToken)?.cancel()
        objc_setAssociatedObject(self, &Self.tokenKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
