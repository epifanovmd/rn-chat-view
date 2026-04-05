import UIKit

public final class PaddedLabel: UILabel {
    private let hPad: CGFloat
    init(hPad: CGFloat) { self.hPad = hPad; super.init(frame: .zero) }
    public required init?(coder: NSCoder) { fatalError() }
    public override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + hPad * 2, height: size.height)
    }
    public override func drawText(in rect: CGRect) {
        super.drawText(in: rect.insetBy(dx: hPad, dy: 0))
    }
}
