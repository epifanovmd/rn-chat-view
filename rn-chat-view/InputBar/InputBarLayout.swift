import UIKit

/// Layout constants for the InputBar module.
struct InputBarLayout {

    // MARK: - Bar

    /// Vertical padding of the input bar
    var barVPad: CGFloat = 8
    /// Horizontal padding of the input bar
    var barHPad: CGFloat = 12
    /// Spacing between elements (buttons ↔ container)
    var barSpacing: CGFloat = 6
    /// Border width for all bordered elements
    var borderWidth: CGFloat = 0.5

    // MARK: - Buttons

    /// Side button diameter (attach, mic)
    var buttonSize: CGFloat = 40
    /// Icon size inside buttons
    var buttonIconSize: CGFloat = 16
    /// Internal send button padding from mainContainer edges
    var sendButtonInset: CGFloat = 4
    /// Internal send button icon size
    var sendButtonIconSize: CGFloat = 14

    // MARK: - Text View

    /// Minimum height of the text view
    var textViewMinHeight: CGFloat = 40
    /// Maximum height before scrolling
    var textViewMaxHeight: CGFloat = 120
    /// Corner radius of the main container
    var containerCornerRadius: CGFloat = 20
    /// Text view font
    var textViewFont: UIFont = .systemFont(ofSize: 16)
    /// Text view content insets (right accounts for internal send button)
    var textViewInsets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 40)
    /// Placeholder leading offset inside text view
    var placeholderLeading: CGFloat = 13
    /// Placeholder text
    var placeholderText: String = "Сообщение"

    // MARK: - Reply Panel

    /// Height of the reply/edit panel
    var replyPanelHeight: CGFloat = 48
    /// Reply icon size
    var replyIconSize: CGFloat = 10
    /// Reply close button size
    var replyCancelSize: CGFloat = 20
    /// Reply close icon size
    var replyCancelIconSize: CGFloat = 10
    /// Reply panel internal spacing
    var replySpacing: CGFloat = 8
    /// Reply accent bar width
    var replyAccentWidth: CGFloat = 2.5
    /// Reply sender font
    var replySenderFont: UIFont = .systemFont(ofSize: 13, weight: .semibold)
    /// Reply text font
    var replyTextFont: UIFont = .systemFont(ofSize: 13)
    /// Reply separator height
    var replySeparatorHeight: CGFloat = 0.5

    // MARK: - Recording

    /// Recording dot diameter
    var recordDotSize: CGFloat = 10
    /// Recording dot leading padding
    var recordDotLeading: CGFloat = 12
    /// Timer leading from dot
    var recordTimerLeading: CGFloat = 8
    /// Timer font
    var recordTimerFont: UIFont = .monospacedDigitSystemFont(ofSize: 16, weight: .regular)
    /// Dot minimum alpha during blink
    var recordDotMinAlpha: CGFloat = 0.2
    /// Slide hint center X offset
    var recordSlideHintOffset: CGFloat = 20
    /// Slide arrow font
    var recordSlideArrowFont: UIFont = .systemFont(ofSize: 22, weight: .bold)
    /// Cancel label font
    var recordCancelFont: UIFont = .systemFont(ofSize: 14)
    /// Cancel swipe threshold (px)
    var recordCancelThreshold: CGFloat = 100
    /// Lock swipe threshold (px)
    var recordLockThreshold: CGFloat = 70
    /// Minimum press duration to start recording
    var recordMinPressDuration: TimeInterval = 0.15

    // MARK: - Lock View

    /// Lock container diameter
    var lockSize: CGFloat = 44
    /// Lock icon size
    var lockIconSize: CGFloat = 14
    /// Lock chevron size
    var lockChevronSize: CGFloat = 10
    /// Lock bottom margin from button
    var lockBottomMargin: CGFloat = 8
    /// Lock chevron top padding
    var lockChevronTopPad: CGFloat = 6
    /// Lock icon center Y offset
    var lockIconCenterOffset: CGFloat = 5

    // MARK: - Send Pulse (locked state)

    /// Enlarged scale of pulsing send button
    var pulseBaseScale: CGFloat = 1.15
    /// Max scale of pulsing send button
    var pulseMaxScale: CGFloat = 1.28
    /// Pulse animation duration (one direction)
    var pulseDuration: TimeInterval = 0.6

    // MARK: - Singleton

    static var current = InputBarLayout()
}
