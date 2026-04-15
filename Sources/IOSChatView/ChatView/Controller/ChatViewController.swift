import UIKit

// MARK: - Scroll Anchor

/// Якорь скролла: привязка к нижнему видимому сообщению.
/// `offset` = расстояние от нижнего края viewport до нижнего края ячейки-якоря.
/// Стабилен при вставках/удалениях сверху.
public struct ScrollAnchor: Codable, Equatable {
    /// ID ячейки-якоря (нижний видимый message).
    public let messageId: String
    /// Расстояние от visible bottom до нижнего края ячейки-якоря (px).
    /// 0 = нижний край ячейки совпадает с низом viewport.
    /// Положительное = ячейка выше низа viewport.
    public let offset: CGFloat
    /// Был ли пользователь внизу чата.
    public let wasAtBottom: Bool

    public init(messageId: String, offset: CGFloat, wasAtBottom: Bool) {
        self.messageId = messageId
        self.offset = offset
        self.wasAtBottom = wasAtBottom
    }
}

public final class ChatViewController: UIViewController {

    // MARK: - Public Configuration

    public var theme: ChatTheme = .light {
        didSet { guard isViewLoaded, !isBatchUpdate else { return }; applyTheme() }
    }
    public var layout: ChatLayout = ChatLayout() {
        didSet {
            guard isViewLoaded, !isBatchUpdate else { return }
            sizeCache.invalidateAll()
            reloadWithCrossfade()
        }
    }
    public var features: ChatFeatures = ChatFeatures() {
        didSet {
            guard isViewLoaded, !isBatchUpdate else { return }
            sizeCache.invalidateAll()
            applyFeatureChanges(from: oldValue)
        }
    }

    private var isBatchUpdate = false

    /// Apply multiple configuration changes at once to avoid redundant reloads.
    public func batchUpdate(_ block: () -> Void) {
        isBatchUpdate = true
        let oldFeatures = features
        block()
        isBatchUpdate = false
        sizeCache.invalidateAll()
        applyTheme()
        applyFeatureChanges(from: oldFeatures)
    }

    // MARK: - Public Properties

    public var contentFactory: ChatContentFactory = DefaultChatContentFactory()
    public weak var delegate: ChatViewControllerDelegate?

