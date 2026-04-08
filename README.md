# IOSChatView

Production-ready iOS chat UI component library. Built with UIKit + DifferenceKit for high-performance message rendering at 100K+ messages.

## Features

### Message Types
- [x] Text messages (single/multi-line, links)
- [x] Emoji-only messages (1-3 emojis, large font, no bubble)
- [x] Image messages (single image with aspect ratio)
- [x] Video messages (thumbnail + play icon + duration badge)
- [x] Media grid (2-4 items, +N overlay)
- [x] Mixed content (media + text caption)
- [x] Voice messages (waveform visualization, playback, seek)
- [x] Polls (single/multiple choice, anonymous, closeable)
- [x] File attachments (icon by extension, name, size)
- [x] Forwarded messages (accent bar + sender label)
- [x] Reply previews (quoted message with sender + text)
- [x] Custom content types (via `MessageMedia.custom`)
- [x] System messages (centered, neutral styling)
- [x] Pinned messages (centered bubble, left-aligned content)
- [x] Thread discussions (pinned root + replies pattern)

### Message Features
- [x] Reactions (emoji chips with count, mine highlight)
- [x] Message status (sending, sent, delivered, read)
- [x] Edited mark
- [x] Timestamp
- [x] Sender name (never / incoming only / always)
- [x] Message highlight on scroll-to
- [x] Thread indicator (reply count, last replier, tap to open)
- [x] Sticky avatars (grouped by sender, supplementary views)
- [x] Link detection (URLs and phone numbers, tap callbacks)
- [x] Message ownership (mine/theirs/system/pinned alignment)

### Input Bar
- [x] Auto-growing text input (1-5 lines)
- [x] Send button (appears when text present)
- [x] Attachment button (configurable)
- [x] Voice recording (long press, drag to cancel/lock)
- [x] Reply mode (with preview panel)
- [x] Edit mode (with preview panel)
- [x] Haptic feedback

### Chat List
- [x] DifferenceKit animated diffs (O(n) Heckel algorithm)
- [x] Custom `UICollectionViewLayout` with pre-computed heights
- [x] Size cache for O(1) cell height lookups
- [x] Scroll-to-bottom FAB with unread badge
- [x] Floating date pill on scroll
- [x] Date separators between message groups
- [x] Prepend scroll compensation (load older messages without jump)
- [x] Append scroll preservation (new messages while scrolled up)
- [x] Empty state (spinner + "no messages" text)
- [x] Top/bottom loading indicators
- [x] Pagination (threshold-based, top + bottom)
- [x] Visibility tracking (message appear events)
- [x] Animated delete/edit/reorder

### Context Menu
- [x] Long press popup with snapshot
- [x] Quick emoji reactions panel
- [x] Action list (reply, edit, copy, delete, etc.)
- [x] Keyboard freeze/restore on dismiss
- [x] Spring animations

### Customization
- [x] `ChatTheme` — 50+ color properties (light/dark presets), system/pinned message colors
- [x] `ChatLayout` — 350+ layout constants (fonts, sizes, spacing)
- [x] `ChatFeatures` — 30+ feature flags
- [x] `ChatContentFactory` — full view customization via protocol
- [x] Avatar views via factory protocol
- [x] `InputBarTheme` — independent input bar theming
- [x] `ContextMenuTheme` — context menu theming (light/dark presets)
- [x] Custom content types via `ChatContent` protocol (type-safe, extensible)
- [x] `batchUpdate {}` — atomic config changes (single reload)
- [x] Content-agnostic core — library knows nothing about message types
- [x] See [CUSTOMIZATION.md](CUSTOMIZATION.md) for full custom types guide

---

## Installation

### CocoaPods

```ruby
pod 'IOSChatView', :path => '../rn-chat-view'
pod 'DifferenceKit', :modular_headers => true

# or from git:
# pod 'IOSChatView', :git => 'https://github.com/epifanovmd/rn-chat-view.git'
```

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/epifanovmd/rn-chat-view.git", from: "1.0.0")
]
```

### Requirements

- iOS 15.0+
- Swift 5.9+
- DifferenceKit 1.3+

---

## Quick Start

```swift
import IOSChatView

class MyChatVC: UIViewController, ChatViewControllerDelegate {
    private let chatVC = ChatViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Configure
        chatVC.delegate = self
        chatVC.theme = .dark
        chatVC.features.senderNameMode = .incomingOnly
        chatVC.features.emojiReactions = ["👍", "❤️", "😂", "😮", "😢", "🔥"]

