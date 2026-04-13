# IOSChatView

Production-ready iOS native chat UI component library.

## Tech Stack

- **Language:** Swift 5.9
- **UI:** UIKit (programmatic, no storyboards)
- **Diff engine:** DifferenceKit 1.3 (CocoaPods / SPM)
- **Layout:** Custom `ChatCollectionViewLayout` (pre-computed heights, binary search)
- **Audio:** AVFoundation, AudioToolbox
- **Min iOS:** 15.0 (podspec 15.1)

## Architecture

**Content-agnostic design.** The library core knows nothing about message types (images, voice, poll, etc.). All content rendering and interaction handling is delegated to `ChatContentFactory`. Built-in types ship in `DefaultContent/` as opt-in defaults.

Delegate-based composition. `ChatViewController` is the main orchestrator, split into 5 extensions:

- `+Data` — row building, layout data computation, size cache, message index
- `+Scroll` — UICollectionViewDelegate with throttled events, pagination, visibility tracking
- `+Input` — InputBarDelegate conformance, forwards to ChatViewControllerDelegate
- `+ContextMenu` — long-press context menu presentation (uses KeyboardFreezeManager)
- `+MessageActions` — routes cell interaction callbacks to delegate

Extracted managers:
- `MessageUpdateHandler` — routes updates (initial/prepend/append/content/replace/structural), bottom-edge-stable offset, incremental patching
- `FloatingDateManager` — floating date pill during scrolling
- `FABManager` — scroll-to-bottom button + unread badge (views from factory)
- `EmptyStateManager` — empty state view (views from factory)
- `KeyboardFreezeManager` — keyboard freeze/restore during context menu
- `UnreadManager` — unread message tracking and count
- `SizeCache` — width-aware cell size cache

### Data Flow

```
[ChatMessage] → buildRows() → [ChatRow] (flat array with date separators + loading)
                                    ↓
                          computeLayoutData() → [RowLayoutInfo] (pre-computed heights)
                                    ↓
                     ChatCollectionViewLayout (custom UICollectionViewLayout)
                                    ↓
                  ChatDataSource (standard UICollectionViewDataSource)
```

### Update Strategies (MessageUpdateHandler)

| Strategy | When | Method |
|----------|------|--------|
| Initial | First batch (was empty) | `reloadData` + sync scroll to bottom |
| Prepend | Older messages loaded | Full layout recompute + `reloadData` + offset compensation |
| Append | New messages at bottom | `reloadData` + auto-scroll if near bottom |
| Content | Edit/reactions/polls (same IDs) | Incremental patch + in-place reconfigure |
| Replace | Delete+insert at same position | Targeted `reloadItems(at:)` + offset fix |
| Structural | Row count changed | DifferenceKit `StagedChangeset` → animated batch |

**Bottom-edge-stable offset**: content and replace updates pin the
bottommost visible message's bottom edge to its screen position.
Height changes expand upward. Uses prefix sums for O(1) cell Y lookup.

**Incremental patching** (content/replace paths):
- `analyzeContent()` — single O(messages) pass: classifies, collects changedIDs, invalidates size cache
- `patchLayoutData()` — recomputes layout only for changed rows, O(changed) not O(n)
- messageIndex/rows/rowIndexCache patched incrementally

**DifferenceKit** used only in `applyStructural` (row count differs).
All other paths bypass it for better performance.

**Performance (90k messages):** content ~142ms, replace ~92ms, structural ~465ms.

### Delegate Hierarchy

```
ChatViewControllerDelegate (typealias combining 4 focused protocols):
  ├── ChatScrollDelegate       — scroll, pagination, FAB tap
  ├── ChatVisibilityDelegate   — visible messages (throttle) + unread messages (debounce)
  ├── ChatMessageDelegate      — tap, long press, reactions, replies, threads, links, chatDidContentInteraction
  └── ChatInputDelegate        — send, edit, attachment, voice recording

InputBarDelegate               — input bar events → ChatViewController → ChatViewControllerDelegate
ContextMenuDelegate            — context menu events (emoji, actions, dismiss)
```

### Configuration

