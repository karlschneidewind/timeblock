import SwiftUI
import SwiftData

enum EditorMode: Identifiable {
    case adding
    case editing(Block)

    var id: String {
        switch self {
        case .adding: return "adding"
        case .editing(let block): return "editing-\(block.id.uuidString)"
        }
    }

    var block: Block? {
        if case .editing(let b) = self { return b }
        return nil
    }
}

struct PopoverRootView: View {
    @Environment(\.modelContext) private var context
    @Environment(TimerEngine.self) private var timer

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var editorMode: EditorMode?
    @State private var showingDatePicker: Bool = false

    @Query(sort: \DailyPlan.date, order: .reverse) private var plans: [DailyPlan]

    private var plan: DailyPlan? {
        let dayStart = Calendar.current.startOfDay(for: selectedDate)
        return plans.first(where: { $0.date == dayStart })
    }

    private var repository: PlanRepository { PlanRepository(context: context) }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            TimerHeaderView(plan: plan)
            Divider()
            addBlockButton
            PlanListView(
                plan: plan,
                onEdit: { block in editorMode = .editing(block) }
            )
        }
        .frame(width: 280, height: 360)
        .onAppear { ensurePlanExists() }
        .onChange(of: selectedDate) { _, _ in ensurePlanExists() }
        .popover(item: $editorMode, arrowEdge: .leading) { mode in
            BlockEditorSheet(
                editing: mode.block,
                onSave: { title, duration in
                    handleSave(mode: mode, title: title, duration: duration)
                    editorMode = nil
                },
                onCancel: { editorMode = nil }
            )
        }
    }

    private func handleSave(mode: EditorMode, title: String, duration: Int) {
        switch mode {
        case .editing(let block):
            block.title = title
            block.durationSeconds = duration
            repository.save()
        case .adding:
            guard let plan else { return }
            repository.addBlock(to: plan, title: title, durationSeconds: duration)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(headerTitle)
                .font(.subheadline.weight(.semibold))
            Spacer()
            datePickerMenu
            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .font(.subheadline)
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q")
            .help("Quit Timeblock")
            .accessibilityLabel("Quit Timeblock")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private var datePickerMenu: some View {
        Button {
            showingDatePicker.toggle()
        } label: {
            Text(shortDateString)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(minWidth: 70, alignment: .center)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Choose date")
        .accessibilityLabel("Choose date")
        .accessibilityValue(shortDateString)
        .popover(isPresented: $showingDatePicker, arrowEdge: .bottom) {
            DatePicker(
                "Date",
                selection: Binding(
                    get: { selectedDate },
                    set: { newValue in
                        selectedDate = newValue
                        showingDatePicker = false
                    }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .padding(12)
        }
    }

    private var shortDateString: String {
        selectedDate.formatted(date: .numeric, time: .omitted)
    }

    private var addBlockButton: some View {
        HStack {
            Spacer()
            Button {
                editorMode = .adding
            } label: {
                Label("Add block", systemImage: "plus")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .keyboardShortcut("n")
            .disabled(plan == nil)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var headerTitle: String {
        if Calendar.current.isDateInToday(selectedDate) { return "Today" }
        if Calendar.current.isDateInTomorrow(selectedDate) { return "Tomorrow" }
        if Calendar.current.isDateInYesterday(selectedDate) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }

    private func ensurePlanExists() {
        _ = repository.fetchOrCreatePlan(for: selectedDate)
    }
}
