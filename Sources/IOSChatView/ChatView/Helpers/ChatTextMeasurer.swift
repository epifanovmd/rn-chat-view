import UIKit

/// Утилиты измерения текста для расчёта размеров контента.
public enum ChatTextMeasurer {

    public static func height(_ text: String, font: UIFont, width: CGFloat) -> CGFloat {
        let size = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        ).size
        return ceil(size.height)
    }

    public static func width(_ text: String, font: UIFont) -> CGFloat {
        let size = (text as NSString).boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: font.lineHeight),
            options: [.usesLineFragmentOrigin],
            attributes: [.font: font],
            context: nil
        ).size
        return ceil(size.width)
    }

    public static func emojiFont(for count: Int, layout: ChatLayout) -> UIFont {
        switch count {
        case 1: return layout.emojiFont1
        case 2: return layout.emojiFont2
        default: return layout.emojiFont3
        }
    }
}
