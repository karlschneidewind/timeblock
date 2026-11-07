import AppKit
import SwiftUI
import SwiftData

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var labelUpdater: Task<Void, Never>?
    private var eventMonitor: Any?
    private var outsideClickMonitor: Any?
    private var lastTitle: String = ""

    private let timer = TimerEngine()
    private let notifications = NotificationService()
    private let container: ModelContainer = {
        do {
            return try ModelContainer(for: DailyPlan.self, Block.self)
        } catch {
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }
    }()

    private let idleIcon = NSImage(systemSymbolName: "timer", accessibilityDescription: "Timeblock")

    func applicationDidFinishLaunching(_ notification: Notification) {
        timer.configure(context: container.mainContext, notifications: notifications)
        installStatusItem()
        installPopover()
        startLabelUpdater()
    }

    func applicationWillTerminate(_ notification: Notification) {
        labelUpdater?.cancel()
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        removeOutsideClickMonitor()
        try? container.mainContext.save()
    }

    private func installStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(togglePopover(_:))
        button.image = idleIcon
        button.imagePosition = .imageLeading
    }

    private func installPopover() {
        popover = NSPopover()
        popover.behavior = .applicationDefined
        popover.contentSize = NSSize(width: 280, height: 360)
        let root = PopoverRootView()
            .environment(timer)
            .modelContainer(container)
        popover.contentViewController = NSHostingController(rootView: root)
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover()
        } else {
            openPopover()
        }
    }

    private func openPopover() {
        guard let button = statusItem.button else { return }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        installEscMonitor()
        installOutsideClickMonitor()
    }

    private func closePopover() {
        popover.performClose(nil)
        removeEscMonitor()
        removeOutsideClickMonitor()
    }

    // Global monitors only see events delivered to other apps, so clicks on the
    // status item, the popover, or its child popovers don't trigger this.
    private func installOutsideClickMonitor() {
        guard outsideClickMonitor == nil else { return }
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            Task { @MainActor in self?.closePopover() }
        }
    }

    private func removeOutsideClickMonitor() {
        if let monitor = outsideClickMonitor {
            NSEvent.removeMonitor(monitor)
            outsideClickMonitor = nil
        }
    }

    private func installEscMonitor() {
        guard eventMonitor == nil else { return }
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if event.keyCode == 53 {
                Task { @MainActor in self.closePopover() }
                return nil
            }
            return event
        }
    }

    private func removeEscMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func startLabelUpdater() {
        labelUpdater = Task { [weak self] in
            while !Task.isCancelled {
                self?.refreshStatusItemLabel()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func refreshStatusItemLabel() {
        guard let button = statusItem.button else { return }
        let status = timer.currentBlockStatus
        let showCountdown = timer.currentBlockID != nil
            && (status == .running || status == .paused)

        let newTitle = showCountdown
            ? formatTime(max(0, timer.currentBlockDuration - timer.displayElapsed))
            : ""

        if newTitle != lastTitle {
            button.title = newTitle
            lastTitle = newTitle
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