```
ChatViewController properties:
  .theme: ChatTheme        — 50+ color properties, light/dark presets
                             New: systemBubble, systemText, systemTime (system messages)
                             New: pinnedBubble, pinnedText, pinnedTime (pinned messages)
  .layout: ChatLayout      — 350+ sizing/spacing/font parameters
                             New: threadBarHeight, threadBarFont, threadBarSpacing,
                                  threadBarIconSize, threadBarChevronSize (thread indicator)
                             New: systemCellBottomSpacing (system message extra spacing)
                             New: pinnedCellBottomSpacing (pinned message extra spacing)
                             New: avatarSize (36), avatarLeadingMargin (6),
                                  avatarBubbleSpacing (2) (sticky avatars)
  .features: ChatFeatures  — behavioral flags (show/hide UI elements)
  .contentFactory: ChatContentFactory — custom view creation (protocol)

  // Visibility tracking (direct properties, not in layout)
  .visibleMessagesThrottleInterval: TimeInterval  — throttle for visible snapshot (default 0.3s)
  .unreadMessagesDebounceInterval: TimeInterval   — debounce for unread batch (default 0.3s)
  .visibilityThreshold: CGFloat                   — enter visible set at 80% cell height visible
  .visibilityExitThreshold: CGFloat               — exit visible set below 50% (hysteresis)
  .unreadVisibilityThreshold: CGFloat             — mark-as-read at 50% visible

batchUpdate { } — apply multiple config changes atomically (single reload)
```

Context menu: `ContextMenuTheme.snapOpenShift: CGFloat = 6` — subtle horizontal shift on open.
`snapX` now uses `sourceFrame.minX` directly (no clamp).

## Project Structure

```
Sources/IOSChatView/
├── ChatView/                                  # CORE — content-agnostic
│   ├── Controller/
│   │   ├── ChatViewController.swift           # Main controller, public API
│   │   ├── ChatViewController+Data.swift      # Row building, layout, size cache
│   │   ├── ChatViewController+Scroll.swift    # Scroll delegate, pagination, visibility
│   │   ├── ChatViewController+Input.swift     # Input bar delegate forwarding
│   │   ├── ChatViewController+ContextMenu.swift # Context menu presentation
│   │   ├── ChatViewController+MessageActions.swift # Cell interaction → delegate
│   │   └── ChatViewControllerDelegate.swift   # 4 delegate protocols
│   ├── DataSource/
│   │   ├── ChatDataSource.swift               # UICollectionViewDataSource
│   │   └── ChatRow.swift                      # Differentiable row enum
│   ├── Components/
│   │   ├── MessageUpdateHandler.swift         # Update router + incremental patch + offset calculator
│   │   ├── FloatingDateManager.swift          # Floating date pill
│   │   ├── FABManager.swift                   # Scroll-to-bottom FAB + badge (views from factory)
│   │   ├── EmptyStateManager.swift            # Empty state (views from factory)
│   │   ├── KeyboardFreezeManager.swift        # Keyboard freeze/restore for context menu
│   │   └── UnreadManager.swift                # Unread message tracking
│   ├── Views/
│   │   ├── ChatCollectionViewLayout.swift     # Custom layout (pre-computed, binary search, avatar supplementary views)
│   │   ├── MessageCell.swift                  # Message cell with gesture handlers
│   │   ├── MessageBubbleView.swift            # Bubble assembly (text, content, footer, etc.)
│   │   ├── AvatarSupplementaryView.swift      # Sticky avatar supplementary view
│   │   ├── DateSeparatorCell.swift            # Date separator cell
│   │   ├── LoadingCell.swift                  # Loading indicator cell (view from factory)
│   │   ├── PaddedLabel.swift                  # Utility label
│   │   └── Content/
│   │       ├── TextContentView.swift          # Text with NSDataDetector link/phone detection
│   │       ├── ReactionsView.swift            # Emoji reaction chips
│   │       ├── ReplyPreviewView.swift         # Quoted message preview
│   │       └── MessageStatusView.swift        # Sent/delivered/read indicators
│   ├── Factory/
│   │   └── ChatContentFactory.swift           # Protocol — all views delegated here
│   ├── Models/
│   │   ├── ChatModels.swift                   # ChatContent, AnyChatContent, MessageBody, MessageOwnership, ThreadInfo, ChatMessage, etc.
│   │   ├── ChatTheme.swift                    # 50+ colors, light/dark presets, contextMenuTheme
│   │   ├── ChatLayout.swift                   # 350+ layout parameters
│   │   └── ChatFeatures.swift                 # Feature flags
│   ├── Audio/
│   │   └── VoicePlayer.swift                  # Singleton audio player
│   └── Helpers/
│       ├── MessageSizeCalculator.swift        # Cell height calculation
│       ├── SizeCache.swift                    # Width-aware cell size cache
│       ├── ChatTextMeasurer.swift             # Text measurement utilities
│       └── DateHelper.swift                   # Date formatting
│
├── DefaultContent/                            # Built-in content types (opt-in)
│   ├── DefaultChatContentFactory.swift        # Default factory: images, voice, poll, files
│   ├── Models/
│   │   ├── DefaultContentTypes.swift          # ImagesContent, VoicePayload, PollPayload, FilesContent
│   │   └── ChatParsing.swift                  # NSDictionary → ChatMessage (RN bridge)
│   └── Views/
│       ├── MediaGridView.swift                # Image/video grid (1-4 items)
│       ├── VoiceContentView.swift             # Waveform + play/pause
│       ├── PollContentView.swift              # Poll with animated bars
│       ├── FileContentView.swift              # File attachment rows
│       └── ImageCache.swift                   # URL → UIImage cache
├── InputBar/
│   ├── InputBarView.swift                     # Main input bar + UITextViewDelegate
│   ├── InputBarView+Recording.swift           # Voice recording gesture state machine
│   ├── InputBarModels.swift                   # InputBarDelegate, InputBarMode
│   ├── InputBarTheme.swift                    # Input bar colors
│   ├── Audio/
│   │   └── VoiceRecorder.swift                # AVAudioRecorder wrapper
│   └── Views/
│       ├── InputBarReplyPanel.swift           # Collapsible reply/edit preview
│       ├── InputBarRecordingRow.swift         # Recording UI (timer, cancel, stop)
│       └── InputBarLockView.swift             # Lock icon for hands-free recording
├── ContextMenu/
│   ├── Controller/
│   │   └── ContextMenuViewController.swift    # Menu presentation + dismiss
│   ├── Models/
│   │   └── ContextMenuModels.swift            # Action, Emoji, Configuration structs
│   ├── Theme/
│   │   └── ContextMenuTheme.swift             # Menu colors, light/dark presets
│   ├── Layout/
│   │   ├── ContextMenuLayout.swift            # Menu positioning
│   │   └── ContextMenuAnimator.swift          # Spring animations
│   └── Views/
│       ├── ContextMenuEmojiPanel.swift        # Emoji quick-reaction bar
│       └── ContextMenuActionsView.swift       # Action menu list
```

