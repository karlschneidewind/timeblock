import SwiftUI
import SwiftData

struct TimerHeaderView: View {
    @Environment(TimerEngine.self) private var timer
    let plan: DailyPlan?

    private var activeBlock: Block? {
        guard let plan,
              let id = timer.currentBlockID,
              timer.currentBlockStatus == .running || timer.currentBlockStatus == .paused
        else { return nil }
        return plan.blocks.first { $0.id == id }
    }

    private var nextBlock: Block? {
        guard let plan else { return nil }
        if let id = timer.currentBlockID,
           timer.currentBlockStatus == .pending,
           let block = plan.blocks.first(where: { $0.id == id }) {
            return block
        }
        return plan.nextPendingBlock
    }

    var body: some View {
        VStack(spacing: 10) {
            if let block = activeBlock {
                CircularTimer(
                    remaining: max(0, block.durationSeconds - timer.displayElapsed),
                    total: block.durationSeconds,
                    title: block.title,
                    isRunning: timer.isRunning
                )
                activeControls
            } else if let block = nextBlock {
                CircularTimer(
                    remaining: block.durationSeconds,
                    total: block.durationSeconds,
                    title: block.title,
                    isRunning: false
                )
                nextControls(for: block)
            } else {
                emptyState
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "timer")
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundStyle(.tertiary)
                .frame(width: 110, height: 110)
                .accessibilityHidden(true)
            Text("Add a block to begin")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(height: 28)
        }
    }

    @ViewBuilder
    private var activeControls: some View {
        HStack(spacing: 10) {
            if timer.isRunning {
                controlButton("Pause", systemImage: "pause.fill") { timer.pause() }
            } else {
                controlButton("Start", systemImage: "play.fill") { timer.resume() }
            }
            controlButton("Skip", systemImage: "forward.end.fill") { timer.skip() }
        }
    }

    private func nextControls(for block: Block) -> some View {
        controlButton("Start", systemImage: "play.fill") { timer.start(block) }
    }

    private func controlButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}

private struct CircularTimer: View {
    let remaining: Int
    let total: Int
    let title: String?
    let isRunning: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var remainingFraction: Double {
        guard total > 0 else { return 0 }
        return max(0, min(1, Double(remaining) / Double(total)))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.18), lineWidth: 4)
            Circle()
                .trim(from: 0, to: remainingFraction)
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(isRunning && !reduceMotion ? .linear(duration: 1) : nil, value: remainingFraction)
            VStack(spacing: 2) {
                Text(formatTime(remaining))
                    .font(.system(.title, design: .rounded, weight: .light))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if let title {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .padding(.horizontal, 14)
        }
        .frame(width: 110, height: 110)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title ?? "Timer")
        .accessibilityValue("\(remaining / 60) minutes \(remaining % 60) seconds remaining")
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
