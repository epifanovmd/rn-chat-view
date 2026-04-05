import UIKit

/// Factory protocol for creating all customizable views inside a message bubble.
/// Override any method to replace the default view with a custom implementation.
public protocol ChatContentFactory: AnyObject {

    // MARK: - Media Content

    /// Create a view for the media portion of a message (images, voice, poll, files).
    func contentView(
        for media: MessageMedia,
        message: ChatMessage,
        width: CGFloat,
        theme: ChatTheme,
        layout: ChatLayout,
        onInteraction: @escaping (ChatContentInteraction) -> Void
    ) -> UIView

    /// Calculate the height of the media content for size calculations.
    func contentHeight(
        for media: MessageMedia,
        width: CGFloat,
        layout: ChatLayout
    ) -> CGFloat

    // MARK: - Text

    /// Create a view for the text portion of a message.
    func textView(
        text: String,
        isMine: Bool,
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView

    /// Calculate text height for size calculations.
    func textHeight(
        text: String,
        font: UIFont,
        width: CGFloat
    ) -> CGFloat

    // MARK: - Emoji-only

    /// Create a view for emoji-only messages (1-3 emojis, no background bubble).
    func emojiView(
        text: String,
        emojiCount: Int,
        layout: ChatLayout
    ) -> UIView

    // MARK: - Reactions

    /// Create the reactions bar below a message.
    func reactionsView(
        reactions: [Reaction],
        theme: ChatTheme,
        maxWidth: CGFloat,
        layout: ChatLayout,
        onTap: @escaping (String) -> Void
    ) -> UIView

    // MARK: - Reply Preview

    /// Create the reply preview inside a message bubble.
    func replyPreviewView(
        reply: ReplyInfo,
        resolved: ReplyDisplayInfo?,
        isMine: Bool,
        theme: ChatTheme,
        layout: ChatLayout,
        onTap: @escaping () -> Void
    ) -> UIView

    // MARK: - Footer

    /// Create the footer (time, edited mark, status icon). Return nil to hide.
    func footerView(
        message: ChatMessage,
        theme: ChatTheme,
        layout: ChatLayout,
        features: ChatFeatures
    ) -> UIView?

    // MARK: - Sender Name

    /// Create the sender name label. Return nil to hide.
    func senderNameView(
        name: String,
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView

    // MARK: - Forwarded Header

    /// Create the forwarded message header label. Return nil to hide.
    func forwardedHeaderView(
        from: String,
        isMine: Bool,
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView

    // MARK: - Date Separator

    /// Create the date separator cell content (e.g. "Today", "Yesterday").
    func dateSeparatorView(
        title: String,
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView

    /// Calculate the height of the date separator.
    func dateSeparatorHeight(layout: ChatLayout) -> CGFloat

    // MARK: - Floating Date

    /// Create the floating date pill shown during scrolling.
    func floatingDateView(
        title: String,
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView
}
