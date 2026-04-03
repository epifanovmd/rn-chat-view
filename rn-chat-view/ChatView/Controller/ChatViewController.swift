import IGListKit
import UIKit

final class ChatViewController: UIViewController {

    // MARK: - Public Properties

    weak var delegate: ChatViewControllerDelegate?

    var theme: ChatTheme = .light { didSet { applyTheme() } }
    var hasMore = false
    var hasNewer = false
    var topThreshold: CGFloat = 200
    var bottomThreshold: CGFloat = 200
    var isLoading = false { didSet { updateEmptyState() } }
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
    var scrollToBottomThreshold: CGFloat = 150 { didSet { updateFABVisibility(animated: false) } }
    var showsSenderName = false { didSet { if oldValue != showsSenderName, isViewLoaded { reloadWithCrossfade() } } }
    var showsFloatingDate = true
    private(set) var isExternalUnreadManagement = false
    var unreadCount: Int = 0 {
        didSet { updateFABBadge() }
    }
    var unreadMessageIDs: Set<String> = []

    /// Устанавливает unreadCount снаружи и переключает FAB в режим внешнего управления.
    /// После вызова внутренняя логика (trackNewUnread, clearUnread при скрытии FAB,
    /// автоматический scrollToBottom при нажатии) отключается.
    func setUnreadCount(_ count: Int) {
        isExternalUnreadManagement = true
        unreadCount = count
    }

    var emojiReactionsList: [String] = [] {
        didSet { contextMenuEmojis = emojiReactionsList.map { ContextMenuEmoji(emoji: $0) } }
    }

    var collectionExtraInsetTop: CGFloat = 0 {
        didSet {
            guard isViewLoaded else { return }
            floatingDateTopConstraint?.constant = ChatLayout.current.sectionSpacing + collectionExtraInsetTop
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

    var collectionView: ChatCollectionView!
    var adapter: ListAdapter!

    // MARK: - UI Components

    var inputBar: InputBarView!
    private let emptyContainer = UIView()
    private let emptyLabel = UILabel()
    private let centerSpinner = UIActivityIndicatorView(style: .large)
    let fabButton = UIButton(type: .custom)
    var fabBlurView: UIVisualEffectView!
    let fabArrow = UIImageView()
    let fabBadge = PaddedLabel(hPad: 6)

    // MARK: - Floating Date

    private let floatingDatePill = UIView()
    private var floatingDateTopConstraint: NSLayoutConstraint?
    private let floatingDateLabel = UILabel()
    private var floatingDateHideTask: DispatchWorkItem?
    private var currentFloatingDate: String?

    // MARK: - Context Menu

    var contextMenuEmojis: [ContextMenuEmoji] = []

    // MARK: - Audio

    let voiceRecorder = VoiceRecorder()

    // MARK: - Constraints

    var inputBarKeyboardConstraint: NSLayoutConstraint?
    private let inputBarBackground = UIView()

    // MARK: - Scroll State

    var isFabVisible = false
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

    // MARK: - Scroll Compensation

    var savedOffsetForAppend: CGPoint?

    // MARK: - Keyboard Freeze (контекстное меню)

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
        setupEmptyState()
        setupInputBar()
        setupFAB()
        setupFloatingDate()
        applyTheme()
        voiceRecorder.delegate = self
        warmUpKeyboard()
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
        floatingDateHideTask?.cancel()
        visibilityDebounceTask?.cancel()
        pendingLoadingRebuild?.cancel()
        if let token = kbHideObserver { NotificationCenter.default.removeObserver(token) }
        if let token = kbShowObserver { NotificationCenter.default.removeObserver(token) }
        KeyboardListener.shared.remove(delegate: self)
    }

    // MARK: - Setup Collection View

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        collectionView = ChatCollectionView(frame: .zero, collectionViewLayout: layout)
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
        updater.delegate = self
        updater.allowsBackgroundDiffing = true
        adapter = ListAdapter(updater: updater, viewController: self)
        adapter.collectionView = collectionView
        adapter.dataSource = self
        adapter.scrollViewDelegate = self
    }

    // MARK: - Setup Empty State

    private func setupEmptyState() {
        emptyContainer.isHidden = true
        emptyContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyContainer)

        emptyLabel.text = NSLocalizedString("chat.empty", value: "Сообщений пока нет.\nНапишите первым!", comment: "")
        emptyLabel.font = ChatLayout.current.emptyStateFont
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyContainer.addSubview(emptyLabel)

