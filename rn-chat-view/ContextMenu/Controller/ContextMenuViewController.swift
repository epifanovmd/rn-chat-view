import UIKit

// MARK: - ContextMenuDelegate

public protocol ContextMenuDelegate: AnyObject {
    func contextMenu(_ menu: ContextMenuViewController, didSelectEmoji emoji: String, forId id: String)
    func contextMenu(_ menu: ContextMenuViewController, didSelectAction action: ContextMenuAction, forId id: String)
    func contextMenuDidDismiss(_ menu: ContextMenuViewController, id: String)
}

// MARK: - ContextMenuViewController

public final class ContextMenuViewController: UIViewController {

    // MARK: - Public

    public weak var delegate:              ContextMenuDelegate?
    public private(set) var configuration: ContextMenuConfiguration
    public var theme: ContextMenuTheme { didSet { applyTheme() } }

    // MARK: - Private

    private var isDismissing:     Bool = false
    private var didPerformLayout: Bool = false
    private var layout:           ContextMenuLayout?
    private var animator:         ContextMenuAnimator?
    private var sourceFrameInWindow: CGRect = .zero

    private let backdrop   = ContextMenuBackdropView()
    private let scrollView = UIScrollView.contextMenuStyle()
    private let canvas     = UIView()
    private var snapshotView: UIView?

    // Панели создаются только если переданы данные
    private var emojiPanel:   ContextMenuEmojiPanel?
    private var actionsPanel: ContextMenuActionsView?

    // MARK: - Init

    public init(configuration: ContextMenuConfiguration, theme: ContextMenuTheme = .light) {
        self.configuration = configuration
        self.theme         = theme
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle   = .crossDissolve

        if let window = configuration.sourceView.window {
            sourceFrameInWindow = configuration.sourceView.convert(
                configuration.sourceView.bounds, to: window
            )
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented — use init(configuration:theme:)")
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupBackdrop()
        setupScrollView()
        buildContent()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !didPerformLayout, view.bounds.width > 0 else { return }
        didPerformLayout = true
        applyLayout()
        configuration.sourceView.alpha = 0
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let layout, let animator else { return }
        animator.animateOpen(layout: layout)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        configuration.sourceView.alpha = 1
    }

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        presentingViewController?.preferredStatusBarStyle ?? .default
    }

    // MARK: - Public API

    public func dismissMenu() {
        close { [weak self] in
            guard let self else { return }
            self.delegate?.contextMenuDidDismiss(self, id: self.configuration.id)
        }
    }

    /// Показывает меню. Если нет ни эмодзи, ни действий — не открывает ничего.
    public static func present(
        configuration: ContextMenuConfiguration,
        theme: ContextMenuTheme = .light,
        from vc: UIViewController,
        delegate: ContextMenuDelegate? = nil
    ) {
        guard !configuration.emojis.isEmpty || !configuration.actions.isEmpty else { return }
        let menu      = ContextMenuViewController(configuration: configuration, theme: theme)
        menu.delegate = delegate
        vc.present(menu, animated: false)
    }

    // MARK: - Setup

