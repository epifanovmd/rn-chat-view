import UIKit

/// Text measurement utilities for calculating content sizes.
/// Available for host app use in custom ChatContentFactory implementations.
enum ChatTextMeasurer {

    /// Calculate the height of multi-line text within a given width.
    static func height(_ text: String, font: UIFont, width: CGFloat) -> CGFloat {
        let size = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        ).size
        return ceil(size.height)
    }

    /// Calculate the single-line width of text.
    static func width(_ text: String, font: UIFont) -> CGFloat {
        let size = (text as NSString).boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: font.lineHeight),
            options: [.usesLineFragmentOrigin],
            attributes: [.font: font],
            context: nil
        ).size
        return ceil(size.width)
    }

    /// Returns the appropriate emoji font for 1, 2, or 3 emoji messages.
    static func emojiFont(for count: Int, layout: ChatLayout) -> UIFont {
        switch count {
        case 1: return layout.emojiFont1
        case 2: return layout.emojiFont2
        default: return layout.emojiFont3
        }
    }
}