        centerSpinner.hidesWhenStopped = true
        centerSpinner.translatesAutoresizingMaskIntoConstraints = false
        emptyContainer.addSubview(centerSpinner)

        NSLayoutConstraint.activate([
            emptyContainer.topAnchor.constraint(equalTo: view.topAnchor),
            emptyContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            emptyLabel.centerXAnchor.constraint(equalTo: emptyContainer.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: emptyContainer.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: emptyContainer.leadingAnchor, constant: ChatLayout.current.emptyStatePadding),
            centerSpinner.centerXAnchor.constraint(equalTo: emptyContainer.centerXAnchor),
            centerSpinner.centerYAnchor.constraint(equalTo: emptyContainer.centerYAnchor),
        ])
    }

    // MARK: - Setup Input Bar

    private func setupInputBar() {
        // Фон под inputBar — продлевается до самого низа (за safe area)
        inputBarBackground.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputBarBackground)

        inputBar = InputBarView()
        inputBar.delegate = self
        inputBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputBar)

        NSLayoutConstraint.activate([
            inputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBarBackground.topAnchor.constraint(equalTo: inputBar.topAnchor),
            inputBarBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBarBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBarBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        if #available(iOS 15.0, *) {
            view.keyboardLayoutGuide.followsUndockedKeyboard = true
            let c = inputBar.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
            c.isActive = true
            inputBarKeyboardConstraint = c
        } else {
            let c = inputBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            c.isActive = true
            inputBarKeyboardConstraint = c
            KeyboardListener.shared.add(delegate: self)
        }
    }

    // MARK: - Keyboard Warm-Up

    private func warmUpKeyboard() {
        let field = UITextField(frame: .zero)
        view.addSubview(field)
        field.becomeFirstResponder()
        field.resignFirstResponder()
        field.removeFromSuperview()
    }

    // MARK: - Setup FAB

    private func setupFAB() {
        let size = InputBarLayout.current.buttonSize
        fabButton.translatesAutoresizingMaskIntoConstraints = false
        fabButton.layer.cornerRadius = size / 2
        fabButton.layer.borderWidth = InputBarLayout.current.borderWidth
        fabButton.alpha = 0
        fabButton.isUserInteractionEnabled = false
        fabButton.addTarget(self, action: #selector(fabTapped), for: .touchUpInside)
        view.addSubview(fabButton)

        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        fabArrow.image = UIImage(systemName: "chevron.down", withConfiguration: config)
        fabArrow.contentMode = .scaleAspectFit
        fabArrow.translatesAutoresizingMaskIntoConstraints = false
        fabArrow.isUserInteractionEnabled = false
        fabButton.addSubview(fabArrow)

        // Badge
        fabBadge.font = ChatLayout.current.fabBadgeFont
        fabBadge.textColor = theme.fabBadgeTextColor
        fabBadge.backgroundColor = theme.fabBadgeBackground
        fabBadge.textAlignment = .center
        fabBadge.layer.cornerRadius = ChatLayout.current.fabBadgeCornerRadius
        fabBadge.layer.masksToBounds = true
        fabBadge.translatesAutoresizingMaskIntoConstraints = false
        fabBadge.isHidden = true
        fabBadge.isUserInteractionEnabled = false
        view.addSubview(fabBadge)

        // Align FAB above right button — anchor to inputBar.bottom offset by padding+buttonHeight+margin
        let IB = InputBarLayout.current
        let hPad = IB.barHPad
        let bottomOffset = IB.barVPad + size + ChatLayout.current.fabMargin
        NSLayoutConstraint.activate([
            fabButton.widthAnchor.constraint(equalToConstant: size),
            fabButton.heightAnchor.constraint(equalToConstant: size),
            fabButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -hPad),
            fabButton.bottomAnchor.constraint(equalTo: inputBar.bottomAnchor, constant: -bottomOffset),
            fabArrow.centerXAnchor.constraint(equalTo: fabButton.centerXAnchor),
            fabArrow.centerYAnchor.constraint(equalTo: fabButton.centerYAnchor),
            fabBadge.centerXAnchor.constraint(equalTo: fabButton.leadingAnchor, constant: 4),
            fabBadge.centerYAnchor.constraint(equalTo: fabButton.topAnchor, constant: 4),
            fabBadge.heightAnchor.constraint(equalToConstant: ChatLayout.current.fabBadgeHeight),
            fabBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: ChatLayout.current.fabBadgeMinWidth),
        ])
    }

    func rebuildFABBlur() {
        // No longer using blur — FAB uses same solid bg as input buttons
    }

    // MARK: - Setup Floating Date

    private func setupFloatingDate() {
        floatingDatePill.translatesAutoresizingMaskIntoConstraints = false
        floatingDatePill.layer.cornerRadius = ChatLayout.current.dateSeparatorCornerRadius
        floatingDatePill.alpha = 0
        view.addSubview(floatingDatePill)

        floatingDateLabel.font = ChatLayout.current.dateSeparatorFont
        floatingDateLabel.textAlignment = .center
        floatingDateLabel.translatesAutoresizingMaskIntoConstraints = false
        floatingDatePill.addSubview(floatingDateLabel)

        let topC = floatingDatePill.topAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.topAnchor,
            constant: ChatLayout.current.sectionSpacing + collectionExtraInsetTop
        )
        floatingDateTopConstraint = topC

        NSLayoutConstraint.activate([
            floatingDatePill.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            topC,
            floatingDateLabel.topAnchor.constraint(equalTo: floatingDatePill.topAnchor, constant: ChatLayout.current.dateSeparatorVPad),
            floatingDateLabel.bottomAnchor.constraint(equalTo: floatingDatePill.bottomAnchor, constant: -ChatLayout.current.dateSeparatorVPad),
            floatingDateLabel.leadingAnchor.constraint(equalTo: floatingDatePill.leadingAnchor, constant: ChatLayout.current.dateSeparatorHPad),
            floatingDateLabel.trailingAnchor.constraint(equalTo: floatingDatePill.trailingAnchor, constant: -ChatLayout.current.dateSeparatorHPad),
        ])
    }

    func updateFloatingDate() {
        guard showsFloatingDate, !messages.isEmpty else { hideFloatingDate(); return }

        let spacing = ChatLayout.current.sectionSpacing

        // Используем кешированные индексы разделителей дат
        struct DateInfo {
            let groupDate: String
            let minY: CGFloat
            let maxY: CGFloat
        }
        var dateSections: [DateInfo] = []

        for (index, item) in cachedDateSeparators {
            guard let attrs = collectionView.layoutAttributesForItem(at: IndexPath(item: 0, section: index)) else { continue }
            let f = collectionView.convert(attrs.frame, to: view)
            dateSections.append(DateInfo(groupDate: item.groupDate, minY: f.minY, maxY: f.maxY))
        }

        guard !dateSections.isEmpty else { return }

        // Позиция pill в координатах view
        let pillRestY = view.safeAreaLayoutGuide.layoutFrame.minY + spacing + collectionExtraInsetTop
        let pillH = floatingDatePill.bounds.height > 0
            ? floatingDatePill.bounds.height
            : ChatLayout.current.dateSeparatorFont.lineHeight + ChatLayout.current.dateSeparatorVPad * 2
        let pillBottom = pillRestY + pillH

        // Текущая дата — последняя, чей низ ушёл выше pill + spacing (ячейка полностью за pill)
        var currentDate: String?
        var currentDatePassed = false
        var nextInfo: DateInfo?

        for (i, info) in dateSections.enumerated() {
            if info.maxY < pillRestY - spacing {
                currentDate = info.groupDate
                currentDatePassed = true
                nextInfo = (i + 1 < dateSections.count) ? dateSections[i + 1] : nil
            }
        }

        // Если ни одна дата ещё не прошла pill — ячейка видна, pill не нужен
        if !currentDatePassed {
            currentFloatingDate = nil
            hideFloatingDate()
            return
        }

        guard let groupDate = currentDate else { return }

        // Выталкивание: начинается когда верх следующей даты на расстоянии spacing от pill bottom
        if let next = nextInfo {
            let triggerY = pillBottom + spacing
            if next.minY < triggerY {
                let pushOffset = next.minY - triggerY  // от 0 до -(pillH + 2*spacing)
                floatingDatePill.transform = CGAffineTransform(translationX: 0, y: pushOffset)
            } else {
                floatingDatePill.transform = .identity
            }
        } else {
            floatingDatePill.transform = .identity
        }

        // Обновляем текст — после push-off fade in
        let dateDidChange = groupDate != currentFloatingDate
        if dateDidChange {
            currentFloatingDate = groupDate
            floatingDateLabel.text = DateHelper.shared.sectionTitle(from: groupDate)
            floatingDatePill.transform = .identity
            floatingDatePill.alpha = 0  // showFloatingDate() сделает fade-in
        }

        showFloatingDate()
    }

    private func showFloatingDate() {
        let L = ChatLayout.current
        floatingDateHideTask?.cancel()
        if floatingDatePill.alpha < 1 {
            UIView.animate(withDuration: L.floatingDateShowDuration) { self.floatingDatePill.alpha = 1 }
        }
        let task = DispatchWorkItem { [weak self] in
            guard let self else { return }
            UIView.animate(withDuration: L.floatingDateHideDuration) { self.floatingDatePill.alpha = 0 }
        }
        floatingDateHideTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + L.floatingDateHideDelay, execute: task)
    }

    private func hideFloatingDate() {
        floatingDateHideTask?.cancel()
        UIView.animate(withDuration: ChatLayout.current.floatingDateHideDuration) {
            self.floatingDatePill.alpha = 0
            self.floatingDatePill.transform = .identity
        }
    }

    // MARK: - Theme

    func applyTheme() {
        guard isViewLoaded else { return }
        collectionView.backgroundColor = .clear
        emptyLabel.textColor = theme.emptyStateText
        let ibTheme = InputBarTheme.from(theme)
        fabButton.backgroundColor = ibTheme.background
        fabButton.layer.borderColor = ibTheme.border.cgColor
        fabArrow.tintColor = theme.fabArrowColor
        fabBadge.backgroundColor = theme.fabBadgeBackground
        fabBadge.textColor = theme.fabBadgeTextColor
        inputBar.applyTheme(.from(theme))
        inputBarBackground.backgroundColor = .clear
        floatingDatePill.backgroundColor = theme.dateSeparatorBackground
        floatingDateLabel.textColor = theme.dateSeparatorText
        reloadWithCrossfade()
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

    func updateMessages(_ newMessages: [ChatMessage]) {
        pendingLoadingRebuild?.cancel()
        pendingLoadingRebuild = nil
        let wasAtBottom = isNearBottom()
        let wasEmpty = messages.isEmpty
        let oldFirstId = messages.first?.id
        let oldLastId = messages.last?.id
        let oldCount = messages.count

        messages = newMessages
        messageIndex = Dictionary(newMessages.map { ($0.id, $0) }, uniquingKeysWith: { _, new in new })
        rebuildListItems()

        let grew = newMessages.count > oldCount

        let isPrepend = !wasEmpty && grew
            && oldFirstId != nil && oldFirstId != newMessages.first?.id
            && oldLastId == newMessages.last?.id

        let isAppendAtBottom = !wasEmpty && grew
            && oldLastId != nil && oldLastId != newMessages.last?.id

        if isPrepend {
            handlePrepend(oldFirstId: oldFirstId, count: newMessages.count)
        } else if isAppendAtBottom {
            handleAppend(wasAtBottom: wasAtBottom, oldCount: oldCount, newMessages: newMessages)
        } else if wasEmpty && !newMessages.isEmpty {
            handleInitialLoad(count: newMessages.count)
        } else {
            handleContentUpdate(count: newMessages.count)
        }
    }

    // MARK: - Update Handlers

    private func handlePrepend(oldFirstId: String?, count: Int) {
        collectionView.prePrependContentHeight = collectionView.contentSize.height
        collectionView.prePrependContentOffset = collectionView.contentOffset.y
        collectionView.needsPrependCompensation = true

        adapter.performUpdates(animated: false) { [weak self] _ in
            guard let self else { return }
            self.finalizeUpdate(count: count, animated: false)
        }
    }

    private func handleAppend(wasAtBottom: Bool, oldCount: Int, newMessages: [ChatMessage]) {
        let wasLoadingNewer = isLoadingNewerActive
        let wantScroll = pendingScrollToBottom || (wasAtBottom && !isLoadingNewerActive)
        isLoadingNewerActive = false

        if wantScroll {
            pendingScrollToBottom = false
            adapter.performUpdates(animated: false) { [weak self] _ in
                guard let self else { return }
                self.scrollToBottom(animated: true)
                self.finalizeUpdate(count: newMessages.count, animated: false)
            }
        } else {
            if !wasLoadingNewer && !wasAtBottom {
                trackNewUnread(newMessages: newMessages, oldCount: oldCount)
            }
            savedOffsetForAppend = collectionView.contentOffset
            adapter.performUpdates(animated: false) { [weak self] _ in
                guard let self else { return }
                self.finalizeUpdate(count: newMessages.count, animated: false)
            }
        }
    }

    private func handleInitialLoad(count: Int) {
        adapter.reloadData { [weak self] _ in
            guard let self else { return }
            if let scrollId = self.pendingScrollMessageId {
                self.scrollToMessage(id: scrollId, position: "center", animated: false, highlight: true)
                self.pendingScrollMessageId = nil
            } else {
                self.scrollToBottom(animated: false)
            }
            self.isInitialScrollProtected = false
            self.finalizeUpdate(count: count, animated: false)
        }
    }

    private func handleContentUpdate(count: Int) {
        let shouldScroll = pendingScrollToBottom
        if shouldScroll { pendingScrollToBottom = false }

        adapter.performUpdates(animated: !shouldScroll) { [weak self] _ in
            guard let self else { return }
            if shouldScroll { self.scrollToBottom(animated: true) }
            self.finalizeUpdate(count: count, animated: !shouldScroll)
        }
    }

    private func finalizeUpdate(count: Int, animated: Bool) {
        lastKnownMessageCount = count
        updateEmptyState()
        updateFABVisibility(animated: animated)
    }

    private func trackNewUnread(newMessages: [ChatMessage], oldCount: Int) {
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

        var currentGroup: String?
        for msg in messages {
            if msg.groupDate != currentGroup {
                currentGroup = msg.groupDate
                let sep = DateSeparatorListItem(groupDate: msg.groupDate)
                dateSeps.append((index: items.count, item: sep))
                items.append(sep)
            }
            items.append(MessageListItem(message: msg))
        }

        if isLoadingBottom {
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
        return distanceFromBottom() <= scrollToBottomThreshold
    }

    func updateFABVisibility(animated: Bool) {
        let shouldShow = !isNearBottom() && !messages.isEmpty
        guard shouldShow != isFabVisible else { return }
        isFabVisible = shouldShow
        let alpha: CGFloat = shouldShow ? 1 : 0
        fabButton.isUserInteractionEnabled = shouldShow
        updateFABBadge()
        let badgeAlpha: CGFloat = (shouldShow && unreadCount > 0) ? 1 : 0
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.fabButton.alpha = alpha
                self.fabBadge.alpha = badgeAlpha
            }
        } else {
            fabButton.alpha = alpha
            fabBadge.alpha = badgeAlpha
        }
    }

    func updateFABBadge() {
        fabBadge.isHidden = unreadCount == 0 || !isFabVisible
        guard unreadCount > 0 else { return }
        fabBadge.text = unreadCount > 99 ? "99+" : "\(unreadCount)"
    }

    func updateEmptyState() {
        let isEmpty = messages.isEmpty
        emptyContainer.isHidden = !isEmpty
        if isEmpty && isLoading {
            emptyLabel.isHidden = true
            centerSpinner.startAnimating()
        } else {
            centerSpinner.stopAnimating()
            emptyLabel.isHidden = false
        }
    }

    func updateCollectionInsets() {
        guard !isInsetFrozen else { return }
        guard let cv = collectionView else { return }
        guard inputBar != nil, inputBar.frame.height > 0, view.bounds.height > 0 else { return }

        let safeTop = view.safeAreaInsets.top

        // Top inset: safe area + extra
        let newTop = safeTop + collectionExtraInsetTop
        if abs(cv.contentInset.top - newTop) > 0.5 {
            cv.contentInset.top = newTop
            cv.verticalScrollIndicatorInsets.top = collectionExtraInsetTop
        }

        // Bottom inset: inputBar zone + extra
        let inputBarZone = view.bounds.height - inputBar.frame.minY
        let newBottom = inputBarZone + ChatLayout.current.collectionBottomPadding + collectionExtraInsetBottom
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
    @objc func fabTapped() {
        delegate?.chatDidTapFAB()
    }
}

// MARK: - PaddedLabel

final class PaddedLabel: UILabel {
    private let hPad: CGFloat

    init(hPad: CGFloat) {
        self.hPad = hPad
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + hPad * 2, height: size.height)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.insetBy(dx: hPad, dy: 0))
    }
}
