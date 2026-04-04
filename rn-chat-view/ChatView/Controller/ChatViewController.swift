import IGListKit
import UIKit

final class ChatViewController: UIViewController {

    // MARK: - Public Configuration

    var theme: ChatTheme = .light {
        didSet { guard isViewLoaded, !isBatchUpdate else { return }; applyTheme() }
    }
    var layout: ChatLayout = ChatLayout() {
        didSet { guard isViewLoaded, !isBatchUpdate else { return }; reloadWithCrossfade() }
    }
    var features: ChatFeatures = ChatFeatures() {
        didSet { guard isViewLoaded, !isBatchUpdate else { return }; applyFeatureChanges(from: oldValue) }
    }

    private var isBatchUpdate = false

    /// Apply multiple configuration changes at once to avoid redundant reloads.
    func batchUpdate(_ block: () -> Void) {
        isBatchUpdate = true
        let oldFeatures = features
        block()
        isBatchUpdate = false
        applyTheme()
        applyFeatureChanges(from: oldFeatures)
    }

    // MARK: - Public Properties

    var contentFactory: ChatContentFactory = DefaultChatContentFactory()
    weak var delegate: ChatViewControllerDelegate?

    var hasMore = false
    var hasNewer = false
    var isLoading = false { didSet { emptyStateManager.update(isEmpty: messages.isEmpty, isLoading: isLoading, showEmptyState: features.showEmptyState) } }
    var isLoadingTop = false {
        didSet { if oldValue != isLoadingTop, isViewLoaded { updateTopLoadingOverlay() } }
    }
    var isLoadingBottom = false {
        didSet { if oldValue != isLoadingBottom, isViewLoaded { scheduleBottomLoadingRebuild() } }
    }
    private var pendingLoadingRebuild: DispatchWorkItem?
    private lazy var topLoadingSpinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .medium)
        s.hidesWhenStopped = true
        return s
    }()

    private(set) var isExternalUnreadManagement = false
    var unreadCount: Int = 0 {
        didSet { fabManager.updateBadge(unreadCount: unreadCount) }
    }
    var unreadMessageIDs: Set<String> = []

    func setUnreadCount(_ count: Int) {
        isExternalUnreadManagement = true
        unreadCount = count
    }

    var collectionExtraInsetTop: CGFloat = 0 {
        didSet {
            guard isViewLoaded else { return }
            floatingDateManager.updateTopConstraint(extraInsetTop: collectionExtraInsetTop)
            view.setNeedsLayout()
        }
    }
    var collectionExtraInsetBottom: CGFloat = 0 {
        didSet { guard isViewLoaded else { return }; view.setNeedsLayout() }
    }

    // MARK: - Initial Scroll

    var isInitialScrollProtected = false
    var pendingScrollMessageId: String?

    // MARK: - Data

    private(set) var messages: [ChatMessage] = []
    private(set) var messageIndex: [String: ChatMessage] = [:]
    private(set) var listItems: [ListDiffable] = []
    private(set) var cachedDateSeparators: [(index: Int, item: DateSeparatorListItem)] = []

    // MARK: - IGListKit

    private(set) var collectionView: ChatCollectionView!
    var adapter: ListAdapter!

    // MARK: - UI Components

    var inputBar: InputBarView!

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
    var pendingScrollToBottom = false
    var isLoadingNewerActive = false

    // MARK: - Keyboard Freeze

    var isInsetFrozen = false
    var frozenBottomInset: CGFloat?
    var keyboardWasVisible = false
    var kbHideObserver: Any?
    var kbShowObserver: Any?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        isInitialScrollProtected = true
        setupCollectionView()
        setupAdapter()
        setupInputBar()
        emptyStateManager.setup(in: view, inputBar: inputBar, layout: layout, theme: theme)
        emptyStateManager.onTap = { [weak self] in self?.view.endEditing(true) }
        setupFAB()
        setupFloatingDate()
        applyTheme()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCollectionInsets()
    }

    override func viewSafeAreaInsetsDidChange() {
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

    private func setupCollectionView() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0

        collectionView = ChatCollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.keyboardDismissMode = .interactive
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.alwaysBounceVertical = true
        collectionView.isPrefetchingEnabled = false
        collectionView.clipsToBounds = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false
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

    // MARK: - Setup Adapter

    private func setupAdapter() {
        let updater = ListAdapterUpdater()
        updater.allowsBackgroundDiffing = true
        adapter = ListAdapter(updater: updater, viewController: self)
        adapter.collectionView = collectionView
        adapter.dataSource = self
        adapter.scrollViewDelegate = self
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
        fabManager.setup(in: view, inputBar: inputBar, layout: layout, theme: theme, features: features)
        fabManager.onTap = { [weak self] in self?.delegate?.chatDidTapFAB() }
    }

    // MARK: - Setup Floating Date

    private func setupFloatingDate() {
        floatingDateManager.setup(
            in: view,
            safeAreaGuide: view.safeAreaLayoutGuide,
            layout: layout,
            theme: theme,
            extraInsetTop: collectionExtraInsetTop
        )
        if !features.showFloatingDate {
            floatingDateManager.setHidden(true)
        }
    }

    // MARK: - Theme

    func applyTheme() {
        guard isViewLoaded else { return }
        collectionView.backgroundColor = .clear
        emptyStateManager.applyTheme(theme)
        fabManager.applyTheme(theme)
        inputBar.applyTheme(theme.isDark ? .dark : .light)
        floatingDateManager.applyTheme(theme)
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
            rebuildListItems()
            adapter.performUpdates(animated: false)
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
        let ip = IndexPath(item: 0, section: first.index)
        if let cell = collectionView.cellForItem(at: ip) as? DateSeparatorCell {
            cell.contentView.alpha = hidden ? 0 : 1
        }
    }

    private func scheduleBottomLoadingRebuild() {
        pendingLoadingRebuild?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.rebuildListItems()
            self.adapter.performUpdates(animated: false)
        }
        pendingLoadingRebuild = work
        DispatchQueue.main.async(execute: work)
    }

    private func reloadWithCrossfade() {
        UIView.transition(with: collectionView, duration: 0.25, options: .transitionCrossDissolve) {
            self.adapter.reloadData(completion: nil)
        }
    }

    // MARK: - Update Messages

    private lazy var messageUpdateHandler = MessageUpdateHandler(controller: self)

    func updateMessages(_ newMessages: [ChatMessage]) {
        pendingLoadingRebuild?.cancel()
        pendingLoadingRebuild = nil
        messageUpdateHandler.update(with: newMessages)
    }

    /// Called by MessageUpdateHandler to apply new messages data.
    func applyMessages(_ newMessages: [ChatMessage]) {
        messages = newMessages
        messageIndex = Dictionary(newMessages.map { ($0.id, $0) }, uniquingKeysWith: { _, new in new })
        rebuildListItems()
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

    func clearUnread() {
        unreadMessageIDs.removeAll()
        unreadCount = 0
    }

    // MARK: - Build List Items

    private func rebuildListItems() {
        var items: [ListDiffable] = []
        var dateSeps: [(index: Int, item: DateSeparatorListItem)] = []
        let showSeps = features.showDateSeparators

        var currentGroup: String?
        for msg in messages {
            if showSeps, msg.groupDate != currentGroup {
                currentGroup = msg.groupDate
                let sep = DateSeparatorListItem(groupDate: msg.groupDate)
                dateSeps.append((index: items.count, item: sep))
                items.append(sep)
            }
            items.append(MessageListItem(message: msg))
        }

        if isLoadingBottom && features.showBottomLoadingIndicator {
            items.append(LoadingListItem(position: .bottom))
        }

        listItems = items
        cachedDateSeparators = dateSeps
    }

    // MARK: - Scroll

    func scrollToBottom(animated: Bool) {
        guard !messages.isEmpty else { return }
        collectionView.layoutIfNeeded()
        isProgrammaticScroll = true
        let maxY = collectionView.contentSize.height - collectionView.bounds.height + collectionView.contentInset.bottom
        if maxY > -collectionView.contentInset.top {
            collectionView.setContentOffset(CGPoint(x: 0, y: maxY), animated: animated)
        }
        if !animated { isProgrammaticScroll = false }
    }

    func scrollToMessage(id: String, position: String, animated: Bool, highlight: Bool) {
        guard let sectionIndex = listItems.firstIndex(where: {
            ($0 as? MessageListItem)?.message.id == id
        }) else { return }
        let totalSections = collectionView.numberOfSections
        guard sectionIndex < totalSections else { return }

        isProgrammaticScroll = true
        collectionView.layoutIfNeeded()

        let scrollPos: UICollectionView.ScrollPosition
        switch position {
        case "top": scrollPos = .top
        case "bottom": scrollPos = .bottom
        default: scrollPos = .centeredVertically
        }

        collectionView.scrollToItem(at: IndexPath(item: 0, section: sectionIndex),
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
        guard let sectionIndex = listItems.firstIndex(where: {
            ($0 as? MessageListItem)?.message.id == id
        }) else { return }
        let sc = adapter.sectionController(forSection: sectionIndex) as? MessageSectionController
        sc?.highlightCell()
    }

    // MARK: - Input Mode

    func beginReply(info: ReplyInfo) {
        inputBar.beginReply(info: InputBarReplyInfo(
            messageId: info.replyToId, senderName: info.senderName,
            text: info.text, hasImage: info.hasImage
        ))
    }
    func beginEdit(messageId: String, text: String) { inputBar.beginEdit(messageId: messageId, text: text) }
    func clearInputMode() { inputBar.cancelMode() }

    // MARK: - Helpers

    func message(forID id: String) -> ChatMessage? { messageIndex[id] }

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
