import SwiftUI

struct BlockRowView: View {
    let block: Block
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 8) {
            statusIcon
                .font(.callout)
            Text(block.title)
                .font(.callout)
                .lineLimit(1)
                .strikethrough(block.isFinished)
            Spacer()
            Text(durationLabel)
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isCurrent ? Color.accentColor.opacity(0.15) : Color.clear)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(block.title)
        .accessibilityValue("\(statusLabel), \(accessibilityDuration)")
    }

    private var accessibilityDuration: String {
        if block.status == .running || block.status == .paused {
            let remaining = block.remainingSeconds
            return "\(remaining / 60) minutes \(remaining % 60) seconds remaining"
        }
        return "\(block.durationSeconds / 60) minutes"
    }

    private var statusLabel: String {
        switch block.status {
        case .pending: return "Pending"
        case .running: return "Running"
        case .paused: return "Paused"
        case .done: return "Done"
        case .skipped: return "Skipped"
        }
    }

    private var statusIcon: some View {
        let (name, color): (String, Color) = {
            switch block.status {
            case .pending: return ("circle", .secondary)
            case .running: return ("play.circle.fill", .accentColor)
            case .paused: return ("pause.circle.fill", .orange)
            case .done: return ("checkmark.circle.fill", .green)
            case .skipped: return ("forward.circle.fill", .secondary)
            }
        }()
        return Image(systemName: name).foregroundStyle(color)
    }

    private var durationLabel: String {
        if block.status == .running || block.status == .paused {
            let remaining = block.remainingSeconds
            return String(format: "%d:%02d", remaining / 60, remaining % 60)
        }
        return "\(block.durationSeconds / 60)m"
    }
}