        // 2. Embed as child view controller
        addChild(chatVC)
        view.addSubview(chatVC.view)
        chatVC.view.frame = view.bounds
        chatVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        chatVC.didMove(toParent: self)

        // 3. Load messages
        chatVC.hasMore = true  // enable top pagination
        chatVC.updateMessages(myMessages)
    }

    // MARK: - Send Message

    func chatDidSendMessage(text: String, replyToId: String?) {
        let msg = createMessage(text: text, replyToId: replyToId)
        chatVC.updateMessages(chatVC.messages + [msg])
        chatVC.clearInputMode()
    }

    // MARK: - Pagination

    func chatDidReachTop(distance: CGFloat) {
        chatVC.isLoadingTop = true
        api.loadOlderMessages { [weak self] older in
            guard let self else { return }
            chatVC.isLoadingTop = false
            chatVC.hasMore = older.count >= pageSize
            chatVC.updateMessages(older + chatVC.messages)
        }
    }

    // MARK: - Message Actions

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
            chatVC.updateMessages(msgs)  // animated delete
        default: break
        }
    }

    func chatDidEditMessage(text: String, messageId: String) {
        // Update message on backend, then refresh messages
        chatVC.clearInputMode()
    }

    // MARK: - Reactions

    func chatDidSelectEmojiReaction(emoji: String, messageId: String) {
        // Toggle reaction on backend, then update messages
    }

    func chatDidTapReaction(messageId: String, emoji: String) {
        // Toggle existing reaction
    }

    // MARK: - Navigation

    func chatDidTapReplyMessage(id: String) {
        chatVC.scrollToMessage(id: id, position: "center", animated: true, highlight: true)
    }

    func chatDidTapFAB() {
        chatVC.clearUnread()
        chatVC.scrollToBottom(animated: true)
    }

    // MARK: - Other Delegates

    func chatDidScroll(offset: CGPoint) {}
    func chatDidReachBottom(distance: CGFloat) {}
    func chatMessagesDidAppear(ids: [String]) { /* mark as read on backend */ }
    func chatDidTapMessage(id: String, attachmentIndex: Int?) { /* open media viewer */ }
    func chatDidCancelInputAction(type: String) {}
    func chatDidTapAttachment() { /* show image picker */ }
    func chatDidCompleteVoiceRecording(fileURL: URL, duration: TimeInterval, waveform: [Float]) {
        // Upload voice file, create voice message
    }
    func chatDidChangeInputText(_ text: String) { /* typing indicator */ }
    func chatDidContentInteraction(messageId: String, interaction: ChatContentInteraction) {
        // Handle content-specific interactions (poll votes, custom taps, etc.)
    }
}
```

---

## Messages

### Creating Messages

```swift
// Text message
let textMsg = ChatMessage(
    id: "1",
    content: MessageBody(text: "Hello!"),
    timestamp: Date(),
    senderName: "Alice",
    ownership: .theirs,
    groupDate: "2026-04-06",
    status: .read,
    reply: nil,
    forwardedFrom: nil,
    reactions: [],
    isEdited: false,
    actions: []
)

// Image message with caption (using built-in ImagesContent)
let imageMsg = ChatMessage(
    id: "2",
    content: MessageBody(
        text: "Check this out!",
        content: AnyChatContent(ImagesContent([
            .image(ImageItem(url: "https://example.com/photo.jpg", width: 400, height: 300, thumbnailUrl: nil))
        ]))
    ),
    timestamp: Date(),
    senderName: nil,
    ownership: .mine,
    groupDate: "2026-04-06",
    status: .sent,
    reply: nil,
    forwardedFrom: nil,
    reactions: [Reaction(emoji: "👍", count: 2, isMine: true)],
    isEdited: false,
    actions: []
)

// Voice message (using built-in VoicePayload)
let voiceMsg = ChatMessage(
    id: "3",
    content: MessageBody(
        content: AnyChatContent(VoicePayload(url: "https://...", duration: 12.5, waveform: [0.2, 0.5, 0.8, 0.3]))
    ),
    // ...
)

// Poll (using built-in PollPayload)
let pollMsg = ChatMessage(
    id: "4",
    content: MessageBody(
        content: AnyChatContent(PollPayload(
            id: "poll1", question: "Favorite color?",
            options: [
                PollOption(id: "r", text: "Red", votes: 5, percentage: 0.5),
                PollOption(id: "b", text: "Blue", votes: 5, percentage: 0.5),
            ],
            totalVotes: 10, selectedOptionIds: ["r"],
            isMultipleChoice: false, isClosed: false, isAnonymous: false
        ))
    ),
    // ...
)

