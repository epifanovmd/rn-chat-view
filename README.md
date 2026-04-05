# IOSChatView

Production-ready iOS chat UI component library. Built with UIKit + IGListKit for high-performance message rendering.

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

### Message Features
- [x] Reactions (emoji chips with count, mine highlight)
- [x] Message status (sending, sent, delivered, read)
- [x] Edited mark
- [x] Timestamp
- [x] Sender name (never / incoming only / always)
- [x] Message highlight on scroll-to

### Input Bar
- [x] Auto-growing text input (1-5 lines)
- [x] Send button (appears when text present)
- [x] Attachment button (configurable)
- [x] Voice recording (long press, drag to cancel/lock)
- [x] Reply mode (with preview panel)
- [x] Edit mode (with preview panel)
- [x] Haptic feedback

### Chat List
- [x] IGListKit-based diffing (background thread)
- [x] Scroll-to-bottom FAB with unread badge
- [x] Floating date pill on scroll
- [x] Date separators between message groups
- [x] Prepend scroll compensation (load older messages)
- [x] Append scroll preservation (new messages while scrolled up)
- [x] Empty state (spinner + "no messages" text)
- [x] Top/bottom loading indicators
- [x] Pagination (threshold-based)
- [x] Visibility tracking (message appear events)

### Context Menu
- [x] Long press popup with snapshot
- [x] Quick emoji reactions panel
- [x] Action list (reply, edit, copy, delete, etc.)
- [x] Keyboard freeze/restore on dismiss
- [x] Spring animations

### Customization
- [x] `ChatTheme` — 50+ color properties (light/dark presets)
- [x] `ChatLayout` — 100+ layout constants (fonts, sizes, spacing)
- [x] `ChatFeatures` — 20+ feature flags
- [x] `ChatContentFactory` — full view customization
- [x] `InputBarTheme` — independent input bar theming
- [x] Custom content types via `MessageMedia.custom`

---

## Installation

### CocoaPods

```ruby
pod 'IOSChatView', :path => '../rn-chat-view'
# or from git:
# pod 'IOSChatView', :git => 'https://github.com/epifanovmd/rn-chat-view.git'
```

### Requirements

- iOS 16.0+
- Swift 5.9+
- IGListKit 5.x

---

## Quick Start

```swift
import IOSChatView

class MyChatVC: UIViewController, ChatViewControllerDelegate {
    private let chatVC = ChatViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        chatVC.delegate = self
        chatVC.theme = .dark
        chatVC.features.senderNameMode = .incomingOnly
        chatVC.features.emojiReactions = ["👍", "❤️", "😂", "😮", "😢"]
        
        addChild(chatVC)
        view.addSubview(chatVC.view)
        chatVC.view.frame = view.bounds
        chatVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        chatVC.didMove(toParent: self)
        
        chatVC.updateMessages(myMessages)
    }
    
    // MARK: - ChatViewControllerDelegate
    
    func chatDidSendMessage(text: String, replyToId: String?) {
        // Send message to your backend
    }
    
    func chatDidTapMessage(id: String, attachmentIndex: Int?) {
        // Handle message tap
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
    content: MessageContent(text: "Hello!", media: nil),
    timestamp: Date(),
    senderName: "Alice",
    isMine: false,
    groupDate: "2025-04-05",
    status: .read,
    reply: nil,
    forwardedFrom: nil,
    reactions: [],
    isEdited: false,
    actions: []
)

// Image message with caption
let imageMsg = ChatMessage(
    id: "2",
    content: MessageContent(
        text: "Check this out!",
        media: .images([
            .image(ImageItem(url: "https://...", width: 400, height: 300, thumbnailUrl: nil))
        ])
    ),
    // ... other fields
)

// Voice message
let voiceMsg = ChatMessage(
    id: "3",
    content: MessageContent(
        text: nil,
        media: .voice(VoicePayload(url: "https://...", duration: 12.5, waveform: [0.2, 0.5, 0.8, ...]))
    ),
    // ...
)

// Poll
let pollMsg = ChatMessage(
    id: "4",
    content: MessageContent(
        text: nil,
        media: .poll(PollPayload(
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

// Custom content type
let locationMsg = ChatMessage(
    id: "5",
    content: MessageContent(
        text: "My location",
        media: .custom(type: "location", payload: AnyHashable(myLocationData))
    ),
    // ...
)
```

