import UIKit

/// Factory protocol responsible for creating every customizable view in the chat.
///
/// The library core is agnostic to concrete content types — it delegates all
/// view creation and sizing to this factory. Assign an instance to
/// `ChatViewController.contentFactory` to control the entire visual appearance.
///
/// `DefaultChatContentFactory` provides a ready-to-use implementation that handles
/// the built-in content types (images, voice, poll, files). You can:
/// - Use it as-is for standard chat functionality.
/// - Subclass it and override specific methods to customize individual elements.
/// - Implement the protocol from scratch for a fully custom chat UI.
public protocol ChatContentFactory: AnyObject {

    // MARK: - Content

    /// Creates the view that renders the main content area of a message
    /// (e.g., image grid, voice waveform, poll, file list, or any custom type).
    ///
    /// The library passes an opaque `AnyChatContent` — unwrap it with
    /// `media.content(as: YourType.self)` to access the typed payload.
    ///
    /// - Parameters:
    ///   - media: Type-erased content payload. Use `content(as:)` to unwrap.
    ///   - message: The full message (for accessing `isMine`, `id`, etc.).
    ///   - width: Available width inside the bubble (after horizontal padding).
    ///   - theme: Current color theme.
    ///   - layout: Current sizing/spacing parameters.
    ///   - onInteraction: Callback to fire when the user interacts with the content
    ///     (tap, vote, play, etc.). The library routes it to
    ///     `chatDidContentInteraction(messageId:interaction:)` on the delegate.
    /// - Returns: A configured `UIView` ready to be inserted into the bubble stack.
    func contentView(
        for media: AnyChatContent,
        message: ChatMessage,
        width: CGFloat,
        theme: ChatTheme,
        layout: ChatLayout,
        onInteraction: @escaping (ChatContentInteraction) -> Void
    ) -> UIView

    /// Returns the pre-calculated height of the content view for layout purposes.
    ///
    /// Called during the layout pass before cells are displayed. Must return the
    /// exact same height that the view from `contentView(for:...)` will occupy.
    ///
    /// - Parameters:
    ///   - media: Type-erased content payload.
    ///   - width: Available width inside the bubble.
    ///   - layout: Current sizing/spacing parameters.
    /// - Returns: Height in points.
    func contentHeight(
        for media: AnyChatContent,
        width: CGFloat,
        layout: ChatLayout
    ) -> CGFloat

    /// Reconfigures an existing content view in-place when message data changes.
    ///
    /// Called instead of destroying and recreating the view during content-only
    /// updates (e.g., poll vote changes, status updates). Enables smooth animations
    /// because the view hierarchy is preserved.
    ///
    /// - Parameters:
    ///   - view: The existing content view previously returned by `contentView(for:...)`.
    ///   - media: The updated content payload.
    ///   - message: The updated message.
    ///   - width: Available width inside the bubble.
    ///   - theme: Current color theme.
    ///   - layout: Current sizing/spacing parameters.
    ///   - onInteraction: Updated interaction callback (must replace any closures
    ///     captured by the previous configuration).
    /// - Returns: `true` if the view was successfully reconfigured in-place;
    ///   `false` to fall back to a full view rebuild via `contentView(for:...)`.
    func reconfigureContentView(
        _ view: UIView,
        for media: AnyChatContent,
        message: ChatMessage,
        width: CGFloat,
        theme: ChatTheme,
        layout: ChatLayout,
        onInteraction: @escaping (ChatContentInteraction) -> Void
    ) -> Bool

    // MARK: - Text

