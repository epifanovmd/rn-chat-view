import UIKit
import QuartzCore

// CAEmitterLayer — единая GPU-нативная система частиц, без per-particle объектов
public final class DisintegrationAnimator {

    public struct Config {
        public var sampleGridSize: CGFloat = 20
        public var particlesPerCell: Int = 80
        public var lifetime: Float = 1.2
        public var particleSize: CGFloat = 1
        public var particleSizeRange: CGFloat = 0.7
        public var velocity: CGFloat = 200
        public var gravity: CGFloat = 300
        public var spin: CGFloat = 8
        public var burstDuration: TimeInterval = 0.15

        public static let `default` = Config()

        public init() {}
    }

    public enum WaveDirection {
        case leadingToTrailing
        case trailingToLeading
    }

    // MARK: - Белый пиксель (4×4, создаётся один раз)

    private static let pixelImage: CGImage = {
        let size = 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let ctx = CGContext(
            data: nil, width: size, height: size,
            bitsPerComponent: 8, bytesPerRow: size * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
        return ctx.makeImage()!
    }()

    // MARK: - Публичное API

    static func disintegrate(
        view: UIView,
        in container: UIView,
        config: Config = .default,
        completion: (() -> Void)? = nil
    ) {
        let bounds = view.bounds
        guard bounds.width > 0, bounds.height > 0 else {
            completion?()
            return
        }

        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let snapshot = renderer.image { ctx in
            view.layer.render(in: ctx.cgContext)
        }
        guard let cgImage = snapshot.cgImage else {
            completion?()
            return
        }

        let frameInContainer = view.convert(bounds, to: container)

        view.isHidden = true

        let scale = snapshot.scale
        let gridSize = config.sampleGridSize
        let imgW = cgImage.width
        let imgH = cgImage.height

        DispatchQueue.global(qos: .userInteractive).async {
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            guard let ctx = CGContext(
                data: nil, width: imgW, height: imgH,
                bitsPerComponent: 8, bytesPerRow: imgW * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                DispatchQueue.main.async { completion?() }
                return
            }
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: imgW, height: imgH))

            guard let pixelData = ctx.data else {
                DispatchQueue.main.async { completion?() }
                return
            }

            let bytesPerRow = ctx.bytesPerRow
            let cols = max(1, Int(ceil(bounds.width / gridSize)))
            let rows = max(1, Int(ceil(bounds.height / gridSize)))

            struct CellInfo {
                let color: UIColor
                let position: CGPoint  // relative to emitter bounds
            }

            var cells: [CellInfo] = []
            cells.reserveCapacity(cols * rows)

            for row in 0..<rows {
                for col in 0..<cols {
                    let ptX = (CGFloat(col) + 0.5) * gridSize
                    let ptY = (CGFloat(row) + 0.5) * gridSize
                    let px = min(Int(ptX * scale), imgW - 1)
                    let py = min(Int(ptY * scale), imgH - 1)

                    let offset = py * bytesPerRow + px * 4
                    let ptr = pixelData.advanced(by: offset).assumingMemoryBound(to: UInt8.self)
                    let r = CGFloat(ptr[0]) / 255.0
                    let g = CGFloat(ptr[1]) / 255.0
                    let b = CGFloat(ptr[2]) / 255.0
                    let a = CGFloat(ptr[3]) / 255.0

                    guard a > 0.02 else { continue }

                    // Premultiplied alpha → un-premultiply для корректных цветов частиц
                    let realR = a > 0.01 ? min(r / a, 1.0) : r
                    let realG = a > 0.01 ? min(g / a, 1.0) : g
                    let realB = a > 0.01 ? min(b / a, 1.0) : b
                    let color = UIColor(red: realR, green: realG, blue: realB, alpha: max(a, 0.35))
                    let position = CGPoint(x: ptX, y: ptY)
                    cells.append(CellInfo(color: color, position: position))
                }
            }

            guard !cells.isEmpty else {
                DispatchQueue.main.async { completion?() }
                return
            }

            DispatchQueue.main.async {
                let emitterLayer = CAEmitterLayer()
                emitterLayer.frame = CGRect(origin: .zero, size: frameInContainer.size)
                emitterLayer.emitterShape = .point
                emitterLayer.renderMode = .additive
                emitterLayer.beginTime = CACurrentMediaTime()

                var emitterCells: [CAEmitterCell] = []
                emitterCells.reserveCapacity(cells.count)

                let pxImage = DisintegrationAnimator.pixelImage

                for info in cells {
                    let cell = CAEmitterCell()
                    cell.contents = pxImage
                    cell.color = info.color.cgColor
                    cell.birthRate = Float(config.particlesPerCell) / Float(config.burstDuration)
                    cell.lifetime = config.lifetime
                    cell.lifetimeRange = config.lifetime * 0.4
                    cell.velocity = config.velocity
                    cell.velocityRange = config.velocity * 0.5
                    cell.emissionRange = .pi * 2
                    cell.yAcceleration = config.gravity
                    cell.spin = config.spin
                    cell.spinRange = config.spin
                    cell.scale = config.particleSize / 4.0
                    cell.scaleRange = config.particleSizeRange / 4.0
                    cell.scaleSpeed = -config.particleSize / (4.0 * CGFloat(config.lifetime))
                    cell.alphaSpeed = -1.0 / config.lifetime
                    cell.emitterCells = nil

                    emitterCells.append(cell)
                }

                // Один rectangle emitter вместо per-cell: частицы стартуют из случайных
                // позиций внутри bounds, а не из точных grid-позиций — выглядит органично
                emitterLayer.emitterPosition = CGPoint(
                    x: frameInContainer.width / 2,
                    y: frameInContainer.height / 2
                )
                emitterLayer.emitterSize = frameInContainer.size
                emitterLayer.emitterShape = .rectangle
                emitterLayer.emitterCells = emitterCells

                let overlay = UIView(frame: frameInContainer)
                overlay.backgroundColor = .clear
                overlay.isUserInteractionEnabled = false
                overlay.layer.addSublayer(emitterLayer)
                container.addSubview(overlay)

                let burstDuration = config.burstDuration
                let totalDuration = burstDuration + Double(config.lifetime + config.lifetime * 0.4)

                DispatchQueue.main.asyncAfter(deadline: .now() + burstDuration) {
                    emitterLayer.birthRate = 0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
                    overlay.removeFromSuperview()
                    completion?()
                }
            }
        }
    }
}