### Updating Messages

```swift
chatVC.updateMessages(newMessages)  // Automatic diff + scroll compensation
```

### Scroll & Navigation

```swift
chatVC.scrollToBottom(animated: true)
chatVC.scrollToMessage(id: "msg-42", position: "center", animated: true, highlight: true)
chatVC.clearUnread()
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
chatVC.theme = theme
```

### Key Color Groups

| Group | Properties |
|---|---|
| Background | `backgroundColor`, `wallpaperColor` |
| Outgoing bubble | `outgoingBubble`, `outgoingText`, `outgoingTime`, `outgoingStatus`, `outgoingStatusRead`, `outgoingEdited`, `outgoingLink` |
| Incoming bubble | `incomingBubble`, `incomingText`, `incomingTime`, `incomingEdited`, `incomingSenderName`, `incomingLink` |
| Reply preview | `outgoing/incomingReplyBackground`, `outgoing/incomingReplyAccent`, `outgoing/incomingReplySender`, `outgoing/incomingReplyText` |
| Forwarded | `outgoing/incomingForwardedLabel`, `outgoing/incomingForwardedAccent` |
| Reactions | `reactionBackground`, `reactionMineBackground`, `reactionText`, `reactionMineBorder` |
| Date separator | `dateSeparatorBackground`, `dateSeparatorText` |
| FAB | `fabBackground`, `fabBorder`, `fabArrowColor`, `fabBadgeBackground`, `fabBadgeTextColor` |
| Voice content | `voiceWaveformActive`, `voiceWaveformInactive` |
| Polls | `pollBarFilled`, `pollBarEmpty`, `pollSelectedBorder`, `pollSubtitleColor` |
| Media | `mediaPlaceholderBackground`, `mediaPlayIconColor`, `mediaDurationBackground` |

---

## Layout

```swift
var layout = ChatLayout()
layout.bubbleCornerRadius = 20
layout.bubbleMaxWidthRatio = 0.8
layout.messageFont = .systemFont(ofSize: 16)
layout.cellVSpacing = 4
chatVC.layout = layout
```

### Batch Updates

```swift
chatVC.batchUpdate {
    chatVC.theme = .dark
    chatVC.layout = customLayout
    chatVC.features.showFab = false
}
```

---

## Feature Flags

```swift
var features = ChatFeatures()

// Messages
features.senderNameMode = .incomingOnly  // .never | .incomingOnly | .always
features.showMessageStatus = true
features.showTimestamp = true
features.showEditedMark = true
features.showReactions = true
features.showReplyPreview = true
features.showForwardedMark = true

// List
features.showFab = true
features.showFloatingDate = true
features.showDateSeparators = true
features.showEmptyState = true

// Input
features.showInputBar = true
features.showAttachButton = true
features.showVoiceRecording = true

// Context menu
features.contextMenuEnabled = true
features.emojiReactions = ["👍", "❤️", "😂", "😮", "😢"]

// Scroll
features.topLoadThreshold = 200
features.bottomLoadThreshold = 200
features.scrollToBottomThreshold = 150

chatVC.features = features
```

---

## Content Factory (Advanced Customization)

Override any part of message rendering:

```swift
class MyContentFactory: DefaultChatContentFactory {

    // Custom media rendering
    override func contentView(for media: MessageMedia, message: ChatMessage,
                              width: CGFloat, theme: ChatTheme, layout: ChatLayout,
                              onInteraction: @escaping (ChatContentInteraction) -> Void) -> UIView {
        if case .custom(let type, let payload) = media, type == "location",
           let loc = payload.base as? LocationPayload {
            let view = LocationMapView()
            view.configure(location: loc)
            view.onTap = { onInteraction(.mediaTap(index: 0)) }
            return view
        }
        return super.contentView(for: media, message: message, width: width,
                                 theme: theme, layout: layout, onInteraction: onInteraction)
    }

    // Custom height calculation for custom types
    override func contentHeight(for media: MessageMedia, width: CGFloat, layout: ChatLayout) -> CGFloat {
        if case .custom(let type, _) = media, type == "location" {
            return 200
        }
        return super.contentHeight(for: media, width: width, layout: layout)
    }

    // Custom date separator
    override func dateSeparatorView(title: String, theme: ChatTheme, layout: ChatLayout) -> UIView {
        let label = UILabel()
        label.text = title
        label.font = .boldSystemFont(ofSize: 14)
        label.textColor = .white
        label.backgroundColor = .systemBlue
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        return label
    }

    // Custom footer
    override func footerView(message: ChatMessage, theme: ChatTheme,
                             layout: ChatLayout, features: ChatFeatures) -> UIView? {
        // Return nil to hide footer entirely
        // Or return custom view
        return super.footerView(message: message, theme: theme, layout: layout, features: features)
    }
}

// Apply
chatVC.contentFactory = MyContentFactory()
```