    /// Creates the view that renders the text portion of a message.
    ///
    /// Used for standalone text messages and as the caption below media content.
    /// The returned view is placed inside the bubble stack.
    ///
    /// - Parameters:
    ///   - text: Message text string.
    ///   - isMine: `true` for outgoing messages (affects text color).
    ///   - theme: Current color theme.
    ///   - layout: Current sizing/spacing parameters (font, etc.).
    /// - Returns: A configured text view.
    func textView(
        text: String,
        isMine: Bool,
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView

    /// Returns the pre-calculated height of a text block for layout purposes.
    ///
    /// - Parameters:
    ///   - text: Message text string.
    ///   - font: The font used for rendering (from `ChatLayout.messageFont`).
    ///   - width: Available width for the text.
    /// - Returns: Height in points.
    func textHeight(
        text: String,
        font: UIFont,
        width: CGFloat
    ) -> CGFloat

    // MARK: - Emoji

    /// Creates the view for emoji-only messages (1–3 emojis displayed without a bubble background).
    ///
    /// - Parameters:
    ///   - text: The emoji string (e.g., "😂🔥").
    ///   - emojiCount: Number of emojis (1–3), determines font size.
    ///   - layout: Current sizing/spacing parameters.
    /// - Returns: A view displaying the emojis at an appropriate size.
    func emojiView(
        text: String,
        emojiCount: Int,
        layout: ChatLayout
    ) -> UIView

    // MARK: - Reactions

    /// Creates the reaction bar displayed below the message content.
    ///
    /// Shows emoji chips with counts (e.g., "👍 3", "❤️ 1"). Chips wrap to
    /// multiple lines if they exceed `maxWidth`.
    ///
    /// - Parameters:
    ///   - reactions: Array of reactions with emoji, count, and whether the current user reacted.
    ///   - theme: Current color theme.
    ///   - maxWidth: Maximum width before wrapping to the next line.
    ///   - layout: Current sizing/spacing parameters.
    ///   - onTap: Callback fired when the user taps a reaction chip, passing the emoji string.
    /// - Returns: A configured reactions view.
    func reactionsView(
        reactions: [Reaction],
        theme: ChatTheme,
        maxWidth: CGFloat,
        layout: ChatLayout,
        onTap: @escaping (String) -> Void
    ) -> UIView

    // MARK: - Reply Preview

    /// Creates the quoted message preview shown inside the bubble when replying.
    ///
    /// Displayed as a compact bar with an accent stripe, sender name, and text snippet.
    ///
    /// - Parameters:
    ///   - reply: Basic reply info from the message model (replyToId, sender, text).
    ///   - resolved: Full display info resolved from the original message (may be nil if the
    ///     original message is not in the current data set).
    ///   - isMine: `true` for outgoing messages (affects colors).
    ///   - theme: Current color theme.
    ///   - layout: Current sizing/spacing parameters.
    ///   - onTap: Callback fired when the user taps the reply preview (typically scrolls to the original message).
    /// - Returns: A configured reply preview view.
    func replyPreviewView(
        reply: ReplyInfo,
        resolved: ReplyDisplayInfo?,
        isMine: Bool,
        theme: ChatTheme,
        layout: ChatLayout,
        onTap: @escaping () -> Void
    ) -> UIView

    // MARK: - Footer

    /// Creates the footer row at the bottom of the bubble (timestamp, "edited" mark, delivery status icon).
    ///
    /// Return `nil` to hide the footer entirely (e.g., when all footer features are disabled).
    /// The footer is right-aligned inside the bubble.
    ///
    /// - Parameters:
    ///   - message: The full message (for timestamp, status, isEdited).
    ///   - theme: Current color theme.
    ///   - layout: Current sizing/spacing parameters.
    ///   - features: Feature flags controlling which footer elements are visible.
    /// - Returns: A configured footer view, or `nil` to hide it.
    func footerView(
        message: ChatMessage,
        theme: ChatTheme,
        layout: ChatLayout,
        features: ChatFeatures
    ) -> UIView?

    // MARK: - Sender Name

    /// Creates the sender name label shown at the top of incoming message bubbles.
    ///
    /// Displayed when `features.senderNameMode` is `.incomingOnly` or `.always`.
    ///
    /// - Parameters:
    ///   - name: The sender's display name.
    ///   - theme: Current color theme.
    ///   - layout: Current sizing/spacing parameters.
    /// - Returns: A configured sender name view.
    func senderNameView(
        name: String,
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView

    // MARK: - Forwarded Header

    /// Creates the "Forwarded from ..." header shown above forwarded message content.
    ///
    /// Displayed inside the bubble, above the reply preview and content.
    ///
    /// - Parameters:
    ///   - from: The name of the original sender.
    ///   - isMine: `true` for outgoing messages (affects colors).
    ///   - theme: Current color theme.
    ///   - layout: Current sizing/spacing parameters.
    /// - Returns: A configured forwarded header view.
    func forwardedHeaderView(
        from: String,
        isMine: Bool,
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView

    // MARK: - Date Separator

    /// Creates the date separator row displayed between message groups from different days
    /// (e.g., "Today", "Yesterday", "March 15").
    ///
    /// Rendered as a standalone cell in the collection view, not inside a message bubble.
    ///
    /// - Parameters:
    ///   - title: Formatted date string.
    ///   - theme: Current color theme.
    ///   - layout: Current sizing/spacing parameters.
    /// - Returns: A configured date separator view (typically a centered pill with text).
    func dateSeparatorView(
        title: String,
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView

    /// Returns the fixed height of the date separator cell for layout purposes.
    ///
    /// - Parameter layout: Current sizing/spacing parameters.
    /// - Returns: Height in points.
    func dateSeparatorHeight(layout: ChatLayout) -> CGFloat

    // MARK: - Floating Date

    /// Creates the floating date pill that appears at the top of the screen while scrolling.
    ///
    /// Shown temporarily to indicate which date the user is currently viewing.
    /// By default reuses `dateSeparatorView`, but can be overridden for a different appearance.
    ///
    /// - Parameters:
    ///   - title: Formatted date string.
    ///   - theme: Current color theme.
    ///   - layout: Current sizing/spacing parameters.
    /// - Returns: A configured floating date view.
    func floatingDateView(
        title: String,
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView

    // MARK: - Empty State

    /// Creates the placeholder view shown when the message list is empty and not loading.
    ///
    /// Centered vertically in the available space between the top of the chat area
    /// and the input bar. Typically displays a message like "No messages yet".
    ///
    /// - Parameters:
    ///   - theme: Current color theme.
    ///   - layout: Current sizing/spacing parameters.
    /// - Returns: A configured empty state view.
    func emptyStateView(
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView

    /// Creates the loading indicator shown in the empty state while initial messages are loading.
    ///
    /// Replaces the empty state text view while `isLoading` is `true` and the message list is empty.
    /// Centered at the same position as the empty state view.
    ///
    /// - Parameters:
    ///   - theme: Current color theme.
    ///   - layout: Current sizing/spacing parameters.
    /// - Returns: A configured loading view (typically a spinner).
    func emptyStateLoadingView(
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView

    // MARK: - Loading Indicator

    /// Creates the loading indicator shown inside the pagination loading cell.
    ///
    /// Displayed at the top or bottom of the message list while older/newer messages
    /// are being loaded. Centered inside the loading cell.
    ///
    /// - Parameters:
    ///   - theme: Current color theme.
    ///   - layout: Current sizing/spacing parameters.
    /// - Returns: A configured loading indicator view (typically a spinner).
    func loadingIndicatorView(
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView

    // MARK: - Floating Action Button

    /// Creates the scroll-to-bottom floating action button (FAB).
    ///
    /// Positioned at the bottom-right corner above the input bar. Appears when the user
    /// scrolls away from the bottom. If the returned view is a `UIButton`, its
    /// `.touchUpInside` event is used; otherwise a tap gesture is added automatically.
    ///
    /// The library manages visibility, position animation, and sizing constraints
    /// externally — the factory only creates the visual appearance.
    ///
    /// - Parameters:
    ///   - theme: Current color theme.
    ///   - layout: Current sizing/spacing parameters.
    /// - Returns: A configured FAB view.
    func fabView(
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView

    /// Creates the unread message count badge displayed on the FAB.
    ///
    /// Positioned at the top-left corner of the FAB button. If the returned view
    /// is a `UILabel`, its `text` property is updated with the unread count
    /// (e.g., "3", "99+"). Hidden when the count is zero.
    ///
    /// - Parameters:
    ///   - theme: Current color theme.
    ///   - layout: Current sizing/spacing parameters.
    /// - Returns: A configured badge view.
    func fabBadgeView(
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView
}