// Custom content type — define your own struct conforming to ChatContent
struct LocationContent: ChatContent {
    static let contentTypeID = "location"
    let latitude: Double
    let longitude: Double
    let address: String
}

let locationMsg = ChatMessage(
    id: "5",
    content: MessageBody(
        text: "My location",
        content: AnyChatContent(LocationContent(latitude: 55.75, longitude: 37.62, address: "Moscow"))
    ),
    // ...
)
// System message (centered, neutral styling)
let systemMsg = ChatMessage(
    id: "6",
    content: MessageBody(text: "Alice joined the group"),
    timestamp: Date(),
    senderName: nil,
    ownership: .system,
    groupDate: "2026-04-06",
    status: .read,
    reply: nil,
    forwardedFrom: nil,
    reactions: [],
    isEdited: false,
    actions: []
)

// Pinned message (centered bubble, left-aligned content)
let pinnedMsg = ChatMessage(
    id: "7",
    content: MessageBody(text: "Meeting at 3 PM tomorrow"),
    timestamp: Date(),
    senderName: "Admin",
    ownership: .pinned,
    groupDate: "2026-04-06",
    status: .read,
    reply: nil,
    forwardedFrom: nil,
    reactions: [],
    isEdited: false,
    actions: []
)

// See CUSTOMIZATION.md for the full guide on custom content types
```

### Message Actions

Define context menu actions per message:

```swift
let actions = [
    MessageAction(id: "reply", title: "Reply", systemImage: "arrowshape.turn.up.left", isDestructive: false),
    MessageAction(id: "edit", title: "Edit", systemImage: "pencil", isDestructive: false),
    MessageAction(id: "copy", title: "Copy", systemImage: "doc.on.doc", isDestructive: false),
    MessageAction(id: "forward", title: "Forward", systemImage: "arrowshape.turn.up.right", isDestructive: false),
    MessageAction(id: "delete", title: "Delete", systemImage: "trash", isDestructive: true),
]
```

### Updating Messages

```swift
// Full update — library auto-detects the type:
// - Initial load (was empty)
// - Prepend (older messages at top, with scroll compensation)
// - Append (new messages at bottom, auto-scroll if near bottom)
// - Content change (edit, delete, reactions — animated diff)
chatVC.updateMessages(newMessages)
```

### Scroll & Navigation

```swift
chatVC.scrollToBottom(animated: true)
chatVC.scrollToMessage(id: "msg-42", position: "center", animated: true, highlight: true)
// position: "top", "center", "bottom"

// Scroll to message on initial load
chatVC.pendingScrollMessageId = "msg-42"
chatVC.updateMessages(messages)

// Unread management
chatVC.clearUnread()
chatVC.setUnreadCount(5)  // enables external unread management
```

---

## Theme

```swift
// Use presets
chatVC.theme = .light
chatVC.theme = .dark

// Customize individual colors
var theme = ChatTheme.dark
theme.outgoingBubble = .systemBlue
theme.incomingSenderName = .systemOrange
theme.fabBackground = .systemGray6
chatVC.theme = theme
```

### Color Groups

| Group | Properties |
|---|---|
| Background | `backgroundColor`, `wallpaperColor` |
| Outgoing bubble | `outgoingBubble`, `outgoingText`, `outgoingTime`, `outgoingStatus`, `outgoingStatusRead`, `outgoingEdited`, `outgoingLink` |
| Incoming bubble | `incomingBubble`, `incomingText`, `incomingTime`, `incomingEdited`, `incomingSenderName`, `incomingLink` |
| Reply preview | `outgoing/incomingReplyBackground`, `outgoing/incomingReplyAccent`, `outgoing/incomingReplySender`, `outgoing/incomingReplyText` |
| Forwarded | `outgoing/incomingForwardedLabel`, `outgoing/incomingForwardedAccent` |
| Files | `outgoingFileBackground`, `incomingFileBackground`, `fileIconColor` |
| Reactions | `reactionBackground`, `reactionMineBackground`, `reactionText`, `reactionMineBorder` |
| Date separator | `dateSeparatorBackground`, `dateSeparatorText` |
| FAB | `fabBackground`, `fabBorder`, `fabBlurStyle`, `fabArrowColor`, `fabBadgeBackground`, `fabBadgeTextColor`, `fabShadowColor` |
| Voice | `voiceWaveformActive`, `voiceWaveformInactive` |
| Polls | `pollBarFilled`, `pollBarEmpty`, `pollSelectedBorder`, `pollSubtitleColor` |
| Media | `mediaPlaceholderBackground`, `mediaPlayIconColor`, `mediaPlayShadowColor`, `mediaDurationBackground`, `mediaDurationTextColor`, `mediaOverlayBackground`, `mediaOverlayTextColor` |
| Highlight | `messageHighlightColor` |
| Empty state | `emptyStateText` |

---

## Layout

350+ layout parameters for pixel-perfect customization:

```swift
var layout = ChatLayout()

