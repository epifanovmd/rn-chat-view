import UIKit

/// Единая конфигурация чата: тема + layout + feature flags.
///
/// Использование:
/// ```
/// let config = ChatConfiguration.default.modified {
///     $0.theme.outgoingBubble = .systemBlue
///     $0.layout.bubbleCornerRadius = 20
///     $0.features.senderNameMode = .always
///     $0.features.showFab = false
/// }
/// chatViewController.configuration = config
/// ```
struct ChatConfiguration: Equatable {
    /// Цвета и визуальные стили
    var theme: ChatTheme
    /// Размеры, шрифты, отступы
    var layout: ChatLayout
    /// Поведенческие флаги (что показывать, как себя вести)
    var features: ChatFeatures

    /// Конфигурация по умолчанию: светлая тема, стандартный layout, все фичи включены
    static let `default` = ChatConfiguration(
        theme: .light,
        layout: ChatLayout(),
        features: ChatFeatures()
    )

    /// Создать изменённую копию конфигурации.
    /// ```
    /// let config = ChatConfiguration.default.modified {
    ///     $0.theme.outgoingBubble = .blue
    ///     $0.features.showFab = false
    /// }
    /// ```
    func modified(_ transform: (inout ChatConfiguration) -> Void) -> ChatConfiguration {
        var copy = self
        transform(&copy)
        return copy
    }
}

// MARK: - Equatable conformance for ChatTheme & ChatLayout

extension ChatTheme: Equatable {
    static func == (lhs: ChatTheme, rhs: ChatTheme) -> Bool {
        // Сравниваем ключевые поля — полное сравнение 80+ цветов через отражение слишком медленно.
        // При любом изменении темы потребитель создаёт новый экземпляр, поэтому identity check достаточен.
        lhs.isDark == rhs.isDark
            && lhs.outgoingBubble == rhs.outgoingBubble
            && lhs.incomingBubble == rhs.incomingBubble
            && lhs.backgroundColor == rhs.backgroundColor
            && lhs.inputBarTextViewBackground == rhs.inputBarTextViewBackground
            && lhs.outgoingText == rhs.outgoingText
            && lhs.incomingText == rhs.incomingText
            && lhs.fabArrowColor == rhs.fabArrowColor
            && lhs.dateSeparatorBackground == rhs.dateSeparatorBackground
            && lhs.voiceWaveformActive == rhs.voiceWaveformActive
    }
}

extension ChatLayout: Equatable {
    static func == (lhs: ChatLayout, rhs: ChatLayout) -> Bool {
        lhs.bubbleCornerRadius == rhs.bubbleCornerRadius
            && lhs.bubbleMaxWidthRatio == rhs.bubbleMaxWidthRatio
            && lhs.bubbleHPad == rhs.bubbleHPad
            && lhs.bubbleVPad == rhs.bubbleVPad
            && lhs.cellHMargin == rhs.cellHMargin
            && lhs.cellVSpacing == rhs.cellVSpacing
            && lhs.messageFont == rhs.messageFont
            && lhs.senderNameFont == rhs.senderNameFont
            && lhs.timeFont == rhs.timeFont
            && lhs.imageMaxHeight == rhs.imageMaxHeight
    }
}

// MARK: - modified() convenience for sub-configs

extension ChatTheme {
    /// Создать изменённую копию темы.
    func modified(_ transform: (inout ChatTheme) -> Void) -> ChatTheme {
        var copy = self
        transform(&copy)
        return copy
    }
}

extension ChatLayout {
    /// Создать изменённую копию layout.
    func modified(_ transform: (inout ChatLayout) -> Void) -> ChatLayout {
        var copy = self
        transform(&copy)
        return copy
    }
}

extension ChatFeatures {
    /// Создать изменённую копию features.
    func modified(_ transform: (inout ChatFeatures) -> Void) -> ChatFeatures {
        var copy = self
        transform(&copy)
        return copy
    }
}