## Public API Reference

### ChatViewController

```swift
public final class ChatViewController: UIViewController {
    // Configuration (observable — triggers UI update on change)
    public var theme: ChatTheme
    public var layout: ChatLayout
    public var features: ChatFeatures
    public var contentFactory: ChatContentFactory
    public func batchUpdate(_ block: () -> Void)  // atomic config changes

    // Delegate
    public weak var delegate: ChatViewControllerDelegate?

    // Pagination state
    public var hasMore: Bool           // older messages available
    public var hasNewer: Bool          // newer messages available
    public var isLoading: Bool         // general loading (shows spinner in empty state)
    public var isLoadingTop: Bool      // top spinner overlay
    public var isLoadingBottom: Bool   // bottom loading indicator

    // Unread management
    public var unreadCount: Int
    public func setUnreadCount(_ count: Int)  // enables external unread management
    public func clearUnread()

    // Collection view access
    public private(set) var collectionView: UICollectionView!
    public var inputBar: InputBarView!
    public var collectionExtraInsetTop: CGFloat
    public var collectionExtraInsetBottom: CGFloat

    // Message operations
    public func updateMessages(_ newMessages: [ChatMessage])
    public func message(forID id: String) -> ChatMessage?

    // Scroll
    public func scrollToBottom(animated: Bool)
    public func scrollToMessage(id: String, position: String, animated: Bool, highlight: Bool)
    public var pendingScrollMessageId: String?  // scroll to this message on initial load

    // Input modes
    public func beginReply(info: ReplyInfo)
    public func beginEdit(messageId: String, text: String)
    public func clearInputMode()
}
```

