// MARK: - ContextMenuModels.swift

import UIKit

// MARK: - ContextMenuAction

public struct ContextMenuAction {
    public let id:            String
    public let title:         String
    public let systemImage:   String?
    public let isDestructive: Bool

    public init(
        id:            String,
        title:         String,
        systemImage:   String? = nil,
        isDestructive: Bool = false
    ) {
        self.id            = id
        self.title         = title
        self.systemImage   = systemImage
        self.isDestructive = isDestructive
    }
}

// MARK: - ContextMenuEmoji

public struct ContextMenuEmoji {
    public let emoji: String
    public init(emoji: String) { self.emoji = emoji }
}

// MARK: - ContextMenuConfiguration

public struct ContextMenuConfiguration {
    public let id:                   String
    public let sourceView:           UIView
    public let emojis:               [ContextMenuEmoji]
    public let actions:              [ContextMenuAction]
    /// Радиус скругления снапшота исходного view.
    /// Задаётся снаружи — ContextMenu не знает о ChatLayoutConstants.
    public let snapshotCornerRadius: CGFloat

    public init(
        id:                   String,
        sourceView:           UIView,
        emojis:               [ContextMenuEmoji],
        actions:              [ContextMenuAction],
        snapshotCornerRadius: CGFloat = 0
    ) {
        self.id                   = id
        self.sourceView           = sourceView
        self.emojis               = emojis
        self.actions              = actions
        self.snapshotCornerRadius = snapshotCornerRadius
    }
}
