import Foundation

/// Вычисляет разницу между двумя конфигурациями для точечного обновления UI.
struct ConfigurationDiff {
    let themeChanged: Bool
    let layoutChanged: Bool
    let featuresChanged: Bool

    // Точечные изменения features
    let fabChanged: Bool
    let floatingDateChanged: Bool
    let inputBarVisibilityChanged: Bool
    let cellAffectingChanged: Bool
    let dateSeparatorsChanged: Bool
    let contextMenuChanged: Bool
    let scrollThresholdsChanged: Bool

    init(old: ChatConfiguration, new: ChatConfiguration) {
        themeChanged = old.theme != new.theme
        layoutChanged = old.layout != new.layout
        featuresChanged = old.features != new.features

        let of = old.features
        let nf = new.features

        fabChanged = of.showFab != nf.showFab
        floatingDateChanged = of.showFloatingDate != nf.showFloatingDate

        inputBarVisibilityChanged = of.showInputBar != nf.showInputBar
            || of.showAttachButton != nf.showAttachButton
            || of.showVoiceRecording != nf.showVoiceRecording

        cellAffectingChanged = of.senderNameMode != nf.senderNameMode
            || of.showMessageStatus != nf.showMessageStatus
            || of.showTimestamp != nf.showTimestamp
            || of.showReactions != nf.showReactions
            || of.showReplyPreview != nf.showReplyPreview
            || of.showEditedMark != nf.showEditedMark
            || of.showForwardedMark != nf.showForwardedMark

        dateSeparatorsChanged = of.showDateSeparators != nf.showDateSeparators

        contextMenuChanged = of.contextMenuEnabled != nf.contextMenuEnabled
            || of.emojiReactions != nf.emojiReactions

        scrollThresholdsChanged = of.topLoadThreshold != nf.topLoadThreshold
            || of.bottomLoadThreshold != nf.bottomLoadThreshold
            || of.scrollToBottomThreshold != nf.scrollToBottomThreshold
    }

    /// Нет изменений
    var isEmpty: Bool {
        !themeChanged && !layoutChanged && !featuresChanged
    }
}
