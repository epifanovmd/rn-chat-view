import UIKit

/// Общий помощник спиннера-кольца (дуга 3/4 окружности с вращением) —
/// используется FAB-кнопкой и голосовым сообщением.
enum LoadingRing {

    /// Настраивает слой как кольцо-дугу заданного размера.
    static func configure(_ ring: CAShapeLayer, size: CGFloat, inset: CGFloat = 4, lineWidth: CGFloat = 2) {
        let radius = size / 2 - inset
        ring.frame = CGRect(x: 0, y: 0, width: size, height: size)
        ring.path = UIBezierPath(
            arcCenter: CGPoint(x: size / 2, y: size / 2),
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: .pi * 1.5,
            clockwise: true
        ).cgPath
        ring.fillColor = UIColor.clear.cgColor
        ring.lineWidth = lineWidth
        ring.lineCap = .round
        ring.strokeStart = 0
        ring.strokeEnd = 0.75
    }

    static func startSpinning(_ ring: CALayer, duration: CFTimeInterval = 0.8) {
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = CGFloat.pi * 2
        rotation.duration = duration
        rotation.repeatCount = .infinity
        rotation.isRemovedOnCompletion = false
        ring.add(rotation, forKey: "spin")
    }

    static func stopSpinning(_ ring: CALayer) {
        ring.removeAnimation(forKey: "spin")
    }
}
