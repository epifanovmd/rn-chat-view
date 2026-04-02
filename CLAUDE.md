# rn-chat-view

iOS native chat UI component library.

## Tech Stack

- **Language:** Swift
- **UI:** UIKit (programmatic, no storyboards) + SwiftUI wrapper
- **List engine:** IGListKit 5.x (CocoaPods)
- **Audio:** AVFoundation
- **Min iOS:** 16.0

## Architecture

MVVM-like with delegate pattern. `ChatViewController` is the main orchestrator, split into 7 extensions:

- `+ContextMenu` — long-press context menu
- `+Input` — text input, send, edit, attachments
- `+Keyboard` — keyboard show/hide handling
- `+ListAdapter` — IGListKit data source & adapter
- `+Scroll` — scroll logic, FAB, floating date pill
- `+Updater` — message insert/update/delete with diff

Host app integrates via `ChatViewControllerDelegate` (20 callback methods).

## Project Structure

```
rn-chat-view/
├── ChatApp.swift                    # SwiftUI entry point
├── ChatDemoViewController.swift     # Demo with sample data
├── ChatView/
│   ├── Controller/                  # ChatViewController + extensions
│   ├── Views/                       # MessageBubbleView, ChatInputBar, Content/
│   ├── IGList/                      # SectionControllers, ChatListItems, SizeCalculator
│   ├── Models/                      # ChatModels, ChatParsing
│   ├── Theme/                       # ChatTheme (light/dark)
│   ├── Audio/                       # VoiceRecorder, VoicePlayer
│   ├── Helpers/                     # DateHelper, ImageCache
│   ├── Keyboard/                    # KeyboardListener
│   └── Constants/                   # ChatLayoutConstants
├── ContextMenu/                     # Long-press popup (actions + emoji)
```

## Conventions

- All UI built programmatically with AutoLayout constraints
- Views use closure callbacks for event bubbling; controllers use delegate protocols
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
