import Foundation
import SwiftData

@Model
final class DailyPlan {
    @Attribute(.unique) var date: Date

    @Relationship(deleteRule: .cascade, inverse: \Block.plan)
    var blocks: [Block] = []

    init(date: Date) {
        self.date = Calendar.current.startOfDay(for: date)
    }

    var orderedBlocks: [Block] {
        blocks.sorted { $0.orderIndex < $1.orderIndex }
    }

    var nextPendingBlock: Block? {
        orderedBlocks.first { $0.status == .pending }
    }

    func nextOrderIndex() -> Int {
        (blocks.map(\.orderIndex).max() ?? -1) + 1
    }
}