    private func setupBackdrop() {
        backdrop.configure(with: theme)
        backdrop.frame            = view.bounds
        backdrop.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(backdrop)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleBackdropTap))
        tap.cancelsTouchesInView = false
        tap.delegate             = self
        view.addGestureRecognizer(tap)
    }

    private func setupScrollView() {
        scrollView.frame            = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scrollView)
        scrollView.addSubview(canvas)
    }

    /// Создаёт только те панели, данные для которых непусты.
    private func buildContent() {
        snapshotView = makeSnapshotView(for: configuration.sourceView)
        if let snap = snapshotView { canvas.addSubview(snap) }

        if !configuration.emojis.isEmpty {
            let panel = ContextMenuEmojiPanel(theme: theme)
            panel.configure(with: configuration.emojis)
            panel.onEmojiTap = { [weak self] emoji in self?.selectEmoji(emoji) }
            canvas.addSubview(panel)
            emojiPanel = panel
        }

        if !configuration.actions.isEmpty {
            let panel = ContextMenuActionsView(theme: theme)
            panel.configure(with: configuration.actions)
            panel.onActionTap = { [weak self] action in self?.selectAction(action) }
            canvas.addSubview(panel)
            actionsPanel = panel
        }
    }

    // MARK: - Layout

    private func applyLayout() {
        let sourceFrame = view.convert(sourceFrameInWindow, from: view.window)

        let emojiSize = emojiPanel.map {
            $0.preferredSize(for: configuration.emojis)
        } ?? .zero

        let actionsSize = actionsPanel.map {
            CGSize(width: theme.menuWidth, height: $0.preferredHeight(for: configuration.actions))
        } ?? .zero

        let computed = ContextMenuLayoutEngine.calculate(
            sourceFrame: sourceFrame,
            snapSize:    configuration.sourceView.bounds.size,
            emojiSize:   emojiSize,
            actionsSize: actionsSize,
            screen:      view.bounds,
            safeArea:    view.safeAreaInsets,
            theme:       theme
        )
        layout = computed

        canvas.frame               = CGRect(origin: .zero, size: computed.canvasSize)
        scrollView.contentSize     = computed.canvasSize
        scrollView.isScrollEnabled = computed.needsScroll
        scrollView.contentOffset   = CGPoint(x: 0, y: computed.scrollOffset)

        animator = ContextMenuAnimator(
            theme:        theme,
            backdrop:     backdrop,
            snapshot:     snapshotView,
            emojiPanel:   emojiPanel,
            actionsPanel: actionsPanel
        )
        animator?.prepareOpen(layout: computed)
    }

    // MARK: - Actions

    @objc private func handleBackdropTap() { dismissMenu() }

    private func selectEmoji(_ emoji: String) {
        close { [weak self] in
            guard let self else { return }
            self.delegate?.contextMenu(self, didSelectEmoji: emoji, forId: self.configuration.id)
        }
    }

    private func selectAction(_ action: ContextMenuAction) {
        close { [weak self] in
            guard let self else { return }
            self.delegate?.contextMenu(self, didSelectAction: action, forId: self.configuration.id)
        }
    }

    // MARK: - Animation + Dismiss

    private func close(completion: @escaping () -> Void) {
        guard !isDismissing, let layout, let animator else { return }
        isDismissing = true

        let srcInView   = view.convert(sourceFrameInWindow, from: view.window)
        let offset      = scrollView.contentOffset.y
        let returnFrame = CGRect(x: srcInView.minX, y: srcInView.minY + offset,
                                 width: srcInView.width, height: srcInView.height)

        animator.animateClose(returnFrame: returnFrame, layout: layout) { [weak self] in
            self?.dismiss(animated: false, completion: completion)
        }
    }

    // MARK: - Theme

    private func applyTheme() {
        backdrop.configure(with: theme)
    }

    // MARK: - Helpers

    /// Создаёт снапшот sourceView.
    /// Радиус скругления берётся из configuration.snapshotCornerRadius —
    /// ContextMenu не знает о деталях рендера чата (нет coupling с ChatLayoutConstants).
    private func makeSnapshotView(for source: UIView) -> UIView? {
        guard let snap = source.snapshotView(afterScreenUpdates: false) else { return nil }
        snap.frame                    = CGRect(origin: .zero, size: source.bounds.size)
        snap.isUserInteractionEnabled = false
        snap.layer.cornerRadius       = configuration.snapshotCornerRadius
        snap.layer.cornerCurve        = .continuous
        snap.layer.masksToBounds      = true

        let wrapper = UIView(frame: CGRect(origin: .zero, size: source.bounds.size))
        wrapper.layer.shadowColor   = UIColor.black.cgColor
        wrapper.layer.shadowOpacity = ChatLayout.current.bubbleShadowOpacity
        wrapper.layer.shadowRadius  = ChatLayout.current.bubbleShadowRadius
        wrapper.layer.shadowOffset  = CGSize(width: 0, height: 3)
        wrapper.addSubview(snap)
        return wrapper
    }
}

// MARK: - UIGestureRecognizerDelegate

extension ContextMenuViewController: UIGestureRecognizerDelegate {

    public func gestureRecognizer(_ gr: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let pt = touch.location(in: canvas)
        let panels: [UIView] = [snapshotView, emojiPanel, actionsPanel].compactMap { $0 }
        return !panels.contains { $0.frame.contains(pt) }
    }

    public func gestureRecognizer(_ gr: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
}

// MARK: - ContextMenuBackdropView

private final class ContextMenuBackdropView: UIView {

    private let blurView  = UIVisualEffectView()
    private let colorView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        [blurView, colorView].forEach {
            $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview($0)
        }
        alpha = 0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented — use init(frame:)")
    }

    func configure(with theme: ContextMenuTheme) {
        blurView.effect           = UIBlurEffect(style: theme.backdropBlurStyle)
        colorView.backgroundColor = theme.backdropColor
        blurView.frame  = bounds
        colorView.frame = bounds
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        blurView.frame  = bounds
        colorView.frame = bounds
    }
}

// MARK: - UIScrollView factory

private extension UIScrollView {
    static func contextMenuStyle() -> UIScrollView {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator   = false
        sv.showsHorizontalScrollIndicator = false
        sv.contentInsetAdjustmentBehavior = .never
        sv.backgroundColor                = .clear
        sv.alwaysBounceVertical           = false
        sv.delaysContentTouches           = false
        sv.canCancelContentTouches        = true
        return sv
    }
}
