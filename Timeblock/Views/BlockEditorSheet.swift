import SwiftUI

struct BlockEditorSheet: View {
    let editing: Block?
    let onSave: (String, Int) -> Void
    let onCancel: () -> Void

    @State private var title: String
    @State private var durationMinutes: Int

    private let presets = [15, 30, 60, 90, 120]
    private let minMinutes = 1
    private let maxMinutes = 240

    init(editing: Block?, onSave: @escaping (String, Int) -> Void, onCancel: @escaping () -> Void) {
        self.editing = editing
        self.onSave = onSave
        self.onCancel = onCancel
        _title = State(initialValue: editing?.title ?? "")
        _durationMinutes = State(initialValue: max(1, (editing?.durationSeconds ?? 60 * 60) / 60))
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var clampedMinutes: Int {
        max(minMinutes, min(maxMinutes, durationMinutes))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 4) {
                ForEach(presets, id: \.self) { preset in
                    Button { durationMinutes = preset } label: {
                        Text("\(preset)")
                            .fontWeight(durationMinutes == preset ? .semibold : .regular)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(durationMinutes == preset ? .accentColor : .secondary)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("\(preset) minutes")
                    .accessibilityAddTraits(durationMinutes == preset ? .isSelected : [])
                }
            }

            HStack(spacing: 6) {
                TextField("60", value: $durationMinutes, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 50)
                    .accessibilityLabel("Duration in minutes")
                Text("min")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Spacer()
                Stepper("Duration", value: $durationMinutes, in: minMinutes...maxMinutes, step: 5)
                    .labelsHidden()
                    .controlSize(.small)
            }

            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(editing == nil ? "Add" : "Save") {
                    guard !trimmedTitle.isEmpty else { return }
                    onSave(trimmedTitle, clampedMinutes * 60)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(trimmedTitle.isEmpty)
            }
        }
        .padding(16)
        .frame(width: 240)
        .onChange(of: durationMinutes) { _, newValue in
            if newValue < minMinutes { durationMinutes = minMinutes }
            else if newValue > maxMinutes { durationMinutes = maxMinutes }
        }
    }
}