### Delegate Protocols

```swift
// Combined protocol
public typealias ChatViewControllerDelegate =
    ChatScrollDelegate & ChatVisibilityDelegate & ChatMessageDelegate & ChatInputDelegate

public protocol ChatScrollDelegate: AnyObject {
    func chatDidScroll(offset: CGPoint)
    func chatDidReachTop(distance: CGFloat)       // load older messages
    func chatDidReachBottom(distance: CGFloat)     // load newer messages
    func chatDidTapFAB()
}

public protocol ChatVisibilityDelegate: AnyObject {
    func chatVisibleMessagesDidChange(ids: [String])  // throttled snapshot of visible messages
    func chatUnreadMessagesDidAppear(ids: [String])   // debounced unread messages batch
}

public protocol ChatMessageDelegate: AnyObject {
    func chatDidTapMessage(id: String, attachmentIndex: Int?)
    func chatDidSelectAction(actionId: String, messageId: String)
    func chatDidSelectEmojiReaction(emoji: String, messageId: String)
    func chatDidTapReaction(messageId: String, emoji: String)
    func chatDidTapReplyMessage(id: String)
    func chatDidTapPollOption(messageId: String, pollId: String, optionId: String)
    func chatDidTapPollDetail(messageId: String, pollId: String)
    func chatDidTapThread(messageId: String, threadId: String)
    func chatDidTapLink(url: URL, messageId: String)
    func chatDidTapPhoneNumber(phoneNumber: String, messageId: String)
}

public protocol ChatInputDelegate: AnyObject {
    func chatDidSendMessage(text: String, replyToId: String?)
    func chatDidEditMessage(text: String, messageId: String)
    func chatDidCancelInputAction(type: String)    // "reply" or "edit"
    func chatDidTapAttachment()
    func chatDidCompleteVoiceRecording(fileURL: URL, duration: TimeInterval, waveform: [Float])
    func chatDidChangeInputText(_ text: String)
}
```

### Data Models

```swift
// Content type system — library is agnostic to concrete types
public protocol ChatContent: Equatable, Hashable, Sendable {
    static var contentTypeID: String { get }
}

public struct AnyChatContent: Equatable, Hashable, Sendable {
    public init<T: ChatContent>(_ content: T)
    public func content<T: ChatContent>(as type: T.Type) -> T?
}

public struct MessageBody: Equatable, Hashable {
    public let text: String?
    public let content: AnyChatContent?    // any ChatContent type
}

// Message ownership — replaces old isMine: Bool
public enum MessageOwnership: Equatable, Hashable {
    case mine       // → MessageAlignment.trailing
    case theirs     // → MessageAlignment.leading
    case system     // → MessageAlignment.center (centered bubble, neutral colors)
    case pinned     // → MessageAlignment.center (centered bubble, left-aligned content)
}

public enum MessageAlignment {
    case leading, trailing, center
}

// Thread info — optional thread metadata on ChatMessage
public struct ThreadInfo: Equatable, Hashable {
    public let threadId: String
    public let replyCount: Int
    public let lastReplierName: String?
}

public struct ChatMessage: Equatable, Hashable {
    public let id: String
    public let content: MessageBody        // text + optional content
    public let timestamp: Date
    public let senderName: String?
    public let senderAvatarUrl: String?    // avatar URL for sticky avatars
    public let ownership: MessageOwnership // .mine, .theirs, .system, .pinned
    public let groupDate: String           // "yyyy-MM-dd" for date separators
    public let status: MessageStatus       // .sending, .sent, .delivered, .read
    public let reply: ReplyInfo?
    public let forwardedFrom: String?
    public let reactions: [Reaction]       // Reaction.isSelected replaces old isMine
    public let isEdited: Bool
    public let actions: [MessageAction]    // context menu actions
    public let thread: ThreadInfo?         // thread indicator (default nil)
}

// Generic interaction — library routes without inspecting
public struct ChatContentInteraction: Sendable {
    public let type: String
    public let payload: [String: AnyHashable]
}
```

### ChatContentFactory

