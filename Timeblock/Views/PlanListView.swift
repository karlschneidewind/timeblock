import SwiftUI
import SwiftData

struct PlanListView: View {
    @Environment(\.modelContext) private var context
    @Environment(TimerEngine.self) private var timer
    let plan: DailyPlan?
    let onEdit: (Block) -> Void

    private var repository: PlanRepository { PlanRepository(context: context) }

    private var activeBlockID: UUID? {
        guard timer.currentBlockStatus == .running || timer.currentBlockStatus == .paused else { return nil }
        return timer.currentBlockID
    }

    var body: some View {
        if let plan, !plan.blocks.isEmpty {
            List {
                ForEach(plan.orderedBlocks, id: \.id) { block in
                    BlockRowView(block: block, isCurrent: block.id == activeBlockID)
                        .contentShape(Rectangle())
                        .onTapGesture { onEdit(block) }
                        .accessibilityAddTraits(.isButton)
                        .accessibilityHint("Edit block")
                        .accessibilityAction { onEdit(block) }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                delete(block)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                timer.start(block)
                            } label: {
                                Label("Start", systemImage: "play.fill")
                            }
                            .tint(.green)
                        }
                        .contextMenu {
                            Button {
                                timer.start(block)
                            } label: {
                                Label("Start", systemImage: "play.fill")
                            }
                            Button {
                                onEdit(block)
                            } label: {
                                Label("Edit…", systemImage: "pencil")
                            }
                            Divider()
                            Button(role: .destructive) {
                                delete(block)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 1, leading: 6, bottom: 1, trailing: 6))
                        .alignmentGuide(.listRowSeparatorLeading) { d in
                            d[.leading]
                        }
                        .alignmentGuide(.listRowSeparatorTrailing) { d in
                            d[.trailing] - 6
                        }
                }
                .onMove { indices, newOffset in
                    var ordered = plan.orderedBlocks
                    ordered.move(fromOffsets: indices, toOffset: newOffset)
                    repository.reorder(ordered)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        } else {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func delete(_ block: Block) {
        if block.id == timer.currentBlockID { timer.clear() }
        repository.delete(block)
    }
}
