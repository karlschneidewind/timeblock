import Foundation
import SwiftData

@MainActor
struct PlanRepository {
    let context: ModelContext

    func fetchOrCreatePlan(for date: Date) -> DailyPlan {
        let dayStart = Calendar.current.startOfDay(for: date)
        let allPlans = (try? context.fetch(FetchDescriptor<DailyPlan>())) ?? []
        if let existing = allPlans.first(where: { $0.date == dayStart }) {
            return existing
        }
        let plan = DailyPlan(date: dayStart)
        context.insert(plan)
        try? context.save()
        return plan
    }

    func addBlock(to plan: DailyPlan, title: String, durationSeconds: Int) {
        let block = Block(
            title: title,
            durationSeconds: durationSeconds,
            orderIndex: plan.nextOrderIndex()
        )
        context.insert(block)
        block.plan = plan
        try? context.save()
    }

    func delete(_ block: Block) {
        context.delete(block)
        try? context.save()
    }

    func reorder(_ blocks: [Block]) {
        for (index, block) in blocks.enumerated() {
            block.orderIndex = index
        }
        try? context.save()
    }

    func save() {
        try? context.save()
    }
}