// Bubble
layout.bubbleCornerRadius = 20
layout.bubbleMaxWidthRatio = 0.8
layout.bubbleHPad = 12
layout.bubbleVPad = 8

// Fonts
layout.messageFont = .systemFont(ofSize: 16)
layout.senderNameFont = .boldSystemFont(ofSize: 13)
layout.timeFont = .systemFont(ofSize: 11)

// Spacing
layout.cellVSpacing = 4
layout.cellHMargin = 8

// Media
layout.imageMaxHeight = 280
layout.imageCornerRadius = 12
layout.mediaGridSpacing = 2

// Voice
layout.voiceWaveformHeight = 32
layout.voiceBarWidth = 3
layout.voiceBarSpacing = 2

// Polls
layout.pollBarHeight = 8
layout.pollBarCornerRadius = 4

// Input Bar
layout.inputBarMinHeight = 52
layout.textViewCornerRadius = 20
layout.textViewFont = .systemFont(ofSize: 16)

chatVC.layout = layout
```

### Batch Updates

Apply multiple configuration changes atomically (single reload):

```swift
chatVC.batchUpdate {
    chatVC.theme = .dark
    chatVC.layout = customLayout
    chatVC.features.showFab = false
    chatVC.features.showDateSeparators = true
}
```

---

## Feature Flags

```swift
var features = ChatFeatures()

// Messages
features.senderNameMode = .incomingOnly  // .never | .incomingOnly | .always
features.showMessageStatus = true        // sent/delivered/read icons
features.showTimestamp = true
features.showEditedMark = true
features.showReactions = true
features.showReplyPreview = true
features.showForwardedMark = true

// List
features.showFab = true                  // floating action button
features.showFloatingDate = true         // date pill on scroll
features.showDateSeparators = true       // date headers between groups
features.showTopLoadingIndicator = true
features.showBottomLoadingIndicator = true
features.showEmptyState = true           // "no messages" view

// Input
features.showInputBar = true
features.showAttachButton = true
features.showVoiceRecording = true

// Context menu
features.contextMenuEnabled = true
features.emojiReactions = ["👍", "❤️", "😂", "😮", "😢", "🔥", "🎉", "👎"]

// Scroll thresholds (points from edge to trigger pagination)
features.topLoadThreshold = 200
features.bottomLoadThreshold = 200
features.scrollToBottomThreshold = 150
features.autoScrollOnNewMessage = true

chatVC.features = features
```

---

## Content Factory (Advanced Customization)

The library is content-agnostic — all rendering is delegated to `ChatContentFactory`. Subclass `DefaultChatContentFactory` to add custom types or customize built-in views:

```swift
class MyFactory: DefaultChatContentFactory {

    // Handle custom content types
    override func contentView(for media: AnyChatContent, message: ChatMessage,
                              width: CGFloat, theme: ChatTheme, layout: ChatLayout,
                              onInteraction: @escaping (ChatContentInteraction) -> Void) -> UIView {
        if let location = media.content(as: LocationContent.self) {
            let view = LocationMapView()
            view.configure(location: location)
            view.onTap = {
                onInteraction(ChatContentInteraction(type: "locationTap", payload: [
                    "lat": location.latitude as AnyHashable,
                    "lon": location.longitude as AnyHashable,
                ]))
            }
            return view
        }
        return super.contentView(for: media, message: message, width: width,
                                 theme: theme, layout: layout, onInteraction: onInteraction)
    }

    // Height for custom content
    override func contentHeight(for media: AnyChatContent, width: CGFloat, layout: ChatLayout) -> CGFloat {
        if media.content(as: LocationContent.self) != nil { return 200 }
        return super.contentHeight(for: media, width: width, layout: layout)
    }
}

