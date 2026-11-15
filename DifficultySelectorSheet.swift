import SwiftUI


struct DifficultySelectorSheet: View {
    @Binding var selectedDifficulties: Set<String>

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(ReadingPracticeView.difficultyLevels, id: \.self) { level in
                            Button {
                                toggle(level)
                            } label: {
                                HStack {
                                    Text(level)
                                        .foregroundColor(.primary)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: isSelected(level) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(isSelected(level) ? .blue : .secondary)
                                }
                                .padding(12)
                                .background(Color.gray.opacity(0.08))
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Check any combination \u{2014} questions at every checked difficulty are mixed together during practice. Nothing checked means every difficulty is included.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .frame(minWidth: 320, minHeight: 260)
            .navigationTitle("Difficulty")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Select All") { selectedDifficulties = Set(ReadingPracticeView.difficultyLevels) }
                        Button("Clear (Show All)") { selectedDifficulties = [] }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    private func isSelected(_ level: String) -> Bool {
        selectedDifficulties.isEmpty || selectedDifficulties.contains(level)
    }

    private func toggle(_ level: String) {
        if selectedDifficulties.isEmpty {
            selectedDifficulties = Set(ReadingPracticeView.difficultyLevels).subtracting([level])
        } else if selectedDifficulties.contains(level) {
            selectedDifficulties.remove(level)
        } else {
            selectedDifficulties.insert(level)
        }
    }
}
