import UIKit

/// Протокол фабрики, отвечающей за создание всех кастомизируемых view в чате.
///
/// Ядро библиотеки не знает о конкретных типах контента — всё создание view
/// и расчёт размеров делегируется фабрике. Присвойте экземпляр в
/// `ChatViewController.contentFactory` для управления всем внешним видом.
///
/// `DefaultChatContentFactory` — готовая реализация для встроенных типов
/// (изображения, голосовые, опросы, файлы). Можно:
/// - Использовать как есть.
/// - Наследовать и переопределить отдельные методы.
/// - Реализовать протокол с нуля для полностью кастомного UI.
public protocol ChatContentFactory: AnyObject {

    // MARK: - Контент

    func contentView(
        for media: AnyChatContent,
        message: ChatMessage,
        width: CGFloat,
        theme: ChatTheme,
        layout: ChatLayout,
        onInteraction: @escaping (ChatContentInteraction) -> Void
    ) -> UIView

    func contentHeight(
        for media: AnyChatContent,
        width: CGFloat,
        layout: ChatLayout
    ) -> CGFloat

    /// In-place реконфигурация существующего view при изменении данных.
    /// Возвращает `true` если view обновлён, `false` — нужна полная пересборка.
    func reconfigureContentView(
        _ view: UIView,
        for media: AnyChatContent,
        message: ChatMessage,
        width: CGFloat,
        theme: ChatTheme,
        layout: ChatLayout,
        onInteraction: @escaping (ChatContentInteraction) -> Void
    ) -> Bool

    // MARK: - Текст

    func textView(
        text: String,
        ownership: MessageOwnership,
        theme: ChatTheme,
        layout: ChatLayout,
        linkDetectionEnabled: Bool,
        onLinkTap: ((URL) -> Void)?
    ) -> UIView

    func textHeight(
        text: String,
        font: UIFont,
        width: CGFloat
    ) -> CGFloat

    // MARK: - Эмодзи

    func emojiView(
        text: String,
        emojiCount: Int,
        layout: ChatLayout
    ) -> UIView

    // MARK: - Реакции

    func reactionsView(
        reactions: [Reaction],
        theme: ChatTheme,
        maxWidth: CGFloat,
        layout: ChatLayout,
        onTap: @escaping (String) -> Void
    ) -> UIView

    // MARK: - Индикатор треда

    func threadIndicatorView(
        thread: ThreadInfo,
        ownership: MessageOwnership,
        theme: ChatTheme,
        layout: ChatLayout,
        onTap: @escaping () -> Void
    ) -> UIView

    // MARK: - Превью цитаты

    func replyPreviewView(
        reply: ReplyInfo,
        resolved: ReplyDisplayInfo?,
        ownership: MessageOwnership,
        theme: ChatTheme,
        layout: ChatLayout,
        onTap: @escaping () -> Void
    ) -> UIView

    // MARK: - Футер

    func footerView(
        message: ChatMessage,
        theme: ChatTheme,
        layout: ChatLayout,
        features: ChatFeatures
    ) -> UIView?

    // MARK: - Имя отправителя

    func senderNameView(
        name: String,
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView

    // MARK: - Заголовок пересланного

    func forwardedHeaderView(
        from: String,
        ownership: MessageOwnership,
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView

    // MARK: - Разделитель дат

    func dateSeparatorView(
        title: String,
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView

    func dateSeparatorHeight(layout: ChatLayout) -> CGFloat

    // MARK: - Плавающая дата

    func floatingDateView(
        title: String,
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView

    // MARK: - Пустое состояние

    func emptyStateView(
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView

    func emptyStateLoadingView(
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView

    // MARK: - Индикатор загрузки

    func loadingIndicatorView(
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView

    // MARK: - FAB (кнопка скролла вниз)

    /// Если возвращённый view — UIButton, используется `.touchUpInside`;
    /// иначе добавляется tap gesture автоматически.
    func fabView(
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView

    /// Бейдж непрочитанных на FAB. Если UILabel — `text` обновляется автоматически.
    func fabBadgeView(
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView

    // MARK: - Аватарка

    func avatarView(
        name: String,
        url: String?,
        size: CGFloat,
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView
}
