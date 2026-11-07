# Timeblock

A native macOS menu bar app for time-blocked deep work. Plan your day in blocks, run a per-block timer, see a live countdown in the menu bar.

- Lives in the menu bar — no Dock icon, no window clutter.
- Plan today (or tomorrow / yesterday) as an ordered list of blocks.
- Start a block, watch it count down. Pause, resume, skip, or reset.
- Local notification when a block ends. Auto-advances to the next pending block (you confirm the start).
- Persists with SwiftData; survives quit, sleep/wake, restarts.

## Requirements

- **macOS 14 Sonoma or newer** (uses `MenuBarExtra`, `@Observable`, SwiftData).
- **Xcode 15.4+** — install free from the Mac App Store: https://apps.apple.com/app/xcode/id497799835

You currently have only Command Line Tools installed. You need the full Xcode app to build a SwiftUI Mac app.

## Setup — option A: XcodeGen (recommended, ~30 sec)

The repo includes a `project.yml` that generates `Timeblock.xcodeproj` automatically.

```bash
brew install xcodegen
cd "/Users/karlschneidewind/Downloads/Timeblock App"
xcodegen generate
open Timeblock.xcodeproj
```

Then in Xcode: **⌘R** to run. The menu bar icon appears at the top-right of your screen.

If macOS prompts for notification permission on first launch, allow it (used for the block-end alert).

## Setup — option B: Manual Xcode project (no XcodeGen)

1. Open Xcode → **File → New → Project**.
2. Choose **macOS → App**, click **Next**.
3. Set:
   - Product Name: `Timeblock`
   - Team: your Apple ID (or "None")
   - Organization Identifier: `com.karlschneidewind`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **SwiftData** (or None — we configure it in code anyway)
   - Tests: off
4. Save the project **inside this folder** (`/Users/karlschneidewind/Downloads/Timeblock App`), so the new `Timeblock.xcodeproj` sits next to the existing `Timeblock/` source folder.
5. In Xcode's project navigator, **delete** the auto-generated `TimeblockApp.swift`, `ContentView.swift`, and the auto-generated `Item.swift` if present — choose "Move to Trash".
6. Right-click the `Timeblock` group → **Add Files to "Timeblock"…** → select the existing `Timeblock/` folder → enable **"Create groups"**, **"Copy items if needed" off** (the files already live there) → Add.
7. Open the project settings → **Targets → Timeblock → Info**:
   - Find the underlying `Info.plist` and add **`Application is agent (UIElement)` = YES** (key `LSUIElement`). The provided `Info.plist` already has this; if Xcode generated its own, point the build setting `INFOPLIST_FILE` to `Timeblock/Info.plist`.
8. **Targets → Timeblock → General → Minimum Deployments**: macOS **14.0**.
9. ⌘R to run.

## Project layout

```
Timeblock App/
├── README.md
├── project.yml                       # XcodeGen manifest (option A)
└── Timeblock/                        # source files
    ├── TimeblockApp.swift            # @main, MenuBarExtra scene
    ├── Info.plist                    # LSUIElement = YES (no Dock icon)
    ├── Assets.xcassets/              # AppIcon + AccentColor
    ├── Models/
    │   ├── Block.swift               # @Model — one block
    │   └── DailyPlan.swift           # @Model — date + ordered blocks
    ├── Services/
    │   ├── TimerEngine.swift         # @Observable timer, wall-clock anchored
    │   ├── NotificationService.swift # local block-end notifications
    │   └── PlanRepository.swift      # SwiftData fetch/insert/reorder
    └── Views/
        ├── MenuBarLabelView.swift    # icon + countdown in menu bar
        ├── PopoverRootView.swift     # popover container
        ├── TimerHeaderView.swift     # current/next block + controls
        ├── PlanListView.swift        # today's blocks, swipe + reorder
        ├── BlockRowView.swift        # one row in the plan list
        └── BlockEditorSheet.swift    # add/edit sheet
```

## Manual test checklist

After ⌘R:

1. Menu bar icon appears at top-right; no Dock icon.
2. Click the icon → popover opens.
3. **Add block** → title "Test", 1 minute → row appears.
4. Tap **Start** → menu bar shows live countdown (e.g. `▶ 0:58 Test`).
5. Quit (popover → ⏻ button). Reopen the app → block is still there with progress preserved.
6. Let the timer hit 0:00 → notification fires, status flips to ✓ done, "Next up" surfaces if another pending block exists.
7. Pause / Resume → countdown stops cleanly, resumes from the same second.
8. Skip → marked skipped, advances to next pending.
9. Drag a block by the row to reorder → new order persists across relaunch.
10. Sleep your Mac for 30 seconds during a running block, wake → elapsed reflects real wall-clock time (we anchor on `Date()`, not a 1Hz tick — so sleep doesn't pause the block).

## Defaults you can change later

- Auto-advance does **not** auto-start the next block — it surfaces a "Start" prompt. Change in `TimerEngine.finishCurrent` if you want hands-off advancement.
- No iCloud sync. Local SwiftData store only. Add CloudKit by configuring a `ModelConfiguration` with `cloudKitDatabase: .private(...)`.
- No global keyboard hotkey. Add via `NSEvent.addGlobalMonitorForEvents` if you want ⌘⌥T from anywhere.
- App icon is a placeholder (no images attached to the AppIcon set yet). Drop PNGs into `Timeblock/Assets.xcassets/AppIcon.appiconset/` to give it a real icon.
