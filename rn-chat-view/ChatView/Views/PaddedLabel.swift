import UIKit

final class PaddedLabel: UILabel {
    private let hPad: CGFloat
    init(hPad: CGFloat) { self.hPad = hPad; super.init(frame: .zero) }
    required init?(coder: NSCoder) { fatalError() }
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + hPad * 2, height: size.height)
    }
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.insetBy(dx: hPad, dy: 0))
    }
}
