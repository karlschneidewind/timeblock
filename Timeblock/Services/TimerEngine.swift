import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class TimerEngine {
    private(set) var currentBlockID: UUID?
    private(set) var currentBlockTitle: String?
    private(set) var currentBlockDuration: Int = 0
    private(set) var currentBlockStatus: BlockStatus = .pending
    private(set) var isRunning: Bool = false
    private(set) var displayElapsed: Int = 0

    private var runStartedAt: Date?
    private var savedElapsed: Int = 0
    private var tickTask: Task<Void, Never>?

    private var notificationService: NotificationService?
    private var modelContext: ModelContext?

    func configure(context: ModelContext, notifications: NotificationService) {
        self.modelContext = context
        self.notificationService = notifications
    }

    func start(_ block: Block) {
        notificationService?.requestPermissionIfNeeded()
        if let active = activeBlock(), active.id != block.id {
            pauseInternal(active)
        }

        bindCurrent(block)
        savedElapsed = block.elapsedSeconds
        runStartedAt = Date()
        block.status = .running
        currentBlockStatus = .running
        isRunning = true
        displayElapsed = savedElapsed
        try? modelContext?.save()
        startTickLoop()
    }

    func pause() {
        guard let block = activeBlock() else { return }
        pauseInternal(block)
    }

    private func pauseInternal(_ block: Block) {
        flushElapsed(to: block)
        block.status = .paused
        currentBlockStatus = .paused
        isRunning = false
        runStartedAt = nil
        tickTask?.cancel()
        tickTask = nil
        try? modelContext?.save()
    }

    func resume() {
        guard let block = activeBlock(), block.status == .paused else { return }
        savedElapsed = block.elapsedSeconds
        runStartedAt = Date()
        block.status = .running
        currentBlockStatus = .running
        isRunning = true
        try? modelContext?.save()
        startTickLoop()
    }

    func skip() {
        guard let block = activeBlock() else { return }
        flushElapsed(to: block)
        block.status = .skipped
        tickTask?.cancel()
        tickTask = nil
        try? modelContext?.save()
        clearCurrent()
    }

    func reset() {
        guard let block = activeBlock() else { return }
        tickTask?.cancel()
        tickTask = nil
        block.elapsedSeconds = 0
        block.status = .pending
        try? modelContext?.save()
        clearCurrent()
    }

    func clear() {
        tickTask?.cancel()
        tickTask = nil
        clearCurrent()
    }

    private func clearCurrent() {
        currentBlockID = nil
        currentBlockTitle = nil
        currentBlockDuration = 0
        currentBlockStatus = .pending
        isRunning = false
        runStartedAt = nil
        savedElapsed = 0
        displayElapsed = 0
    }

    private func bindCurrent(_ block: Block) {
        currentBlockID = block.id
        currentBlockTitle = block.title
        currentBlockDuration = block.durationSeconds
        currentBlockStatus = block.status
    }

    private func activeBlock() -> Block? {
        guard let id = currentBlockID, let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<Block>(predicate: #Predicate { $0.id == id })
        return try? context.fetch(descriptor).first
    }

    private func flushElapsed(to block: Block) {
        if let started = runStartedAt {
            let delta = Int(Date().timeIntervalSince(started))
            block.elapsedSeconds = savedElapsed + max(0, delta)
        }
    }

    private func startTickLoop() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                self?.tick()
            }
        }
    }

    private func tick() {
        guard isRunning, let block = activeBlock(), let started = runStartedAt else { return }
        let delta = Int(Date().timeIntervalSince(started))
        let total = savedElapsed + max(0, delta)

        if total >= block.durationSeconds {
            block.elapsedSeconds = block.durationSeconds
            block.status = .done
            displayElapsed = block.durationSeconds
            tickTask?.cancel()
            tickTask = nil
            try? modelContext?.save()
            let title = block.title
            clearCurrent()
            Task { @MainActor [weak self] in
                self?.notificationService?.notifyBlockComplete(title: title)
            }
        } else {
            block.elapsedSeconds = total
            displayElapsed = total
        }
    }
}