```swift
public protocol ChatContentFactory: AnyObject {
    // Content (custom types rendered here)
    func contentView(for media: AnyChatContent, ...) -> UIView
    func contentHeight(for media: AnyChatContent, ...) -> CGFloat
    func reconfigureContentView(_ view: UIView, for media: AnyChatContent, ...) -> Bool

    // Universal elements
    func textView(text: String, ownership: MessageOwnership, theme: ChatTheme, layout: ChatLayout, linkDetectionEnabled: Bool, onLinkTap: ((URL) -> Void)?) -> UIView
    func textHeight(text: String, ...) -> CGFloat
    func emojiView(text: String, emojiCount: Int, ...) -> UIView
    func reactionsView(reactions: [Reaction], ...) -> UIView
    func replyPreviewView(reply: ReplyInfo, ...) -> UIView
    func footerView(message: ChatMessage, ...) -> UIView?
    func senderNameView(name: String, ...) -> UIView
    func forwardedHeaderView(from: String, ...) -> UIView
    func dateSeparatorView(title: String, ...) -> UIView
    func dateSeparatorHeight(layout: ChatLayout) -> CGFloat
    func floatingDateView(title: String, ...) -> UIView

    // Thread indicator
    func threadIndicatorView(thread: ThreadInfo, ownership: MessageOwnership, theme: ChatTheme, layout: ChatLayout, onTap: (() -> Void)?) -> UIView

    // Avatars
    func avatarView(name: String, url: String?, size: CGFloat, theme: ChatTheme, layout: ChatLayout) -> UIView

    // UI components
    func emptyStateView(...) -> UIView
    func emptyStateLoadingView(...) -> UIView
    func loadingIndicatorView(...) -> UIView
    func fabView(...) -> UIView
    func fabBadgeView(...) -> UIView
}
// DefaultChatContentFactory — handles built-in types, subclass to customize
// See CUSTOMIZATION.md for full guide on custom content types
```

### Feature Flags (ChatFeatures)

```swift
public struct ChatFeatures {
    // Messages
    public var senderNameMode: SenderNameMode  // .never, .incomingOnly, .always
    public var showMessageStatus: Bool         // sent/delivered/read icons
    public var showTimestamp: Bool
    public var showEditedMark: Bool
    public var showReactions: Bool
    public var showReplyPreview: Bool
    public var showForwardedMark: Bool

    // List
    public var showFab: Bool                   // floating action button
    public var showFloatingDate: Bool          // date pill on scroll
    public var showDateSeparators: Bool
    public var showTopLoadingIndicator: Bool
    public var showBottomLoadingIndicator: Bool
    public var showEmptyState: Bool

    // Input
    public var showInputBar: Bool
    public var showAttachButton: Bool
    public var showVoiceRecording: Bool

    // Threads
    public var showThreadIndicator: Bool       // default true

    // Avatars
    public var showAvatars: Bool               // default false — sticky avatars for .theirs messages

    // Link Detection
    public var linkDetectionEnabled: Bool       // default true — URLs and phone numbers

    // Context Menu
    public var contextMenuEnabled: Bool
    public var emojiReactions: [String]        // e.g. ["👍", "❤️", "😂", "😮", "😢", "🔥"]

    // Scroll Thresholds
    public var topLoadThreshold: CGFloat       // default 200
    public var bottomLoadThreshold: CGFloat    // default 200
    public var scrollToBottomThreshold: CGFloat // default 150
    public var autoScrollOnNewMessage: Bool
}
```

## Integration Example

