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

Delegate-based composition. `ChatViewController` is the main orchestrator, split into 5 extensions:

- `+Data` — row building, layout data computation, size cache, message index
- `+Scroll` — UICollectionViewDelegate with throttled events, pagination, visibility tracking
- `+Input` — InputBarDelegate conformance, forwards to ChatViewControllerDelegate
- `+ContextMenu` — long-press context menu presentation + keyboard freeze/restore
- `+MessageActions` — routes cell interaction callbacks to delegate

Extracted managers:
- `MessageUpdateHandler` — detects update type (initial/prepend/append/content) and applies optimal strategy
- `FloatingDateManager` — floating date pill during scrolling
- `FABManager` — scroll-to-bottom button + unread badge
- `EmptyStateManager` — empty state view with spinner

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
| Initial | First batch (was empty) | `reloadData` + deferred scroll to bottom |
| Prepend | Older messages loaded | `reloadData` + manual contentOffset compensation |
| Append | New messages at bottom | `reloadData` + auto-scroll if near bottom |
| Content | Edit/delete/reactions/polls | DifferenceKit `StagedChangeset` → animated `performBatchUpdates` |

### Delegate Hierarchy

```
ChatViewControllerDelegate (typealias combining 4 focused protocols):
  ├── ChatScrollDelegate       — scroll, pagination, FAB tap
  ├── ChatVisibilityDelegate   — message visibility tracking
  ├── ChatMessageDelegate      — tap, long press, reactions, polls, replies
  └── ChatInputDelegate        — send, edit, attachment, voice recording

InputBarDelegate               — input bar events → ChatViewController → ChatViewControllerDelegate
ContextMenuDelegate            — context menu events (emoji, actions, dismiss)
```

### Configuration

```
ChatViewController properties:
  .theme: ChatTheme        — 50+ color properties, light/dark presets
  .layout: ChatLayout      — 350+ sizing/spacing/font parameters
  .features: ChatFeatures  — behavioral flags (show/hide UI elements)
  .contentFactory: ChatContentFactory — custom view creation (protocol)

batchUpdate { } — apply multiple config changes atomically (single reload)
```

## Project Structure

```
Sources/IOSChatView/
├── ChatView/
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
│   │   ├── MessageUpdateHandler.swift         # Update strategy dispatcher
│   │   ├── FloatingDateManager.swift          # Floating date pill
│   │   ├── FABManager.swift                   # Scroll-to-bottom FAB + badge
│   │   └── EmptyStateManager.swift            # Empty state + spinner
│   ├── Views/
│   │   ├── ChatCollectionViewLayout.swift     # Custom layout (pre-computed, binary search)
│   │   ├── MessageCell.swift                  # Message cell with gesture handlers
│   │   ├── MessageBubbleView.swift            # Bubble assembly (text, media, footer, etc.)
│   │   ├── DateSeparatorCell.swift            # Date separator cell
│   │   ├── LoadingCell.swift                  # Loading indicator cell
│   │   ├── PaddedLabel.swift                  # Utility label
│   │   └── Content/
│   │       ├── TextContentView.swift          # Text with link detection
│   │       ├── MediaGridView.swift            # Image/video grid (1-4 items)
│   │       ├── VoiceContentView.swift         # Waveform + play/pause
│   │       ├── PollContentView.swift          # Poll with animated bars
│   │       ├── FileContentView.swift          # File attachment rows
│   │       ├── ReactionsView.swift            # Emoji reaction chips
│   │       ├── ReplyPreviewView.swift         # Quoted message preview
│   │       └── MessageStatusView.swift        # Sent/delivered/read indicators
│   ├── Factory/
│   │   ├── ChatContentFactory.swift           # Protocol for custom content views
│   │   └── DefaultChatContentFactory.swift    # Default implementation
│   ├── Models/
│   │   ├── ChatModels.swift                   # ChatMessage, MessageMedia, Reaction, etc.
│   │   ├── ChatTheme.swift                    # 50+ colors, light/dark presets
│   │   ├── ChatLayout.swift                   # 350+ layout parameters
│   │   ├── ChatFeatures.swift                 # Feature flags
│   │   └── ChatParsing.swift                  # NSDictionary → ChatMessage (RN bridge)
│   ├── Audio/
│   │   └── VoicePlayer.swift                  # Singleton audio player
│   └── Helpers/
│       ├── MessageSizeCalculator.swift        # Cell height calculation
│       ├── ChatTextMeasurer.swift             # Text measurement utilities
│       ├── ImageCache.swift                   # URL → UIImage cache
│       └── DateHelper.swift                   # Date formatting
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
    func chatMessagesDidAppear(ids: [String])      // mark as read
}

public protocol ChatMessageDelegate: AnyObject {
    func chatDidTapMessage(id: String, attachmentIndex: Int?)
    func chatDidSelectAction(actionId: String, messageId: String)
    func chatDidSelectEmojiReaction(emoji: String, messageId: String)
    func chatDidTapReaction(messageId: String, emoji: String)
    func chatDidTapReplyMessage(id: String)
    func chatDidTapPollOption(messageId: String, pollId: String, optionId: String)
    func chatDidTapPollDetail(messageId: String, pollId: String)
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
public struct ChatMessage: Equatable, Hashable {
    public let id: String
    public let content: MessageContent     // text + media
    public let timestamp: Date
    public let senderName: String?
    public let isMine: Bool
    public let groupDate: String           // "yyyy-MM-dd" for date separators
    public let status: MessageStatus       // .sending, .sent, .delivered, .read
    public let reply: ReplyInfo?
    public let forwardedFrom: String?
    public let reactions: [Reaction]
    public let isEdited: Bool
    public let actions: [MessageAction]    // context menu actions
}

public struct MessageContent: Equatable, Hashable {
    public let text: String?
    public let media: MessageMedia?
}

public enum MessageMedia: Equatable, Hashable {
    case images([MediaItem])               // 1-4 images/videos in grid
    case voice(VoicePayload)               // waveform + duration
    case poll(PollPayload)                 // question + options + votes
    case files([FilePayload])              // file attachments
    case custom(type: String, payload: AnyHashable)
}

public enum MediaItem: Equatable, Hashable {
    case image(ImageItem)
    case video(VideoItem)
}

public struct Reaction: Equatable, Hashable {
    public let emoji: String
    public let count: Int
    public let isMine: Bool
}

public struct ReplyInfo: Equatable, Hashable {
    public let replyToId: String
    public let senderName: String?
    public let text: String?
    public let hasImage: Bool
}

public struct MessageAction: Equatable, Hashable {
    public let id: String
    public let title: String
    public let systemImage: String?
    public let isDestructive: Bool
}
```

### ChatContentFactory (Customization)

```swift
public protocol ChatContentFactory {
    func contentView(for media: MessageMedia, ...) -> UIView
    func contentHeight(for media: MessageMedia, ...) -> CGFloat
    func textView(text: String, ...) -> UIView
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
}
// DefaultChatContentFactory — subclass to override specific views
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
    func chatMessagesDidAppear(ids: [String]) { /* mark as read */ }
    func chatDidTapMessage(id: String, attachmentIndex: Int?) {}
    func chatDidTapReaction(messageId: String, emoji: String) {}
    func chatDidTapReplyMessage(id: String) {
        chatVC.scrollToMessage(id: id, position: "center", animated: true, highlight: true)
    }
    func chatDidTapPollOption(messageId: String, pollId: String, optionId: String) {}
    func chatDidTapPollDetail(messageId: String, pollId: String) {}
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
