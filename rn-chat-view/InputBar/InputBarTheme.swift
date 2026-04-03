import UIKit

/// Theme colors for the InputBar module.
struct InputBarTheme {

    // MARK: - Container & Text

    /// Background of buttons and main container
    var background: UIColor
    /// Border color
    var border: UIColor
    /// Text color in text view
    var text: UIColor
    /// Tint color (cursor, icons)
    var tint: UIColor
    /// Placeholder text color
    var placeholder: UIColor

    // MARK: - Reply Panel

    /// Reply accent bar color
    var replyAccent: UIColor
    /// Reply sender name color
    var replySender: UIColor
    /// Reply text color
    var replyText: UIColor
    /// Reply close button tint
    var replyClose: UIColor

    // MARK: - Recording

    /// Recording dot color
    var recordingDot: UIColor
    /// Cancel button / trash icon color
    var recordingCancel: UIColor
    /// Mic button / send button fill during recording
    var recordingMicFill: UIColor

    // MARK: - Lock

    /// Lock container background
    var lockBackground: UIColor
    /// Lock icon tint
    var lockIcon: UIColor
}

// MARK: - Factory from ChatTheme

extension InputBarTheme {

    static let light = InputBarTheme(
        background: .white,
        border: UIColor(white: 0.8, alpha: 1),
        text: .black,
        tint: .systemBlue,
        placeholder: UIColor(white: 0.6, alpha: 1),
        replyAccent: .systemBlue,
        replySender: .systemBlue,
        replyText: UIColor(white: 0.3, alpha: 1),
        replyClose: UIColor(white: 0.5, alpha: 1),
        recordingDot: .systemRed,
        recordingCancel: .systemRed,
        recordingMicFill: .systemBlue,
        lockBackground: UIColor(white: 0.95, alpha: 1),
        lockIcon: UIColor(white: 0.4, alpha: 1)
    )

    static let dark = InputBarTheme(
        background: UIColor(red: 0.15, green: 0.19, blue: 0.25, alpha: 1),
        border: UIColor(white: 0.25, alpha: 1),
        text: .white,
        tint: UIColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1),
        placeholder: UIColor(white: 0.45, alpha: 1),
        replyAccent: UIColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1),
        replySender: UIColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1),
        replyText: UIColor(white: 0.65, alpha: 1),
        replyClose: UIColor(white: 0.5, alpha: 1),
        recordingDot: .systemRed,
        recordingCancel: .systemRed,
        recordingMicFill: UIColor(red: 0.35, green: 0.6, blue: 0.95, alpha: 1),
        lockBackground: UIColor(red: 0.18, green: 0.22, blue: 0.28, alpha: 1),
        lockIcon: UIColor(white: 0.6, alpha: 1)
    )

    /// Create InputBarTheme from the existing ChatTheme.
    static func from(_ theme: ChatTheme) -> InputBarTheme {
        InputBarTheme(
            background: theme.inputBarTextViewBackground,
            border: theme.inputBarBorder,
            text: theme.inputBarText,
            tint: theme.inputBarTint,
            placeholder: theme.inputBarPlaceholder,
            replyAccent: theme.replyPanelAccent,
            replySender: theme.replyPanelSender,
            replyText: theme.replyPanelText,
            replyClose: theme.replyPanelClose,
            recordingDot: theme.voiceRecordingIndicator,
            recordingCancel: theme.voiceRecordingCancelColor,
            recordingMicFill: theme.voiceRecordingMicBackground,
            lockBackground: theme.voiceRecordingLockBackground,
            lockIcon: theme.voiceRecordingLockIcon
        )
    }
}