chatVC.contentFactory = MyFactory()
```

For the full guide on custom content types, factory patterns, and interaction handling, see **[CUSTOMIZATION.md](CUSTOMIZATION.md)**.

### All Factory Methods

| Method | Purpose |
|---|---|
| `contentView(for:message:width:theme:layout:onInteraction:)` | Content rendering (any type) |
| `contentHeight(for:width:layout:)` | Height calculation for content |
| `reconfigureContentView(_:for:message:...)` | In-place content update (animations) |
| `textView(text:ownership:theme:layout:)` | Text portion of message |
| `textHeight(text:font:width:)` | Text height calculation |
| `emojiView(text:emojiCount:layout:)` | Emoji-only messages (1-3 emojis) |
| `reactionsView(reactions:theme:maxWidth:layout:onTap:)` | Reaction chip bar |
| `replyPreviewView(reply:resolved:ownership:theme:layout:onTap:)` | Quoted message block |
| `footerView(message:theme:layout:features:)` | Time + edited mark + status icon |
| `senderNameView(name:theme:layout:)` | Sender name label |
| `forwardedHeaderView(from:ownership:theme:layout:)` | "Forwarded from X" header |
| `dateSeparatorView(title:theme:layout:)` | Date separator pill |
| `dateSeparatorHeight(layout:)` | Date separator height |
| `floatingDateView(title:theme:layout:)` | Floating date during scroll |
| `emptyStateView(theme:layout:)` | Empty state placeholder |
| `emptyStateLoadingView(theme:layout:)` | Loading spinner in empty state |
| `loadingIndicatorView(theme:layout:)` | Pagination loading indicator |
| `fabView(theme:layout:)` | Scroll-to-bottom FAB button |
| `fabBadgeView(theme:layout:)` | Unread badge on FAB |

---

## Delegate Reference

```swift
// Composite protocol (implement all 4):
typealias ChatViewControllerDelegate =
    ChatScrollDelegate & ChatVisibilityDelegate & ChatMessageDelegate & ChatInputDelegate
```

### ChatScrollDelegate

```swift
func chatDidScroll(offset: CGPoint)          // scroll position changed
func chatDidReachTop(distance: CGFloat)      // near top — load older messages
func chatDidReachBottom(distance: CGFloat)   // near bottom — load newer messages
func chatDidTapFAB()                         // scroll-to-bottom button tapped
```

### ChatVisibilityDelegate

```swift
func chatMessagesDidAppear(ids: [String])    // messages became visible (for read receipts)
```

### ChatMessageDelegate

```swift
func chatDidTapMessage(id: String, attachmentIndex: Int?)               // message/media tap
func chatDidSelectAction(actionId: String, messageId: String)           // context menu action
func chatDidSelectEmojiReaction(emoji: String, messageId: String)       // emoji from context menu
func chatDidTapReaction(messageId: String, emoji: String)               // reaction chip tap
func chatDidTapReplyMessage(id: String)                                 // quoted message tap
func chatDidContentInteraction(messageId: String, interaction: ChatContentInteraction)  // all content interactions
```

### ChatInputDelegate

```swift
func chatDidSendMessage(text: String, replyToId: String?)               // send button
func chatDidEditMessage(text: String, messageId: String)                // edit confirmed
func chatDidCancelInputAction(type: String)                             // "reply" or "edit" cancelled
func chatDidTapAttachment()                                             // attachment button
func chatDidCompleteVoiceRecording(fileURL: URL, duration: TimeInterval, waveform: [Float])
func chatDidChangeInputText(_ text: String)                             // text changed (typing indicator)
```

All delegate methods have default empty implementations — implement only what you need.

---

## Input Bar

The input bar is embedded in `ChatViewController` but can also be used standalone:

```swift
let inputBar = InputBarView()
inputBar.delegate = self
inputBar.applyTheme(.dark)
inputBar.applyLayout(ChatLayout())

// Show/hide buttons
inputBar.showAttachButton = true
inputBar.voiceRecordingEnabled = true

// Reply/edit modes
inputBar.beginReply(info: InputBarReplyInfo(
    messageId: "1", senderName: "Alice", text: "Hello", hasImage: false
))
inputBar.beginEdit(messageId: "1", text: "Updated text")
inputBar.cancelMode()

