import UIKit
import QuartzCore

/// Animates a view "disintegrating" into a cloud of tiny confetti-like particles
/// that scatter, spin, and drift downward.
///
/// Performance: uses `CAEmitterLayer` — a single GPU-native particle system.
/// Zero per-particle CALayer or CAAnimation objects. The render server handles
/// all particle physics, drawing, and compositing on the GPU.
public final class DisintegrationAnimator {

    /// Configuration for the disintegration effect.
    public struct Config {
        /// Size of each color sample region (points). Controls color diversity.
        /// Smaller = more color samples = more emitter cells (still very fast).
        public var sampleGridSize: CGFloat = 20
        /// Number of particles per emitter cell (per color region).
        public var particlesPerCell: Int = 80
        /// Particle lifetime in seconds.
        public var lifetime: Float = 1.2
        /// Particle size in points.
        public var particleSize: CGFloat = 1
        /// Particle size randomization range.
        public var particleSizeRange: CGFloat = 0.7
        /// Maximum scatter velocity (points/sec).
        public var velocity: CGFloat = 200
        /// Gravity pull (positive = down).
        public var gravity: CGFloat = 300
        /// Spin speed (radians/sec).
        public var spin: CGFloat = 8
        /// Burst duration — how long the emitter fires (seconds).
        /// After this, emission stops and existing particles fade out.
        public var burstDuration: TimeInterval = 0.15

        public static let `default` = Config()

        public init() {}
    }

    public enum WaveDirection {
        case leadingToTrailing
        case trailingToLeading
    }

    // MARK: - Shared tiny square image (1×1 white pixel, created once)

    private static let pixelImage: CGImage = {
        let size = 4 // 4×4 for better anti-aliasing
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

    // MARK: - Public API

    /// Disintegrate a view into confetti-like particles.
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

        // 1. Snapshot
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let snapshot = renderer.image { ctx in
            view.layer.render(in: ctx.cgContext)
        }
        guard let cgImage = snapshot.cgImage else {
            completion?()
            return
        }

        let frameInContainer = view.convert(bounds, to: container)

        // Hide immediately
        view.isHidden = true

        // 2. Sample colors on background thread
        let scale = snapshot.scale
        let gridSize = config.sampleGridSize
        let imgW = cgImage.width
        let imgH = cgImage.height

        DispatchQueue.global(qos: .userInteractive).async {
            // Read pixel data once
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
                    // Sample center of each grid cell
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

                    // Skip fully transparent regions
                    guard a > 0.02 else { continue }

                    // Premultiplied alpha → восстановить реальный цвет
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

            // 3. Build emitter on main thread
            DispatchQueue.main.async {
                let emitterLayer = CAEmitterLayer()
                emitterLayer.frame = CGRect(origin: .zero, size: frameInContainer.size)
                emitterLayer.emitterShape = .point
                emitterLayer.renderMode = .additive
                emitterLayer.beginTime = CACurrentMediaTime()

                // Create one emitter cell per color sample
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

                    // Scatter in all directions
                    cell.velocity = config.velocity
                    cell.velocityRange = config.velocity * 0.5
                    cell.emissionRange = .pi * 2

                    // Gravity
                    cell.yAcceleration = config.gravity

                    // Spin
                    cell.spin = config.spin
                    cell.spinRange = config.spin

                    // Size
                    cell.scale = config.particleSize / 4.0 // pixelImage is 4×4
                    cell.scaleRange = config.particleSizeRange / 4.0
                    cell.scaleSpeed = -config.particleSize / (4.0 * CGFloat(config.lifetime))

                    // Fade out
                    cell.alphaSpeed = -1.0 / config.lifetime

                    // Emit from this cell's grid position
                    cell.emitterCells = nil

                    emitterCells.append(cell)
                }

                // Use sub-emitters per position by creating point emitters
                // Instead, use multiple emitter layers for position control
                // OR: single emitter with rectangle shape + random emission

                // Approach: one CAEmitterLayer per grid cell is too many layers.
                // Better: single layer, rectangle shape, all cells emit from same area.
                // Trade-off: particles don't start from exact grid positions, but from
                // random positions within the view bounds. Looks organic.

                emitterLayer.emitterPosition = CGPoint(
                    x: frameInContainer.width / 2,
                    y: frameInContainer.height / 2
                )
                emitterLayer.emitterSize = frameInContainer.size
                emitterLayer.emitterShape = .rectangle
                emitterLayer.emitterCells = emitterCells

                // Add to container as an overlay at the view's position
                let overlay = UIView(frame: frameInContainer)
                overlay.backgroundColor = .clear
                overlay.isUserInteractionEnabled = false
                overlay.layer.addSublayer(emitterLayer)
                container.addSubview(overlay)

                // Stop emission after burst, let particles finish their lifetime
                let burstDuration = config.burstDuration
                let totalDuration = burstDuration + Double(config.lifetime + config.lifetime * 0.4)

                DispatchQueue.main.asyncAfter(deadline: .now() + burstDuration) {
                    // Stop emitting new particles
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
