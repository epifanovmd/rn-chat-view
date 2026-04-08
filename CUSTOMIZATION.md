# Custom Content Types & Factory Guide

IOSChatView is a content-agnostic chat UI. The library knows nothing about message types — all rendering, sizing, and interaction handling is delegated to `ChatContentFactory`. This guide shows how to define custom content types, build a custom factory, and handle interactions.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Defining Custom Content Types](#defining-custom-content-types)
- [Creating Messages with Custom Content](#creating-messages-with-custom-content)
- [Building a Custom Factory](#building-a-custom-factory)
- [Handling Content Interactions](#handling-content-interactions)
- [Delegate Reference](#delegate-reference)
- [Built-in Content Types](#built-in-content-types)
- [Full Example](#full-example)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│  Your App                                           │
│  ┌─────────────┐  ┌────────────┐  ┌──────────────┐ │
│  │ Content      │  │ Factory    │  │ Delegate     │ │
│  │ Types        │  │            │  │              │ │
│  │ PaymentContent│ │ MyFactory  │  │ MyVC         │ │
│  │ LocationContent│ contentView()│ │ chatDid...() │ │
│  └──────┬──────┘  └─────┬──────┘  └──────┬───────┘ │
│         │               │                │         │
├─────────┼───────────────┼────────────────┼─────────┤
│  IOSChatView Library    │                │         │
│         │               │                │         │
│  ┌──────▼──────┐  ┌─────▼──────┐  ┌──────▼───────┐ │
│  │AnyChatContent│  │ChatContent │  │ChatViewController│
│  │(opaque box) │  │Factory     │  │Delegate      │ │
│  └─────────────┘  │(protocol)  │  │(protocol)    │ │
│                   └────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────┘
```

**Key principle:** The library core only works with `AnyChatContent` (an opaque wrapper) and `ChatContentInteraction` (a generic event struct). It never inspects what's inside — your factory does all the work.

---

## Defining Custom Content Types

Any struct conforming to `ChatContent` can be used as message content:

```swift
import IOSChatView

// 1. Define your content type
struct PaymentContent: ChatContent {
    // Required: unique identifier for this type
    static let contentTypeID = "payment"
    
    // Your custom fields — fully type-safe
    let amount: Decimal
    let currency: String
    let recipientName: String
    let status: PaymentStatus
    
    enum PaymentStatus: String, Hashable, Sendable {
        case pending, completed, failed
    }
}

struct LocationContent: ChatContent {
    static let contentTypeID = "location"
    
    let latitude: Double
    let longitude: Double
    let address: String
    let mapSnapshotURL: String?
}

struct ContactContent: ChatContent {
    static let contentTypeID = "contact"
    
    let name: String
    let phone: String
    let avatarURL: String?
}
```

**Requirements for `ChatContent`:**
- Must conform to `Equatable`, `Hashable`, `Sendable` (inherited from protocol)
- Must have a `static var contentTypeID: String` — unique string per type
- All properties must be `Hashable` and `Sendable`

---

## Creating Messages with Custom Content

Wrap your content in `AnyChatContent` and pass it to `MessageBody`:

```swift
// Custom content message
let paymentMessage = ChatMessage(
    id: "msg-1",
    content: MessageBody(
        text: "Payment sent",  // optional text caption
        content: AnyChatContent(PaymentContent(
            amount: 42.50,
            currency: "USD",
            recipientName: "Alice",
            status: .completed
        ))
    ),
    timestamp: Date(),
    senderName: "Bob",
    ownership: .mine,
    groupDate: "2026-04-06",
    status: .delivered,
    reply: nil,
    forwardedFrom: nil,
    reactions: [],
    isEdited: false,
    actions: []
)

// Text-only message (no content)
let textMessage = ChatMessage(
    id: "msg-2",
    content: MessageBody(text: "Hello!"),
    // ... other fields
)

// Content-only message (no text)
let locationMessage = ChatMessage(
    id: "msg-3",
    content: MessageBody(
        text: nil,
        content: AnyChatContent(LocationContent(
            latitude: 55.7539,
            longitude: 37.6208,
            address: "Red Square, Moscow",
            mapSnapshotURL: nil
        ))
    ),
    // ... other fields
)
```

---

## Building a Custom Factory

### Option A: Subclass DefaultChatContentFactory

Best when you want to **add** custom types while keeping built-in ones (images, voice, poll, files):

```swift
class MyFactory: DefaultChatContentFactory {
    
    override func contentView(
        for media: AnyChatContent,
        message: ChatMessage,
        width: CGFloat,
        theme: ChatTheme,
        layout: ChatLayout,
        onInteraction: @escaping (ChatContentInteraction) -> Void
    ) -> UIView {
        // Handle your custom types
        if let payment = media.content(as: PaymentContent.self) {
            return makePaymentView(payment, onInteraction: onInteraction)
        }
        if let location = media.content(as: LocationContent.self) {
            return makeLocationView(location, onInteraction: onInteraction)
        }
        // Fall back to default for built-in types
        return super.contentView(for: media, message: message, width: width,
                                  theme: theme, layout: layout, onInteraction: onInteraction)
    }
    
    override func contentHeight(
        for media: AnyChatContent,
        width: CGFloat,
        layout: ChatLayout
    ) -> CGFloat {
        if media.content(as: PaymentContent.self) != nil { return 80 }
        if media.content(as: LocationContent.self) != nil { return 160 }
        return super.contentHeight(for: media, width: width, layout: layout)
    }
    
    // Build your custom views
    private func makePaymentView(
        _ payment: PaymentContent,
        onInteraction: @escaping (ChatContentInteraction) -> Void
    ) -> UIView {
        let view = PaymentCardView()
        view.configure(payment: payment)
        view.onTap = {
            onInteraction(ChatContentInteraction(
                type: "paymentTap",
                payload: ["amount": payment.amount as AnyHashable]
            ))
        }
        return view
    }
}
```

### Option B: Implement ChatContentFactory from scratch

For a fully custom chat with no built-in types:

```swift
class MinimalFactory: NSObject, ChatContentFactory {
    
    func contentView(for media: AnyChatContent, message: ChatMessage,
                     width: CGFloat, theme: ChatTheme, layout: ChatLayout,
                     onInteraction: @escaping (ChatContentInteraction) -> Void) -> UIView {
        // Handle ALL your types here — no fallback
        if let payment = media.content(as: PaymentContent.self) {
            return makePaymentView(payment)
        }
        // Unknown type fallback
        let label = UILabel()
        label.text = "[\(media.contentTypeID)]"
        return label
    }
    
    func contentHeight(for media: AnyChatContent, width: CGFloat,
                       layout: ChatLayout) -> CGFloat {
        if media.content(as: PaymentContent.self) != nil { return 80 }
        return 44
    }
    
    func reconfigureContentView(_ view: UIView, for media: AnyChatContent,
                                 message: ChatMessage, width: CGFloat,
                                 theme: ChatTheme, layout: ChatLayout,
                                 onInteraction: @escaping (ChatContentInteraction) -> Void) -> Bool {
        // Return true if you successfully updated the view in-place
        // Return false to fall back to full view rebuild
        if let payment = media.content(as: PaymentContent.self),
           let paymentView = view as? PaymentCardView {
            paymentView.configure(payment: payment)
            return true
        }
        return false
    }
    
    // ... implement remaining protocol methods (text, emoji, reactions, etc.)
}
```

### Option C: Override specific UI elements only

```swift
class ThemedFactory: DefaultChatContentFactory {
    
    // Custom sender name with avatar
    override func senderNameView(name: String, theme: ChatTheme, layout: ChatLayout) -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        // ... add avatar circle + label
        return stack
    }
    
    // Custom footer with encryption icon
    override func footerView(message: ChatMessage, theme: ChatTheme,
                              layout: ChatLayout, features: ChatFeatures) -> UIView? {
        let view = EncryptedFooterView()
        view.configure(message: message, theme: theme)
        return view
    }
    
    // Custom empty state
    override func emptyStateView(theme: ChatTheme, layout: ChatLayout) -> UIView {
        let view = AnimatedEmptyStateView()
        view.configure(theme: theme)
        return view
    }
    
    // Custom FAB button
    override func fabView(theme: ChatTheme, layout: ChatLayout) -> UIView {
        let button = GradientFABButton()
        button.configure(theme: theme, size: layout.inputButtonSize)
        return button
    }
}
```

### Assigning the factory

```swift
let chatVC = ChatViewController()
chatVC.contentFactory = MyFactory()  // or ThemedFactory(), MinimalFactory(), etc.
```

---

## Handling Content Interactions

### Firing interactions from custom views

Inside your factory's `contentView(for:...)`, use the `onInteraction` callback:

```swift
func makePaymentView(
    _ payment: PaymentContent,
    onInteraction: @escaping (ChatContentInteraction) -> Void
) -> UIView {
    let view = PaymentCardView()
    view.configure(payment: payment)
    
    // Tap on the whole card
    view.onTap = {
        onInteraction(ChatContentInteraction(
            type: "paymentTap",
            payload: [
                "amount": payment.amount as AnyHashable,
                "currency": payment.currency as AnyHashable,
                "status": payment.status.rawValue as AnyHashable,
            ]
        ))
    }
    
    // Tap on "Pay Again" button
    view.onPayAgain = {
        onInteraction(ChatContentInteraction(
            type: "paymentPayAgain",
            payload: ["amount": payment.amount as AnyHashable]
        ))
    }
    
    // Tap on "Details" link
    view.onDetails = {
        onInteraction(ChatContentInteraction(
            type: "paymentDetails",
            payload: ["transactionId": payment.transactionId as AnyHashable]
        ))
    }
    
    return view
}
```

### Receiving interactions in the delegate

All content interactions arrive through a single delegate method:

```swift
func chatDidContentInteraction(messageId: String, interaction: ChatContentInteraction) {
    switch interaction.type {
    case "paymentTap":
        let amount = interaction.payload["amount"] as? Decimal ?? 0
        showPaymentDetails(messageId: messageId, amount: amount)
        
    case "paymentPayAgain":
        let amount = interaction.payload["amount"] as? Decimal ?? 0
        initiatePayment(amount: amount)
        
    case "locationTap":
        let lat = interaction.payload["lat"] as? Double ?? 0
        let lon = interaction.payload["lon"] as? Double ?? 0
        openMap(latitude: lat, longitude: lon)
        
    case "contactCall":
        let phone = interaction.payload["phone"] as? String ?? ""
        callPhone(phone)
        
    default:
        break
    }
}
```

### Built-in interaction convenience constructors

`DefaultChatContentFactory` uses these for built-in types:

```swift
// These are defined as static methods on ChatContentInteraction:
ChatContentInteraction.mediaTap(index: 0)           // type: "mediaTap"
ChatContentInteraction.fileTap(index: 2)             // type: "fileTap"
ChatContentInteraction.pollOptionTap(pollId: "p1", optionId: "o1")  // type: "pollOptionTap"
ChatContentInteraction.pollDetailTap(pollId: "p1")   // type: "pollDetailTap"
ChatContentInteraction.voiceTap(url: "https://...")   // type: "voiceTap"
```

---

## Delegate Reference

`ChatViewControllerDelegate` is a composite of four focused protocols. All methods have default empty implementations — implement only what you need.

### ChatScrollDelegate

```swift
/// Called on every scroll event (throttled by `layout.scrollThrottleInterval`).
func chatDidScroll(offset: CGPoint)

/// Called when the user scrolls near the top (within `features.topLoadThreshold`).
/// Use this to load older messages.
func chatDidReachTop(distance: CGFloat)

/// Called when the user scrolls near the bottom (within `features.bottomLoadThreshold`).
/// Use this to load newer messages.
func chatDidReachBottom(distance: CGFloat)

/// Called when the user taps the FAB (scroll-to-bottom button).
func chatDidTapFAB()
```

**Typical implementation:**

```swift
func chatDidReachTop(distance: CGFloat) {
    guard !chatVC.isLoadingTop else { return }
    chatVC.isLoadingTop = true
    api.loadOlderMessages { [weak self] messages in
        self?.chatVC.isLoadingTop = false
        self?.chatVC.updateMessages(messages + self!.chatVC.messages)
    }
}

func chatDidTapFAB() {
    chatVC.clearUnread()
    chatVC.scrollToBottom(animated: true)
}
```

### ChatVisibilityDelegate

```swift
/// Called when messages become visible on screen (debounced).
/// Use this to send read receipts.
func chatMessagesDidAppear(ids: [String])
```

**Typical implementation:**

```swift
func chatMessagesDidAppear(ids: [String]) {
    api.markAsRead(messageIds: ids)
}
```

### ChatMessageDelegate

```swift
/// Called when a message bubble is tapped.
func chatDidTapMessage(id: String, attachmentIndex: Int?)

/// Called when the user selects an action from the context menu.
func chatDidSelectAction(actionId: String, messageId: String)

/// Called when the user selects an emoji from the context menu reaction bar.
func chatDidSelectEmojiReaction(emoji: String, messageId: String)

/// Called when the user taps an existing reaction chip below a message.
func chatDidTapReaction(messageId: String, emoji: String)

/// Called when the user taps the reply preview inside a message.
func chatDidTapReplyMessage(id: String)

/// Called when a factory-created content view fires an interaction.
/// ALL content-type-specific interactions go through this single method.
func chatDidContentInteraction(messageId: String, interaction: ChatContentInteraction)

/// Called when the user taps a thread indicator on a message.
func chatDidTapThread(messageId: String, threadId: String)

/// Called when the user taps a detected link in a message.
func chatDidTapLink(url: URL, messageId: String)

/// Called when the user taps a detected phone number in a message.
func chatDidTapPhoneNumber(phoneNumber: String, messageId: String)
```

**Typical implementation:**

```swift
func chatDidSelectAction(actionId: String, messageId: String) {
    switch actionId {
    case "reply":
        guard let msg = chatVC.message(forID: messageId) else { return }
        chatVC.beginReply(info: ReplyInfo(
            replyToId: messageId,
            senderName: msg.senderName ?? "You",
            text: msg.content.text,
            hasImage: msg.content.content != nil
        ))
    case "edit":
        guard let msg = chatVC.message(forID: messageId) else { return }
        chatVC.beginEdit(messageId: messageId, text: msg.content.text ?? "")
    case "delete":
        var msgs = chatVC.messages
        msgs.removeAll { $0.id == messageId }
        chatVC.updateMessages(msgs)
    default:
        break
    }
}

func chatDidTapReplyMessage(id: String) {
    chatVC.scrollToMessage(id: id, position: "center", animated: true, highlight: true)
}

func chatDidContentInteraction(messageId: String, interaction: ChatContentInteraction) {
    switch interaction.type {
    case "pollOptionTap":
        let optionId = interaction.payload["optionId"] as? String ?? ""
        togglePollVote(messageId: messageId, optionId: optionId)
    case "paymentTap":
        showPaymentDetails(messageId: messageId)
    default:
        break
    }
}
```

### ChatInputDelegate

```swift
/// Called when the user sends a message.
func chatDidSendMessage(text: String, replyToId: String?)

/// Called when the user confirms an edit.
func chatDidEditMessage(text: String, messageId: String)

/// Called when the user cancels a reply or edit. `type` is "reply" or "edit".
func chatDidCancelInputAction(type: String)

/// Called when the user taps the attachment button.
func chatDidTapAttachment()

/// Called when a voice recording is completed.
func chatDidCompleteVoiceRecording(fileURL: URL, duration: TimeInterval, waveform: [Float])

/// Called on text input changes (throttled).
func chatDidChangeInputText(_ text: String)
```

**Typical implementation:**

```swift
func chatDidSendMessage(text: String, replyToId: String?) {
    let message = createMessage(text: text, replyToId: replyToId)
    var messages = chatVC.messages
    messages.append(message)
    chatVC.updateMessages(messages)
    api.sendMessage(message)
}

func chatDidEditMessage(text: String, messageId: String) {
    var messages = chatVC.messages
    guard let idx = messages.firstIndex(where: { $0.id == messageId }) else { return }
    let old = messages[idx]
    messages[idx] = ChatMessage(
        id: old.id,
        content: MessageBody(text: text, content: old.content.content),
        // ... copy other fields, set isEdited: true
    )
    chatVC.updateMessages(messages)
}
```

---

## Built-in Content Types

These ship with the library in `DefaultContent/` and are handled by `DefaultChatContentFactory`:

| Type | contentTypeID | Payload | View |
|------|--------------|---------|------|
| `ImagesContent` | `builtin.images` | `[MediaItem]` — images and videos | Grid layout (1-4 items) |
| `VoicePayload` | `builtin.voice` | URL, duration, waveform | Play button + waveform |
| `PollPayload` | `builtin.poll` | Question, options, votes | Animated poll bars |
| `FilesContent` | `builtin.files` | `[FilePayload]` — files | File rows with icons |

```swift
// Using built-in types
let imageMsg = MessageBody(
    text: "Check this out",
    content: AnyChatContent(ImagesContent([
        .image(ImageItem(url: "https://...", width: 400, height: 300, thumbnailUrl: nil)),
    ]))
)

let voiceMsg = MessageBody(
    text: nil,
    content: AnyChatContent(VoicePayload(
        url: "https://...",
        duration: 12.5,
        waveform: [0.1, 0.4, 0.8, 0.6, 0.3]
    ))
)
```

---

## Full Example

A complete view controller with custom content types:

```swift
import IOSChatView
import UIKit

// MARK: - Custom Types

struct PaymentContent: ChatContent {
    static let contentTypeID = "payment"
    let amount: Decimal
    let currency: String
}

// MARK: - Custom Factory

class MyFactory: DefaultChatContentFactory {
    override func contentView(
        for media: AnyChatContent, message: ChatMessage, width: CGFloat,
        theme: ChatTheme, layout: ChatLayout,
        onInteraction: @escaping (ChatContentInteraction) -> Void
    ) -> UIView {
        if let payment = media.content(as: PaymentContent.self) {
            let label = UILabel()
            label.text = "\(payment.amount) \(payment.currency)"
            label.font = .monospacedDigitSystemFont(ofSize: 24, weight: .bold)
            label.textColor = .systemGreen
            label.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: nil, action: nil)
            // ... wire up onInteraction
            return label
        }
        return super.contentView(for: media, message: message, width: width,
                                  theme: theme, layout: layout, onInteraction: onInteraction)
    }
    
    override func contentHeight(for media: AnyChatContent, width: CGFloat,
                                 layout: ChatLayout) -> CGFloat {
        if media.content(as: PaymentContent.self) != nil { return 50 }
        return super.contentHeight(for: media, width: width, layout: layout)
    }
}

// MARK: - View Controller

class MyChatVC: UIViewController, ChatViewControllerDelegate {
    let chatVC = ChatViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        chatVC.contentFactory = MyFactory()
        chatVC.delegate = self
        chatVC.theme = .dark
        chatVC.features.senderNameMode = .incomingOnly
        chatVC.features.emojiReactions = ["👍", "❤️", "😂", "💸"]
        
        addChild(chatVC)
        view.addSubview(chatVC.view)
        chatVC.view.frame = view.bounds
        chatVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        chatVC.didMove(toParent: self)
        
        chatVC.updateMessages(makeSampleMessages())
    }
    
    func makeSampleMessages() -> [ChatMessage] {
        [
            ChatMessage(
                id: "1",
                content: MessageBody(
                    text: "Payment received!",
                    content: AnyChatContent(PaymentContent(amount: 42.50, currency: "USD"))
                ),
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
        ]
    }
    
    // MARK: - Delegate
    
    func chatDidContentInteraction(messageId: String, interaction: ChatContentInteraction) {
        print("Interaction: \(interaction.type) on message \(messageId)")
    }
    
    func chatDidSendMessage(text: String, replyToId: String?) {
        // Append and update
    }
}
```

---

## ChatContentFactory Methods

The factory protocol covers all customizable views:

| Category | Methods |
|----------|---------|
| **Content** | `contentView(for:...)`, `contentHeight(for:...)`, `reconfigureContentView(_:for:...)` |
| **Text** | `textView(text:ownership:theme:layout:linkDetectionEnabled:onLinkTap:)`, `textHeight(text:...)` |
| **Emoji** | `emojiView(text:emojiCount:...)` |
| **Reactions** | `reactionsView(reactions:...)` |
| **Reply** | `replyPreviewView(reply:...)` |
| **Footer** | `footerView(message:...)` |
| **Sender** | `senderNameView(name:...)` |
| **Forward** | `forwardedHeaderView(from:...)` |
| **Dates** | `dateSeparatorView(title:...)`, `dateSeparatorHeight(...)`, `floatingDateView(title:...)` |
| **Empty State** | `emptyStateView(...)`, `emptyStateLoadingView(...)` |
| **Loading** | `loadingIndicatorView(...)` |
| **Thread** | `threadIndicatorView(thread:ownership:theme:layout:onTap:)` |
| **Avatar** | `avatarView(name:url:size:theme:layout:)` |
| **FAB** | `fabView(...)`, `fabBadgeView(...)` |

Override any of these in your factory subclass to customize the corresponding UI element.
