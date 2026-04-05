import UIKit

public final class ChatViewController: UIViewController {

    // MARK: - Public Configuration

    public var theme: ChatTheme = .light {
        didSet { guard isViewLoaded, !isBatchUpdate else { return }; applyTheme() }
    }
    public var layout: ChatLayout = ChatLayout() {
        didSet {
            guard isViewLoaded, !isBatchUpdate else { return }
            sizeCache.removeAll()
            reloadWithCrossfade()
        }
    }
    public var features: ChatFeatures = ChatFeatures() {
        didSet {
            guard isViewLoaded, !isBatchUpdate else { return }
            sizeCache.removeAll()
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
        sizeCache.removeAll()
        applyTheme()
        applyFeatureChanges(from: oldFeatures)
    }

    // MARK: - Public Properties

    public var contentFactory: ChatContentFactory = DefaultChatContentFactory()
    public weak var delegate: ChatViewControllerDelegate?

    public var hasMore = false
    public var hasNewer = false
    public var isLoading = false { didSet { emptyStateManager.update(isEmpty: messages.isEmpty, isLoading: isLoading, showEmptyState: features.showEmptyState) } }
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

    public private(set) var isExternalUnreadManagement = false
    public var unreadCount: Int = 0 {
        didSet { fabManager.updateBadge(unreadCount: unreadCount) }
    }
    var unreadMessageIDs: Set<String> = []

    public func setUnreadCount(_ count: Int) {
        isExternalUnreadManagement = true
        unreadCount = count
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

    // MARK: - Initial Scroll

    public var isInitialScrollProtected = false
    public var pendingScrollMessageId: String?

    // MARK: - Data

    public internal(set) var messages: [ChatMessage] = []
    public internal(set) var messageIndex: [String: ChatMessage] = [:]
    /// O(1) lookup: messageId → row index
    var rowIndexCache: [String: Int] = [:]
    /// Cached date separator info for floating date manager
    var cachedDateSeparators: [(rowIndex: Int, groupDate: String)] = []
    /// Flat row array — the single source of truth for the collection view
    var rows: [ChatRow] = []

    // MARK: - Size Cache

    /// Cache of computed cell sizes keyed by message ID or groupDate
    var sizeCache: [String: CGSize] = [:]

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

    var isProgrammaticScroll = false
    var lastScrollEventTime: CFTimeInterval = 0
    var visibleMessageIDs: Set<String> = []
    var pendingVisibleIDs: Set<String> = []
    var visibilityDebounceTask: DispatchWorkItem?
    var pendingHighlightId: String?
    var isUserDragging = false
    var lastKnownMessageCount = 0
    public var pendingScrollToBottom = false
    public var isLoadingNewerActive = false

    // MARK: - Keyboard Freeze

    var isInsetFrozen = false
    var frozenBottomInset: CGFloat?
    var keyboardWasVisible = false
    var kbHideObserver: Any?
    var kbShowObserver: Any?

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
        setupFAB()
        setupFloatingDate()
        applyTheme()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCollectionInsets()
    }

    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateCollectionInsets()
    }

    deinit {
        floatingDateManager.cancelPendingTasks()
        visibilityDebounceTask?.cancel()
        pendingLoadingRebuild?.cancel()
        if let token = kbHideObserver { NotificationCenter.default.removeObserver(token) }
        if let token = kbShowObserver { NotificationCenter.default.removeObserver(token) }
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
        sizeCache.removeAll()
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
        sizeCache.removeAll()
        rows = buildRows(from: messages)
        chatLayout.rowLayoutData = computeLayoutData()
        UIView.transition(with: collectionView, duration: 0.25, options: .transitionCrossDissolve) {
            self.collectionView.reloadData()
        }
    }

    // MARK: - Update Messages

    private lazy var messageUpdateHandler = MessageUpdateHandler(controller: self)

    private var pendingMessages: [ChatMessage]?

    public func updateMessages(_ newMessages: [ChatMessage]) {
        pendingLoadingRebuild?.cancel()
        pendingLoadingRebuild = nil
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
        guard !isExternalUnreadManagement else { return }
        let delta = newMessages.count - oldCount
        guard delta > 0 else { return }
        let newIDs = newMessages.suffix(delta).filter { !$0.isMine }.map { $0.id }
        guard !newIDs.isEmpty else { return }
        unreadMessageIDs.formUnion(newIDs)
        unreadCount = unreadMessageIDs.count
    }

    public func clearUnread() {
        unreadMessageIDs.removeAll()
        unreadCount = 0
    }


    // MARK: - Scroll

    public func scrollToBottom(animated: Bool) {
        guard !messages.isEmpty else { return }
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

    func distanceFromBottom() -> CGFloat {
        guard let cv = collectionView else { return 0 }
        return max(0, cv.contentSize.height - cv.contentOffset.y - cv.bounds.height + cv.contentInset.bottom)
    }

    func isNearBottom() -> Bool {
        guard collectionView.contentSize.height > 0 else { return true }
        return distanceFromBottom() <= features.scrollToBottomThreshold
    }

    func updateFABVisibility(animated: Bool) {
        guard features.showFab else { return }
        fabManager.updateVisibility(isNearBottom: isNearBottom(), hasMessages: !messages.isEmpty, animated: animated)
        fabManager.updateBadge(unreadCount: unreadCount)
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
        guard !isInsetFrozen else { return }
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

        let distanceFromEnd = cv.contentSize.height - cv.contentOffset.y - cv.bounds.height + oldBottom
        cv.contentInset.bottom = newBottom
        cv.verticalScrollIndicatorInsets.bottom = newIndicatorBottom
        let newOffsetY = cv.contentSize.height - cv.bounds.height + newBottom - distanceFromEnd
        cv.contentOffset = CGPoint(x: 0, y: max(-cv.contentInset.top, newOffsetY))
    }

    @objc func dismissKeyboard() { view.endEditing(true) }
}

