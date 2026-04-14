import UIKit

/// Animates a view "disintegrating" into a cloud of tiny confetti-like particles
/// that scatter, spin, and drift downward.
///
/// Usage:
/// ```swift
/// DisintegrationAnimator.disintegrate(view: someView, in: containerView) {
///     // cleanup after animation
/// }
/// ```
public final class DisintegrationAnimator {

    /// Configuration for the disintegration effect.
    public struct Config {
        /// Size of each particle tile in points.
        public var tileSize: CGFloat = 2
        /// Fraction of tiles to actually emit (0..1). Keeps particle count manageable
        /// when tileSize is very small. 1.0 = every tile, 0.4 = ~40% random sample.
        public var density: CGFloat = 0.45
        /// Total animation duration in seconds.
        public var duration: TimeInterval = 1.2
        /// Maximum horizontal scatter distance (points).
        public var maxScatterX: CGFloat = 160
        /// Maximum upward scatter (negative Y = up).
        public var maxScatterUp: CGFloat = 80
        /// Maximum downward scatter (positive Y = down, gravity bias).
        public var maxScatterDown: CGFloat = 200
        /// Maximum rotation angle (radians).
        public var maxRotation: CGFloat = .pi * 3
        /// Delay spread — particles at the trailing edge start later (seconds).
        public var delaySpread: TimeInterval = 0.35
        /// Direction of the dissolve wave.
        public var waveDirection: WaveDirection = .trailingToLeading

        public static let `default` = Config()

        public init() {}
    }

    public enum WaveDirection {
        /// Wave moves left → right (left particles fly first).
        case leadingToTrailing
        /// Wave moves right → left (right particles fly first).
        case trailingToLeading
    }

    // MARK: - Public API

    /// Disintegrate a view into confetti-like particles.
    ///
    /// - Parameters:
    ///   - view: The source view to disintegrate. It will be hidden during animation.
    ///   - container: The superview where particles are placed.
    ///   - config: Animation configuration.
    ///   - completion: Called when animation finishes and particles are removed.
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

        // 1. Rasterize the view
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let snapshot = renderer.image { ctx in
            view.layer.render(in: ctx.cgContext)
        }

        guard let cgImage = snapshot.cgImage else {
            completion?()
            return
        }

        let tileSize = config.tileSize
        let scale = snapshot.scale
        let cols = Int(ceil(bounds.width / tileSize))
        let rows = Int(ceil(bounds.height / tileSize))

        guard cols > 0, rows > 0 else {
            completion?()
            return
        }

        // 2. Create particle container at the view's position in the container
        let frameInContainer = view.convert(bounds, to: container)
        // Expand the container so particles can fly outside the original bounds
        let overflow: CGFloat = max(config.maxScatterX, config.maxScatterDown) + 40
        let expandedFrame = frameInContainer.insetBy(dx: -overflow, dy: -overflow)
        let particleContainer = UIView(frame: expandedFrame)
        particleContainer.backgroundColor = .clear
        particleContainer.isUserInteractionEnabled = false
        particleContainer.clipsToBounds = false
        container.addSubview(particleContainer)

        // Offset so that tile origins are relative to the original view position
        let originOffset = CGPoint(
            x: frameInContainer.minX - expandedFrame.minX,
            y: frameInContainer.minY - expandedFrame.minY
        )

        // 3. Hide the original view
        view.isHidden = true

        // 4. Create particle layers with density sampling
        let imgWidth = CGFloat(cgImage.width)
        let imgHeight = CGFloat(cgImage.height)

        var particleLayers: [(layer: CALayer, col: Int, row: Int)] = []
        let estimatedCount = Int(CGFloat(cols * rows) * min(config.density, 1.0))
        particleLayers.reserveCapacity(estimatedCount)