    public var hasMore = false
    public var hasNewer = false
    public var isLoading = false { didSet { emptyStateManager.update(isEmpty: messages.isEmpty, isLoading: isLoading, showEmptyState: features.showEmptyState) } }
    public var emptyStateText: String? {
        didSet { emptyStateManager.updateText(emptyStateText) }
    }
    public var isLoadingTop = false {
        didSet { if oldValue != isLoadingTop, isViewLoaded { updateTopLoadingOverlay() } }
    }
    public var isLoadingBottom = false {
        didSet { if oldValue != isLoadingBottom, isViewLoaded { scheduleBottomLoadingRebuild() } }
    }
    private var pendingLoadingRebuild: DispatchWorkItem?
    private lazy var topLoadingSpinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .medium)
        s.hidesWhenStopped = true
        return s
    }()

    let unreadManager = UnreadManager()

    public var unreadCount: Int { unreadManager.count }

    public func setUnreadCount(_ count: Int) {
        unreadManager.setExternalCount(count)
    }

    public var collectionExtraInsetTop: CGFloat = 0 {
        didSet {
            guard isViewLoaded else { return }
            floatingDateManager.updateTopConstraint(extraInsetTop: collectionExtraInsetTop)
            view.setNeedsLayout()
        }
    }
    public var collectionExtraInsetBottom: CGFloat = 0 {
        didSet { guard isViewLoaded else { return }; view.setNeedsLayout() }
    }

    // MARK: - Visibility Intervals

    /// Throttle interval for visible messages snapshot (seconds). Default 0.3.
    public var visibleMessagesThrottleInterval: TimeInterval = 0.3
    /// Debounce interval for unread messages batch (seconds). Default 0.3.
    public var unreadMessagesDebounceInterval: TimeInterval = 0.3
    /// Minimum fraction of cell height to enter "visible" set (0..1). Default 0.8.
    public var visibilityThreshold: CGFloat = 0.8
    /// Fraction below which a cell exits the "visible" set (hysteresis). Default 0.5.
    public var visibilityExitThreshold: CGFloat = 0.5
    /// Minimum fraction of cell height visible on screen for mark-as-read (0..1). Default 0.5.
    public var unreadVisibilityThreshold: CGFloat = 0.5

    // MARK: - Initial Scroll

    public var isInitialScrollProtected = false

    /// Saved scroll anchor for pixel-accurate initial restore.
    /// Set from RN before messages arrive. Used by applyInitial.
    public var pendingScrollAnchor: ScrollAnchor?

    /// Pending initial scroll target set by applyInitial.
    /// Executed by viewDidLayoutSubviews once bounds > 0 and view is in window.
    enum PendingInitialScroll {
        case toAnchor(ScrollAnchor)
        case toBottom
    }
    var pendingInitialScroll: PendingInitialScroll?

    // MARK: - Data (internal — mutated by extensions, read by MessageUpdateHandler/DataSource)

    public internal(set) var messages: [ChatMessage] = []
    var messageIndex: [String: ChatMessage] = [:]
    var rowIndexCache: [String: Int] = [:]
    var cachedDateSeparators: [(rowIndex: Int, groupDate: String)] = []
    var rows: [ChatRow] = []

    // MARK: - Size Cache

    var sizeCache = SizeCache()

    // MARK: - Collection View + Data Source

    public private(set) var collectionView: UICollectionView!
    var dataSource: ChatDataSource!

    // MARK: - UI Components

    public var inputBar: InputBarView!

    // MARK: - Managers

    let floatingDateManager = FloatingDateManager()
    let fabManager = FABManager()
    let emptyStateManager = EmptyStateManager()

    // MARK: - Constraints

    var inputBarKeyboardConstraint: NSLayoutConstraint?

    // MARK: - Scroll State

    enum ScrollDirection { case up, down, none }
    var scrollDirection: ScrollDirection = .none
    var lastScrollOffsetY: CGFloat = 0
    var isProgrammaticScroll = false
    var lastScrollEventTime: CFTimeInterval = 0
    var anchorThrottleTime: CFTimeInterval = 0
    var visibleMessageIDs: Set<String> = []
    var lastVisibleThrottleTime: CFTimeInterval = 0
    var pendingVisibleThrottleTask: DispatchWorkItem?
    var lastFiredVisibleIDs: Set<String> = []
    var activeVisibleIDs: Set<String> = []
    var latestVisibleIDs: [String] = []
    var pendingUnreadIDs: Set<String> = []
    var unreadDebounceTask: DispatchWorkItem?
    var pendingHighlightId: String?
    var isUserDragging = false
    var lastKnownMessageCount = 0
    var pendingScrollToBottom = false
    var isLoadingNewerActive = false

    // MARK: - Keyboard Freeze

    lazy var keyboardFreezeManager = KeyboardFreezeManager(
        collectionView: collectionView,
        inputBar: inputBar,
        onThaw: { [weak self] in self?.updateCollectionInsets() }
    )

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        isInitialScrollProtected = true
        setupCollectionView()
        setupDataSource()
        setupInputBar()
        emptyStateManager.setup(in: view, inputBar: inputBar, factory: contentFactory, layout: layout, theme: theme)
        emptyStateManager.onTap = { [weak self] in self?.view.endEditing(true) }
        unreadManager.onCountChanged = { [weak self] count in
            self?.fabManager.updateBadge(unreadCount: count)
        }
        setupFAB()
        setupFloatingDate()
        applyTheme()
        updateEmptyState()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let cv = collectionView!
        updateCollectionInsets()
        executePendingInitialScroll()
    }

    /// Execute pending initial scroll when the view is fully laid out:
    /// bounds > 0 and view is in a window (not a temporary RN state).
    func executePendingInitialScroll() {
        guard let scroll = pendingInitialScroll else { return }

        let cv = collectionView!
        let frameH = cv.bounds.height

        let insetBottom = cv.contentInset.bottom

        // Wait until view has real dimensions, is in a window, and insets have settled.
        // During RN mount, keyboard layout guide gives insetBottom=852 temporarily.
        // We must wait until it settles to the real value (typically < half the screen).
        guard frameH > 0, cv.bounds.width > 0,
              view.window != nil,
              insetBottom < frameH * 0.5 else {
            return
        }

        guard let layout = chatLayout else { return }

        let topInset = cv.adjustedContentInset.top
        let contentH = cv.contentSize.height

        switch scroll {
        case .toAnchor(let anchor):
            if anchor.wasAtBottom {
                let maxY = max(contentH - frameH + insetBottom, -topInset)
                cv.contentOffset = CGPoint(x: 0, y: maxY)
            } else if rowIndexCache[anchor.messageId] != nil {
                restoreScrollAnchor(anchor)
            } else {
                let maxY = max(contentH - frameH + insetBottom, -topInset)
                cv.contentOffset = CGPoint(x: 0, y: maxY)
            }

        case .toBottom:
            let maxY = max(contentH - frameH + insetBottom, -topInset)
            cv.contentOffset = CGPoint(x: 0, y: maxY)
        }

        pendingInitialScroll = nil
        isInitialScrollProtected = false
        finalizeUpdate(count: rows.count, animated: false)
    }

    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateCollectionInsets()
    }

    deinit {
        floatingDateManager.cancelPendingTasks()
        pendingVisibleThrottleTask?.cancel()
        unreadDebounceTask?.cancel()
        pendingLoadingRebuild?.cancel()
    }

    // MARK: - Setup Collection View

    private(set) var chatLayout: ChatCollectionViewLayout!

    private func setupCollectionView() {
        chatLayout = ChatCollectionViewLayout()

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: chatLayout)
        collectionView.backgroundColor = .clear
        collectionView.keyboardDismissMode = .interactive
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.alwaysBounceVertical = true
        collectionView.isPrefetchingEnabled = false
        collectionView.clipsToBounds = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        // Set delegate BEFORE creating dataSource — required for FlowLayout + ScrollView delegate
        collectionView.delegate = self
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        collectionView.addGestureRecognizer(tap)
    }

    // MARK: - Setup DataSource

    private func setupDataSource() {
        collectionView.register(MessageCell.self, forCellWithReuseIdentifier: MessageCell.reuseID)
        collectionView.register(DateSeparatorCell.self, forCellWithReuseIdentifier: DateSeparatorCell.reuseID)
        collectionView.register(LoadingCell.self, forCellWithReuseIdentifier: LoadingCell.reuseID)
        collectionView.register(AvatarSupplementaryView.self, forSupplementaryViewOfKind: AvatarSupplementaryView.kind, withReuseIdentifier: AvatarSupplementaryView.reuseID)
        dataSource = ChatDataSource(controller: self)
        collectionView.dataSource = dataSource
    }

    // MARK: - Setup Input Bar

    private func setupInputBar() {
        inputBar = InputBarView()
        inputBar.delegate = self
        inputBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputBar)

        NSLayoutConstraint.activate([
            inputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        view.keyboardLayoutGuide.followsUndockedKeyboard = true
        let c = inputBar.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
        c.isActive = true
        inputBarKeyboardConstraint = c
    }

    // MARK: - Setup FAB

    private func setupFAB() {
        fabManager.setup(in: view, inputBar: inputBar, factory: contentFactory, layout: layout, theme: theme, features: features)
        fabManager.onTap = { [weak self] in self?.delegate?.chatDidTapFAB() }
    }

    // MARK: - Setup Floating Date

    private func setupFloatingDate() {
        floatingDateManager.setup(
            in: view,
            safeAreaGuide: view.safeAreaLayoutGuide,
            layout: layout,
            theme: theme,
            extraInsetTop: collectionExtraInsetTop,
            factory: contentFactory
        )
        if !features.showFloatingDate {
            floatingDateManager.setHidden(true)
        }
    }

    // MARK: - Theme

    func applyTheme() {
        guard isViewLoaded else { return }
        collectionView.backgroundColor = .clear
        inputBar.applyTheme(theme.isDark ? .dark : .light)
        floatingDateManager.applyTheme(theme)
        fabManager.applyTheme(theme, layout: layout, factory: contentFactory)
        emptyStateManager.applyTheme(factory: contentFactory, theme: theme, layout: layout)
        sizeCache.invalidateAll()
        reloadWithCrossfade()
    }

    // MARK: - Feature Changes

    private func applyFeatureChanges(from old: ChatFeatures) {
        if old.showFab != features.showFab {
            fabManager.setEnabled(features.showFab)
            if features.showFab {
                fabManager.updateVisibility(isNearBottom: isNearBottom(), hasMessages: !messages.isEmpty, animated: true)
            }
        }
        if old.showFloatingDate != features.showFloatingDate {
            floatingDateManager.setHidden(!features.showFloatingDate)
        }
        if old.showInputBar != features.showInputBar
            || old.showAttachButton != features.showAttachButton
            || old.showVoiceRecording != features.showVoiceRecording {
            inputBar.isHidden = !features.showInputBar
            inputBar.showAttachButton = features.showAttachButton
            inputBar.voiceRecordingEnabled = features.showVoiceRecording
            if !features.showVoiceRecording {
                fabManager.setExpanded(true, animated: true)
            }
            updateCollectionInsets()
        }
        if old.showDateSeparators != features.showDateSeparators {
            reloadAll()
        }
        if old.senderNameMode != features.senderNameMode
            || old.showMessageStatus != features.showMessageStatus
            || old.showTimestamp != features.showTimestamp
            || old.showReactions != features.showReactions
            || old.showReplyPreview != features.showReplyPreview
            || old.showEditedMark != features.showEditedMark
            || old.showForwardedMark != features.showForwardedMark {
            reloadWithCrossfade()
        }
        if old.showEmptyState != features.showEmptyState {
            updateEmptyState()
        }
    }

    private func updateTopLoadingOverlay() {
        if isLoadingTop {
            if topLoadingSpinner.superview == nil {
                topLoadingSpinner.translatesAutoresizingMaskIntoConstraints = false
                collectionView.addSubview(topLoadingSpinner)
                NSLayoutConstraint.activate([
                    topLoadingSpinner.centerXAnchor.constraint(equalTo: collectionView.frameLayoutGuide.centerXAnchor),
                    topLoadingSpinner.topAnchor.constraint(equalTo: collectionView.topAnchor, constant: 12),
                ])
            }
            topLoadingSpinner.startAnimating()
            hideFirstDateSeparator(true)
        } else {
            topLoadingSpinner.stopAnimating()
            hideFirstDateSeparator(false)
        }
    }

    func hideFirstDateSeparator(_ hidden: Bool) {
        guard let first = cachedDateSeparators.first else { return }
        let ip = IndexPath(item: first.rowIndex, section: 0)
        if let cell = collectionView.cellForItem(at: ip) as? DateSeparatorCell {
            cell.contentView.alpha = hidden ? 0 : 1
        }
    }

    private func scheduleBottomLoadingRebuild() {
        pendingLoadingRebuild?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.reloadAll()
        }
        pendingLoadingRebuild = work
        DispatchQueue.main.async(execute: work)
    }

    private func reloadWithCrossfade() {
        let anchor = currentScrollAnchor()
        sizeCache.invalidateAll()
        rows = buildRows(from: messages)
        applyLayoutData(computeLayoutData())
        UIView.transition(with: collectionView, duration: 0.25, options: .transitionCrossDissolve) {
            self.collectionView.reloadData()
        } completion: { [weak self] _ in
            guard let self, let anchor else { return }
            self.restoreScrollAnchor(anchor)
        }
    }

    // MARK: - Update Messages

    private lazy var messageUpdateHandler = MessageUpdateHandler(controller: self)

    private var pendingMessages: [ChatMessage]?

    public func updateMessages(_ newMessages: [ChatMessage]) {
        pendingLoadingRebuild?.cancel()
        pendingLoadingRebuild = nil

        // Defer structural updates while the user is actively scrolling.
        // Content, append, and prepend are safe — they handle scroll position internally.
        if collectionView.isDragging || collectionView.isDecelerating {
            let isStructural = messageUpdateHandler.peekClassify(
                old: messages, new: newMessages)
            if isStructural {
                pendingMessages = newMessages
                return
            }
        }

        messageUpdateHandler.update(with: newMessages)
    }

    func flushPendingMessages() {
        guard let pending = pendingMessages else { return }
        pendingMessages = nil
        updateMessages(pending)
    }

    func finalizeUpdate(count: Int, animated: Bool) {
        lastKnownMessageCount = count
        updateEmptyState()
        updateFABVisibility(animated: animated)
    }

    func trackNewUnread(newMessages: [ChatMessage], oldCount: Int) {
        unreadManager.trackAppended(newMessages: newMessages, oldCount: oldCount)
    }

    public func clearUnread() {
        unreadManager.clearAll()
    }


    // MARK: - Scroll Anchor

    /// Returns the current scroll position as a stable anchor tied to a message.
    /// Anchors to the top-most visible message with offset from visible top.
    /// Accounts for `adjustedContentInset.top` (safe area + extra inset).
    public func currentScrollAnchor() -> ScrollAnchor? {
        guard !messages.isEmpty, let cv = collectionView else { return nil }

        if isNearBottom() {
            guard let lastMsg = messages.last else { return nil }
            return ScrollAnchor(messageId: lastMsg.id, offset: 0, wasAtBottom: true)
        }

        // Нижний край видимой области (с учётом insets)
        let visibleBottom = cv.contentOffset.y + cv.bounds.height - cv.contentInset.bottom

        // Нижний видимый message cell
        let paths = cv.indexPathsForVisibleItems.sorted { $0.item > $1.item }

        for ip in paths {
            guard ip.item < rows.count,
                  case .message(let msg) = rows[ip.item] else { continue }

            let rowIdx = ip.item
            guard rowIdx < chatLayout.rowLayoutData.count,
                  rowIdx < chatLayout.yOffsets.count else { continue }

            let cellBottom = chatLayout.yOffsets[rowIdx]
                + chatLayout.rowLayoutData[rowIdx].topInset
                + chatLayout.rowLayoutData[rowIdx].height
            let offset = visibleBottom - cellBottom

            return ScrollAnchor(messageId: msg.id, offset: offset, wasAtBottom: false)
        }
        return nil
    }

    /// Restores scroll position from a previously saved anchor.
    /// Восстанавливает позицию скролла: нижний край ячейки-якоря на прежнем расстоянии от visible bottom.
    public func restoreScrollAnchor(_ anchor: ScrollAnchor) {
        guard let cv = collectionView else { return }

        if anchor.wasAtBottom {
            scrollToBottom(animated: false)
            return
        }

        guard let rowIndex = rowIndexCache[anchor.messageId],
              rowIndex < chatLayout.rowLayoutData.count,
              rowIndex < chatLayout.yOffsets.count else {
            return
        }

        let cellBottom = chatLayout.yOffsets[rowIndex]
            + chatLayout.rowLayoutData[rowIndex].topInset
            + chatLayout.rowLayoutData[rowIndex].height

        // visibleBottom = contentOffset.y + bounds.height - contentInset.bottom
        // cellBottom = visibleBottom - offset
        // → contentOffset.y = cellBottom + offset - bounds.height + contentInset.bottom
        let targetOffset = cellBottom + anchor.offset - cv.bounds.height + cv.contentInset.bottom

        let minY = -cv.adjustedContentInset.top
        let maxY = cv.contentSize.height - cv.bounds.height + cv.contentInset.bottom
        let clampedY = min(max(targetOffset, minY), max(maxY, minY))

        cv.contentOffset = CGPoint(x: 0, y: clampedY)
    }

    // MARK: - Scroll

    public func scrollToBottom(animated: Bool) {
        pendingScrollToBottom = true

        guard !messages.isEmpty else {
            return
        }
        collectionView.layoutIfNeeded()
        isProgrammaticScroll = true
        let maxY = collectionView.contentSize.height - collectionView.bounds.height + collectionView.contentInset.bottom
        if maxY > -collectionView.contentInset.top {
            collectionView.setContentOffset(CGPoint(x: 0, y: maxY), animated: animated)
        }
        if !animated { isProgrammaticScroll = false }
    }

    public func scrollToMessage(id: String, position: String, animated: Bool, highlight: Bool) {
        guard let rowIndex = rowIndexCache[id] else { return }
        let totalItems = collectionView.numberOfItems(inSection: 0)
        guard rowIndex < totalItems else { return }

        isProgrammaticScroll = true
        collectionView.layoutIfNeeded()

        let scrollPos: UICollectionView.ScrollPosition
        switch position {
        case "top": scrollPos = .top
        case "bottom": scrollPos = .bottom
        default: scrollPos = .centeredVertically
        }

        collectionView.scrollToItem(at: IndexPath(item: rowIndex, section: 0),
                                     at: scrollPos, animated: animated)
        if !animated { isProgrammaticScroll = false }

        if highlight {
            pendingHighlightId = id
            DispatchQueue.main.asyncAfter(deadline: .now() + (animated ? 0.35 : 0.1)) { [weak self] in
                self?.performHighlight()
            }
        }
    }

    func performHighlight() {
        guard let id = pendingHighlightId else { return }
        pendingHighlightId = nil
        guard let rowIndex = rowIndexCache[id] else { return }
        let ip = IndexPath(item: rowIndex, section: 0)
        guard let cell = collectionView.cellForItem(at: ip) as? MessageCell else { return }
        cell.playHighlight()
    }

    // MARK: - Disintegration Effect

    /// Enable confetti-like disintegration effect when messages are deleted.
    /// When `false` (default), deletion uses standard fade animation.
    /// When `true`, deleted message bubbles shatter into particles automatically
    /// on any `updateMessages()` call that removes messages.
    public var disintegrationEnabled: Bool = false

    /// Particle animation configuration (used when `disintegrationEnabled` is `true`).
    public var disintegrationConfig: DisintegrationAnimator.Config = .default

    // MARK: - Input Mode

    public func beginReply(info: ReplyInfo) {
        inputBar.beginReply(info: InputBarReplyInfo(
            messageId: info.replyToId, senderName: info.senderName,
            text: info.text, hasImage: info.hasImage
        ))
    }
    public func beginEdit(messageId: String, text: String) { inputBar.beginEdit(messageId: messageId, text: text) }
    public func clearInputMode() { inputBar.cancelMode() }

    // MARK: - Helpers

    public func message(forID id: String) -> ChatMessage? { messageIndex[id] }

    public func distanceFromBottom() -> CGFloat {
        guard let cv = collectionView else { return 0 }
        return max(0, cv.contentSize.height - cv.contentOffset.y - cv.bounds.height + cv.contentInset.bottom)
    }

    public func isNearBottom() -> Bool {
        guard collectionView.contentSize.height > 0 else { return true }
        return distanceFromBottom() <= features.scrollToBottomThreshold
    }

    func updateFABVisibility(animated: Bool) {
        guard features.showFab else { return }
        fabManager.updateVisibility(isNearBottom: isNearBottom(), hasMessages: !messages.isEmpty, animated: animated)
        fabManager.updateBadge(unreadCount: unreadManager.count)
    }

    func updateEmptyState() {
        emptyStateManager.update(isEmpty: messages.isEmpty, isLoading: isLoading, showEmptyState: features.showEmptyState)
    }

    func updateFloatingDate() {
        guard features.showFloatingDate, !messages.isEmpty else { floatingDateManager.hide(); return }
        floatingDateManager.update(
            cachedSeparators: cachedDateSeparators,
            collectionView: collectionView,
            parentView: view,
            extraInsetTop: collectionExtraInsetTop
        )
    }

    func updateCollectionInsets() {
        guard !keyboardFreezeManager.isInsetFrozen else { return }
        guard let cv = collectionView else { return }
        guard inputBar != nil, inputBar.frame.height > 0, view.bounds.height > 0 else { return }

        let safeTop = view.safeAreaInsets.top
        let newTop = safeTop + collectionExtraInsetTop
        if abs(cv.contentInset.top - newTop) > 0.5 {
            cv.contentInset.top = newTop
            cv.verticalScrollIndicatorInsets.top = collectionExtraInsetTop
        }

        let inputBarZone = view.bounds.height - inputBar.frame.minY
        let newBottom = inputBarZone + layout.collectionBottomPadding + collectionExtraInsetBottom
        let newIndicatorBottom = max(0, inputBarZone - view.safeAreaInsets.bottom)
        let oldBottom = cv.contentInset.bottom
        guard abs(oldBottom - newBottom) > 0.5 else { return }

        if isUserDragging {
            cv.contentInset.bottom = newBottom
            cv.verticalScrollIndicatorInsets.bottom = newIndicatorBottom
            return
        }

        // Compute distanceFromEnd BEFORE changing inset (uses oldBottom)
        let distanceFromEnd = cv.contentSize.height - cv.contentOffset.y - cv.bounds.height + oldBottom

        cv.contentInset.bottom = newBottom
        cv.verticalScrollIndicatorInsets.bottom = newIndicatorBottom

        // Don't adjust offset during initial scroll protection —
        // the offset will be set by executePendingInitialScroll.
        guard !isInitialScrollProtected,
              pendingInitialScroll == nil else {
            return
        }

        let maxOffsetY = cv.contentSize.height - cv.bounds.height + newBottom
        let minOffsetY = -cv.contentInset.top
        // When content is too small to fill the visible area, keep it pinned at top
        guard maxOffsetY > minOffsetY else { return }

        let newOffsetY = cv.contentSize.height - cv.bounds.height + newBottom - distanceFromEnd
        cv.contentOffset = CGPoint(x: 0, y: max(minOffsetY, min(newOffsetY, maxOffsetY)))
    }

    @objc func dismissKeyboard() { view.endEditing(true) }
}