```swift
class MyChatVC: UIViewController, ChatViewControllerDelegate {

    let chatVC = ChatViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Configure
        chatVC.theme = .dark
        chatVC.features.senderNameMode = .incomingOnly
        chatVC.features.emojiReactions = ["👍", "❤️", "😂", "😮", "😢", "🔥"]
        chatVC.delegate = self

        // 2. Embed as child
        addChild(chatVC)
        view.addSubview(chatVC.view)
        chatVC.view.frame = view.bounds
        chatVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        chatVC.didMove(toParent: self)

        // 3. Load messages
        chatVC.hasMore = true
        chatVC.updateMessages(myMessages)
    }

    // MARK: - Pagination
    func chatDidReachTop(distance: CGFloat) {
        chatVC.isLoadingTop = true
        loadOlderMessages { [weak self] older in
            self?.chatVC.isLoadingTop = false
            self?.chatVC.updateMessages(older + self!.chatVC.messages)
        }
    }

    // MARK: - Send
    func chatDidSendMessage(text: String, replyToId: String?) {
        let msg = createMessage(text: text, replyToId: replyToId)
        chatVC.updateMessages(chatVC.messages + [msg])
    }

    // MARK: - Actions
    func chatDidSelectAction(actionId: String, messageId: String) {
        switch actionId {
        case "reply":
            if let msg = chatVC.message(forID: messageId) {
                chatVC.beginReply(info: ReplyInfo(
                    replyToId: messageId,
                    senderName: msg.senderName,
                    text: msg.content.text,
                    hasImage: false
                ))
            }
        case "edit":
            if let msg = chatVC.message(forID: messageId) {
                chatVC.beginEdit(messageId: messageId, text: msg.content.text ?? "")
            }
        case "delete":
            var msgs = chatVC.messages
            msgs.removeAll { $0.id == messageId }
            chatVC.updateMessages(msgs)
        default: break
        }
    }

    // MARK: - Reactions
    func chatDidSelectEmojiReaction(emoji: String, messageId: String) {
        // Toggle reaction on server, then update messages
    }

    // MARK: - Other required delegate methods
    func chatDidScroll(offset: CGPoint) {}
    func chatDidReachBottom(distance: CGFloat) {}
    func chatDidTapFAB() { chatVC.scrollToBottom(animated: true) }
    func chatVisibleMessagesDidChange(ids: [String]) { /* scroll position tracking */ }
    func chatUnreadMessagesDidAppear(ids: [String]) { /* mark as read on backend */ }
    func chatDidTapMessage(id: String, attachmentIndex: Int?) {}
    func chatDidTapReaction(messageId: String, emoji: String) {}
    func chatDidTapReplyMessage(id: String) {
        chatVC.scrollToMessage(id: id, position: "center", animated: true, highlight: true)
    }
    func chatDidTapPollOption(messageId: String, pollId: String, optionId: String) {}
    func chatDidTapPollDetail(messageId: String, pollId: String) {}
    func chatDidTapThread(messageId: String, threadId: String) {
        // Open thread view
    }
    func chatDidTapLink(url: URL, messageId: String) {
        UIApplication.shared.open(url)
    }
    func chatDidTapPhoneNumber(phoneNumber: String, messageId: String) {}
    func chatDidEditMessage(text: String, messageId: String) {}
    func chatDidCancelInputAction(type: String) {}
    func chatDidTapAttachment() {}
    func chatDidCompleteVoiceRecording(fileURL: URL, duration: TimeInterval, waveform: [Float]) {}
    func chatDidChangeInputText(_ text: String) {}
}
```

## Conventions

- All UI built programmatically with AutoLayout constraints
- Views use closure callbacks for event bubbling; controllers use delegate protocols
- Pass `layout`/`theme`/`features` via parameters, not global singletons
- New content types go in `ChatView/Views/Content/`
- Follow existing extension pattern when adding ChatViewController functionality
- Custom content views — subclass `DefaultChatContentFactory` and override specific methods

## Build

```bash
# Demo app (Example/)
cd Example
pod install
xcodebuild -workspace rn-chat-view.xcworkspace \
  -scheme rn-chat-view \
  -destination 'id=00008110-000C0CA03A21801E' \
  -allowProvisioningUpdates \
  ENABLE_USER_SCRIPT_SANDBOXING=NO \
  build

# Install on device
xcrun devicectl device install app --device 00008110-000C0CA03A21801E \
  ~/Library/Developer/Xcode/DerivedData/rn-chat-view-*/Build/Products/Debug-iphoneos/rn-chat-view.app

# Launch
xcrun devicectl device process launch --device 00008110-000C0CA03A21801E ru.force-dev.rn-chat-view
```

## Installation

### CocoaPods
```ruby
pod 'IOSChatView', :path => '../path-to-lib'
pod 'DifferenceKit', :modular_headers => true
```

### Swift Package Manager
```swift
.package(url: "https://github.com/epifanovmd/rn-chat-view.git", from: "1.0.0")
```

## Known Issues

- `ENABLE_USER_SCRIPT_SANDBOXING` must be `NO` — CocoaPods rsync scripts are incompatible with Xcode sandbox