### Factory Methods

| Method | Purpose |
|---|---|
| `contentView(for:message:width:theme:layout:onInteraction:)` | Media content (images, voice, poll, files, custom) |
| `contentHeight(for:width:layout:)` | Height calculation for media content |
| `textView(text:isMine:theme:layout:)` | Text portion of message |
| `textHeight(text:font:width:)` | Text height calculation |
| `emojiView(text:emojiCount:layout:)` | Emoji-only messages |
| `reactionsView(reactions:theme:maxWidth:layout:onTap:)` | Reaction chips |
| `replyPreviewView(reply:resolved:isMine:theme:layout:onTap:)` | Reply quote block |
| `footerView(message:theme:layout:features:)` | Time + edited + status |
| `senderNameView(name:theme:layout:)` | Sender name label |
| `forwardedHeaderView(from:isMine:theme:layout:)` | "Forwarded from" label |
| `dateSeparatorView(title:theme:layout:)` | Date separator pill |
| `dateSeparatorHeight(layout:)` | Date separator height |
| `floatingDateView(title:theme:layout:)` | Floating date during scroll |

---

## Delegate

```swift
// Compose only the protocols you need:
protocol ChatScrollDelegate       // scroll, pagination, FAB tap
protocol ChatVisibilityDelegate   // message visibility tracking
protocol ChatMessageDelegate      // tap, long press, reactions, polls
protocol ChatInputDelegate        // send, edit, attachment, voice recording

// Or use the composite:
typealias ChatViewControllerDelegate = ChatScrollDelegate & ChatVisibilityDelegate 
    & ChatMessageDelegate & ChatInputDelegate
```

All delegate methods have default empty implementations.

---

## InputBar (Standalone)

InputBar can be used independently from ChatViewController:

```swift
let inputBar = InputBarView()
inputBar.delegate = self
inputBar.applyTheme(.dark)

// Modes
inputBar.beginReply(info: InputBarReplyInfo(messageId: "1", senderName: "Alice", text: "Hello", hasImage: false))
inputBar.beginEdit(messageId: "1", text: "Updated text")
inputBar.cancelMode()

// Configuration
inputBar.showAttachButton = true
inputBar.voiceRecordingEnabled = true
```

---

## Utilities

```swift
// Text measurement (available for custom content factories)
let height = ChatTextMeasurer.height("Hello", font: .systemFont(ofSize: 15), width: 280)
let width = ChatTextMeasurer.width("Hello", font: .systemFont(ofSize: 15))
let font = ChatTextMeasurer.emojiFont(for: 2, layout: ChatLayout())
```

---

## Architecture

```
IOSChatView/
├── ChatView/           # Main chat component
│   ├── Controller/     # ChatViewController + extensions
│   ├── Components/     # FABManager, FloatingDate, EmptyState, MessageUpdateHandler
│   ├── Factory/        # ChatContentFactory protocol + DefaultChatContentFactory
│   ├── Models/         # ChatMessage, ChatTheme, ChatLayout, ChatFeatures
│   ├── Views/          # MessageCell, MessageBubbleView, Content/*
│   ├── IGList/         # Section controllers, MessageSizeCalculator
│   ├── Audio/          # VoicePlayer
│   └── Helpers/        # DateHelper, ImageCache, ChatTextMeasurer
├── InputBar/           # Standalone input bar module
│   ├── Audio/          # VoiceRecorder
│   └── Views/          # RecordingRow, ReplyPanel, LockView
└── ContextMenu/        # Long-press context menu module
```

---

## License

MIT License. See [LICENSE](LICENSE) for details.
