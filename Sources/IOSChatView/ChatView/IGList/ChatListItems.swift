import IGListKit

// MARK: - Message Item

public final class MessageListItem: NSObject, ListDiffable {
    let message: ChatMessage
    private let contentHash: Int

    init(message: ChatMessage) {
        self.message = message
        var hasher = Hasher()
        hasher.combine(message.id)
        hasher.combine(message.content)
        hasher.combine(message.status)
        hasher.combine(message.reactions)
        hasher.combine(message.isEdited)
        hasher.combine(message.reply)
        hasher.combine(message.forwardedFrom)
        hasher.combine(message.actions)
        self.contentHash = hasher.finalize()
    }

    public func diffIdentifier() -> NSObjectProtocol {
        message.id as NSString
    }

    public func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let other = object as? MessageListItem else { return false }
        return contentHash == other.contentHash
    }
}

// MARK: - Date Separator Item

public final class DateSeparatorListItem: NSObject, ListDiffable {
    let groupDate: String
    let title: String

    init(groupDate: String) {
        self.groupDate = groupDate
        self.title = DateHelper.shared.sectionTitle(from: groupDate)
    }

    public func diffIdentifier() -> NSObjectProtocol {
        ("date_" + groupDate) as NSString
    }

    public func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let other = object as? DateSeparatorListItem else { return false }
        return groupDate == other.groupDate
    }
}

// MARK: - Loading Item

public final class LoadingListItem: NSObject, ListDiffable {
    enum Position: String { case top, bottom }
    let position: Position

    init(position: Position) {
        self.position = position
    }

    public func diffIdentifier() -> NSObjectProtocol {
        ("loading_" + position.rawValue) as NSString
    }

    public func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let other = object as? LoadingListItem else { return false }
        return position == other.position
    }
}