        for row in 0..<rows {
            for col in 0..<cols {
                // Density sampling — skip random tiles
                if config.density < 1.0 && CGFloat.random(in: 0...1) > config.density {
                    continue
                }

                let x = CGFloat(col) * tileSize
                let y = CGFloat(row) * tileSize
                let w = min(tileSize, bounds.width - x)
                let h = min(tileSize, bounds.height - y)

                let cropRect = CGRect(
                    x: x * scale, y: y * scale,
                    width: w * scale, height: h * scale
                ).intersection(CGRect(x: 0, y: 0, width: imgWidth, height: imgHeight))

                guard cropRect.width > 0, cropRect.height > 0,
                      let tileCG = cgImage.cropping(to: cropRect) else { continue }

                let layer = CALayer()
                layer.frame = CGRect(x: originOffset.x + x, y: originOffset.y + y, width: w, height: h)
                layer.contents = tileCG
                layer.contentsScale = scale
                particleContainer.layer.addSublayer(layer)
                particleLayers.append((layer, col, row))
            }
        }

        guard !particleLayers.isEmpty else {
            particleContainer.removeFromSuperview()
            completion?()
            return
        }

        // 5. Animate particles
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            particleContainer.removeFromSuperview()
            completion?()
        }

        let maxCol = CGFloat(max(cols - 1, 1))
        let maxRow = CGFloat(max(rows - 1, 1))

        for (layer, col, row) in particleLayers {
            // Wave delay
            let normalizedCol: CGFloat
            switch config.waveDirection {
            case .leadingToTrailing:
                normalizedCol = CGFloat(col) / maxCol
            case .trailingToLeading:
                normalizedCol = 1.0 - CGFloat(col) / maxCol
            }
            let normalizedRow = CGFloat(row) / maxRow
            let delay = (normalizedCol * 0.7 + normalizedRow * 0.3) * config.delaySpread
                + Double.random(in: 0...0.08) // jitter for organic feel

            // Scatter with gravity bias (more down than up)
            let scatterX = CGFloat.random(in: -config.maxScatterX...config.maxScatterX)
            let scatterY = CGFloat.random(in: -config.maxScatterUp...config.maxScatterDown)

            let rotation = CGFloat.random(in: -config.maxRotation...config.maxRotation)
            let particleDuration = config.duration * Double.random(in: 0.5...1.0)

            // Confetti-like 3D flip on random axis
            let flipAxis: String = Bool.random() ? "transform.rotation.x" : "transform.rotation.y"

            // Position — use keyframe for a slight arc (gravity feel)
            let posAnim = CAKeyframeAnimation(keyPath: "position")
            let startPos = layer.position
            let endPos = CGPoint(x: startPos.x + scatterX, y: startPos.y + scatterY)
            let midPos = CGPoint(
                x: startPos.x + scatterX * 0.5,
                y: startPos.y + min(scatterY * 0.2, -10) // slight upward arc first
            )
            posAnim.values = [
                NSValue(cgPoint: startPos),
                NSValue(cgPoint: midPos),
                NSValue(cgPoint: endPos)
            ]
            posAnim.keyTimes = [0, 0.3, 1.0]
            posAnim.timingFunctions = [
                CAMediaTimingFunction(name: .easeOut),
                CAMediaTimingFunction(name: .easeIn)
            ]

            // Opacity — stay visible longer, then fade fast
            let opacityAnim = CAKeyframeAnimation(keyPath: "opacity")
            opacityAnim.values = [1.0, 1.0, 0.6, 0.0]
            opacityAnim.keyTimes = [0, 0.3, 0.7, 1.0]

            // Z rotation (spin)
            let rotAnim = CABasicAnimation(keyPath: "transform.rotation.z")
            rotAnim.fromValue = 0
            rotAnim.toValue = rotation

            // 3D flip for confetti tumble
            let flipAnim = CABasicAnimation(keyPath: flipAxis)
            flipAnim.fromValue = 0
            flipAnim.toValue = CGFloat.random(in: -(.pi * 4)...(.pi * 4))

            // Scale — slight shrink
            let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
            scaleAnim.fromValue = 1.0
            scaleAnim.toValue = CGFloat.random(in: 0.1...0.5)
            scaleAnim.timingFunction = CAMediaTimingFunction(name: .easeIn)

            let group = CAAnimationGroup()
            group.animations = [posAnim, opacityAnim, rotAnim, flipAnim, scaleAnim]
            group.duration = particleDuration
            group.beginTime = CACurrentMediaTime() + delay
            group.fillMode = .forwards
            group.isRemovedOnCompletion = false

            layer.add(group, forKey: "disintegrate")
            layer.opacity = 0
        }

        CATransaction.commit()
    }
}
