import SwiftUI

struct BankSelectorSheet: View {
    let availableBanks: [String]
    @Binding var selectedBanks: Set<String>

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(availableBanks, id: \.self) { bank in
                            Button {
                                toggle(bank)
                            } label: {
                                HStack {
                                    Text(bank)
                                        .foregroundColor(.primary)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: isSelected(bank) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(isSelected(bank) ? .blue : .secondary)
                                }
                                .padding(12)
                                .background(Color.gray.opacity(0.08))
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Check any combination \u{2014} questions from every checked bank are mixed together during practice. Nothing checked means every bank is included.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .frame(minWidth: 340, minHeight: 260)
            .navigationTitle("Question Banks")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Select All") { selectedBanks = Set(availableBanks) }
                        Button("Clear (Show All)") { selectedBanks = [] }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    private func isSelected(_ bank: String) -> Bool {
        selectedBanks.isEmpty || selectedBanks.contains(bank)
    }

    private func toggle(_ bank: String) {
        if selectedBanks.isEmpty {
            selectedBanks = Set(availableBanks).subtracting([bank])
        } else if selectedBanks.contains(bank) {
            selectedBanks.remove(bank)
        } else {
            selectedBanks.insert(bank)
        }
    }
}