// Keyboard
inputBar.activateKeyboard()
inputBar.dismissKeyboard()
inputBar.isKeyboardActive  // read-only
```

### InputBarMode

```swift
public enum InputBarMode: Equatable {
    case normal
    case reply(messageId: String, senderName: String?, text: String?, hasImage: Bool)
    case edit(messageId: String, text: String)
}
```

### Voice Recording

Voice recording uses a long-press gesture on the mic button:
- **Drag left** to cancel
- **Drag up** to lock (hands-free recording)
- **Release** to send

The recording produces a `.m4a` file with waveform data, delivered via `chatDidCompleteVoiceRecording`.

---

## Context Menu

Shown on long-press of a message bubble. Configured per-message via `MessageAction` array and globally via `features.emojiReactions`.

```swift
// Per-message actions
let msg = ChatMessage(
    // ...
    actions: [
        MessageAction(id: "reply", title: "Reply", systemImage: "arrowshape.turn.up.left", isDestructive: false),
        MessageAction(id: "delete", title: "Delete", systemImage: "trash", isDestructive: true),
    ]
)

// Global emoji palette
chatVC.features.emojiReactions = ["👍", "❤️", "😂", "😮", "😢", "🔥"]

// Disable context menu entirely
chatVC.features.contextMenuEnabled = false
```

### ContextMenuTheme

```swift
var menuTheme = ContextMenuTheme.dark
menuTheme.emojiPanelBackground = .systemGray6
menuTheme.menuCornerRadius = 16
menuTheme.openDuration = 0.3
```

---

## Unread Management

Two modes:

### Automatic (default)
The library tracks visible messages and decrements unread count automatically:

```swift
chatVC.unreadCount = 5  // shows badge on FAB
// As user scrolls, visible unread messages are marked and count decreases
```

### External
For apps that manage read state on the backend:

```swift
chatVC.setUnreadCount(10)  // switches to external mode
// Library no longer auto-decrements — you control the count
chatVC.clearUnread()       // reset to zero
```

---

## React Native Bridge

Parse messages from JavaScript dictionaries:

```swift
let msg = ChatMessage.from(dict: jsDict)
```

Supports all content types, reactions, replies, actions, and status.

---

## Architecture

The library core (`ChatView/`) is content-agnostic — it knows nothing about message types. All content rendering lives in `DefaultContent/`, which users can replace entirely.

```
Sources/IOSChatView/
├── ChatView/              # CORE — content-agnostic
│   ├── Controller/        # ChatViewController + 5 extensions
│   ├── DataSource/        # UICollectionViewDataSource + ChatRow (Differentiable)
│   ├── Components/        # MessageUpdateHandler, FAB, FloatingDate, EmptyState,
│   │                      # KeyboardFreezeManager, UnreadManager
│   ├── Factory/           # ChatContentFactory protocol (no implementation)
│   ├── Models/            # ChatContent, AnyChatContent, MessageBody, ChatMessage, Theme, Layout
│   ├── Views/             # MessageCell, MessageBubbleView, ChatCollectionViewLayout
│   │   └── Content/       # Text, Reactions, Reply, Status (universal elements)
│   ├── Audio/             # VoicePlayer (singleton)
│   └── Helpers/           # MessageSizeCalculator, SizeCache, ChatTextMeasurer, DateHelper
├── DefaultContent/        # Built-in content types (opt-in)
│   ├── DefaultChatContentFactory.swift
│   ├── Models/            # ImagesContent, VoicePayload, PollPayload, FilesContent, ChatParsing
│   └── Views/             # MediaGrid, Voice, Poll, File, ImageCache
├── InputBar/
│   ├── InputBarView       # Main view + recording extension
│   ├── Audio/             # VoiceRecorder
│   └── Views/             # ReplyPanel, RecordingRow, LockView
└── ContextMenu/
    ├── Controller/        # ContextMenuViewController
    ├── Models/            # Action, Emoji, Configuration
    ├── Theme/             # ContextMenuTheme (light/dark)
    ├── Layout/            # Positioning + spring animations
    └── Views/             # EmojiPanel, ActionsView
```

### Performance

- **Custom layout:** Pre-computed heights, binary search for visible rect, no delegate calls during scroll
- **Size cache:** Width-aware cache (id + width key), auto-invalidates on rotation
- **DifferenceKit:** O(n) Heckel diff, animated batch updates only for affected cells
- **Prepend:** O(delta) — only new rows computed, scroll offset compensated
- **Append:** Constant time — rows added at end, auto-scroll if near bottom

---

## License

MIT License. See [LICENSE](LICENSE) for details.
