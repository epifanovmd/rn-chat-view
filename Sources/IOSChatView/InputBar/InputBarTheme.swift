import UIKit

public struct InputBarTheme {

    // MARK: - Контейнер и текст

    public var background: UIColor
    public var border: UIColor
    public var text: UIColor
    public var tint: UIColor
    public var placeholder: UIColor

    // MARK: - Панель ответа

    public var replyAccent: UIColor
    public var replySender: UIColor
    public var replyText: UIColor
    public var replyClose: UIColor

    // MARK: - Запись

    public var recordingDot: UIColor
    public var recordingCancel: UIColor
    public var recordingMicFill: UIColor

    // MARK: - Замок

    public var lockBackground: UIColor
    public var lockIcon: UIColor
}

// MARK: - Пресеты

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
