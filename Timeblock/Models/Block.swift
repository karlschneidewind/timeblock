import Foundation
import SwiftData

enum BlockStatus: String, Codable, CaseIterable {
    case pending
    case running
    case paused
    case done
    case skipped
}

@Model
final class Block {
    @Attribute(.unique) var id: UUID
    var title: String
    var category: String?
    var durationSeconds: Int
    var elapsedSeconds: Int
    var statusRaw: String
    var scheduledStart: Date?
    var orderIndex: Int

    var plan: DailyPlan?

    var status: BlockStatus {
        get { BlockStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        title: String,
        category: String? = nil,
        durationSeconds: Int,
        elapsedSeconds: Int = 0,
        status: BlockStatus = .pending,
        scheduledStart: Date? = nil,
        orderIndex: Int
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.durationSeconds = durationSeconds
        self.elapsedSeconds = elapsedSeconds
        self.statusRaw = status.rawValue
        self.scheduledStart = scheduledStart
        self.orderIndex = orderIndex
    }

    var remainingSeconds: Int {
        max(0, durationSeconds - elapsedSeconds)
    }

    var isFinished: Bool {
        status == .done || status == .skipped
    }
}
