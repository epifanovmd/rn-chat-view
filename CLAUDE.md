# rn-chat-view

iOS native chat UI component library.

## Tech Stack

- **Language:** Swift
- **UI:** UIKit (programmatic, no storyboards) + SwiftUI wrapper
- **List engine:** IGListKit 5.x (CocoaPods)
- **Audio:** AVFoundation
- **Min iOS:** 16.0

## Architecture

Delegate-based composition. `ChatViewController` is the main orchestrator, split into 5 extensions:

- `+ContextMenu` — long-press context menu presentation + keyboard freeze/restore
- `+Input` — InputBarDelegate conformance, forwards to ChatViewControllerDelegate
- `+ListAdapter` — IGListKit data source, SectionEnvironment & MessageSectionDelegate conformance
- `+Scroll` — UIScrollViewDelegate with throttled events and pagination
- `+Updater` — ListAdapterUpdaterDelegate for batch updates

Extracted managers:
- `FloatingDateManager` — floating date pill during scrolling
- `FABManager` — scroll-to-bottom button + unread badge
- `EmptyStateManager` — empty state view with spinner

### Delegate hierarchy

```
ChatViewControllerDelegate (typealias combining 4 focused protocols):
  ├── ChatScrollDelegate       — scroll, pagination, FAB tap
  ├── ChatVisibilityDelegate   — message visibility tracking
  ├── ChatMessageDelegate      — tap, long press, reactions, polls
  └── ChatInputDelegate        — send, edit, attachment, voice recording

SectionEnvironment (protocol)  — provides theme/layout/features to section controllers
MessageSectionDelegate         — interaction callbacks from message cells
InputBarDelegate               — input bar events → ChatViewController → ChatViewControllerDelegate
```

### Configuration flow

```
ChatConfiguration (theme + layout + features)
  → ChatViewController.configuration property
  → ConfigurationDiff detects changes
  → applyConfigurationDiff() targets specific updates
  → SectionEnvironment provides config to section controllers
  → InputBarView.applyLayout() / applyTheme() for input bar
```

## Project Structure

```
rn-chat-view/
├── ChatApp.swift                    # SwiftUI entry point
├── ChatDemoViewController.swift     # Demo with sample data
├── ChatView/
│   ├── Controller/                  # ChatViewController + 5 extensions
│   ├── Components/                  # FloatingDateManager, FABManager, EmptyStateManager
│   ├── Delegates/                   # ChatViewControllerDelegate (4 sub-protocols)
│   ├── Protocols/                   # SectionEnvironment
│   ├── Configuration/               # ChatConfiguration, ChatFeatures, ConfigurationDiff
│   ├── Theme/                       # ChatTheme (light/dark, 80+ colors)
│   ├── Layout/                      # ChatLayout (unified layout constants)
│   ├── Views/                       # MessageCell, MessageBubbleView, DateSeparatorCell, Content/
│   ├── IGList/                      # SectionControllers, ChatListItems, MessageSizeCalculator
│   ├── Models/                      # ChatModels, ChatParsing (RN bridge parsing)
│   ├── Audio/                       # VoicePlayer
│   └── Helpers/                     # DateHelper, ImageCache
├── InputBar/                        # Self-contained input bar module
│   ├── InputBarView.swift           # Main view + UITextViewDelegate + VoiceRecorderDelegate
│   ├── InputBarView+Recording.swift # Long-press recording gesture state machine
│   ├── InputBarTheme.swift          # Color theme (derived from ChatTheme)
│   ├── Audio/                       # VoiceRecorder (owned by InputBar)
│   ├── Models/                      # InputBarDelegate, InputBarMode, RecordingState
│   └── Views/                       # InputBarRecordingRow, InputBarReplyPanel, InputBarLockView
├── ContextMenu/                     # Long-press popup (actions + emoji)
```

## Conventions

- All UI built programmatically with AutoLayout constraints
- Views use closure callbacks for event bubbling; controllers use delegate protocols
- Section controllers access configuration via `SectionEnvironment` protocol (no global singletons)
- `ChatLayout` has a deprecated `static var current` for views that read defaults at init; new code should pass layout via parameters
- New content types go in `ChatView/Views/Content/`
- New section controllers go in `ChatView/IGList/SectionControllers/`
- Follow existing extension pattern when adding ChatViewController functionality

## Build

```bash
# Install dependencies
pod install

# Build for device (iPhone 13 Pro)
xcodebuild -workspace rn-chat-view.xcworkspace \
  -scheme rn-chat-view \
  -destination 'id=00008110-000C0CA03A21801E' \
  -allowProvisioningUpdates \
  ENABLE_USER_SCRIPT_SANDBOXING=NO \
  build

# Install on device
xcrun devicectl device install app --device 00008110-000C0CA03A21801E \
  ~/Library/Developer/Xcode/DerivedData/rn-chat-view-*/Build/Products/Debug-iphoneos/rn-chat-view.app
```

## Known Issues

- `ENABLE_USER_SCRIPT_SANDBOXING` must be `NO` — CocoaPods rsync scripts are incompatible with Xcode sandbox
