import UIKit

/// Theme colors for the InputBar module.
public struct InputBarTheme {

    // MARK: - Container & Text

    /// Background of buttons and main container
    public var background: UIColor
    /// Border color
    public var border: UIColor
    /// Text color in text view
    public var text: UIColor
    /// Tint color (cursor, icons)
    public var tint: UIColor
    /// Placeholder text color
    public var placeholder: UIColor

    // MARK: - Reply Panel

    /// Reply accent bar color
    public var replyAccent: UIColor
    /// Reply sender name color
    public var replySender: UIColor
    /// Reply text color
    public var replyText: UIColor
    /// Reply close button tint
    public var replyClose: UIColor

    // MARK: - Recording

    /// Recording dot color
    public var recordingDot: UIColor
    /// Cancel button / trash icon color
    public var recordingCancel: UIColor
    /// Mic button / send button fill during recording
    public var recordingMicFill: UIColor

    // MARK: - Lock

    /// Lock container background
    public var lockBackground: UIColor
    /// Lock icon tint
    public var lockIcon: UIColor
}

// MARK: - Factory from ChatTheme

extension InputBarTheme {

    public static let light = InputBarTheme(
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

    public static let dark = InputBarTheme(
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

}
