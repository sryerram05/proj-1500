import SwiftUI

struct ConceptSelectorSheet: View {
    @Binding var selectedSkills: Set<String>

    @Environment(\.dismiss) private var dismiss

    private var allSkills: [String] {
        ReadingPracticeView.topics.flatMap { ReadingPracticeView.skillsByTopic[$0] ?? [] }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(ReadingPracticeView.topics, id: \.self) { topic in
                        topicSection(topic)
                    }

                    Text("Check any combination of concepts \u{2014} questions matching any of them are mixed together during practice. Nothing checked means every concept is included.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .frame(minWidth: 380, minHeight: 420)
            .navigationTitle("Concepts")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Select All") { selectedSkills = Set(allSkills) }
                        Button("Clear (Show All)") { selectedSkills = [] }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    private func topicSection(_ topic: String) -> some View {
        let skills = ReadingPracticeView.skillsByTopic[topic] ?? []

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(topic)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Spacer()
                Button(allSelected(skills) ? "Deselect all" : "Select all") {
                    toggleAll(skills)
                }
                .font(.caption)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(skills, id: \.self) { skill in
                    Button {
                        toggle(skill)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(Question.shortSkillLabel(for: skill))
                                    .foregroundColor(.primary)
                                    .fontWeight(.medium)
                                Text(skill)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: isSelected(skill) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isSelected(skill) ? .blue : .secondary)
                        }
                        .padding(12)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func isSelected(_ skill: String) -> Bool {
        selectedSkills.isEmpty || selectedSkills.contains(skill)
    }

    private func allSelected(_ skills: [String]) -> Bool {
        skills.allSatisfy { isSelected($0) }
    }

    private func toggle(_ skill: String) {
        if selectedSkills.isEmpty {
           
            selectedSkills = Set(allSkills).subtracting([skill])
        } else if selectedSkills.contains(skill) {
            selectedSkills.remove(skill)
        } else {
            selectedSkills.insert(skill)
        }
    }

    private func toggleAll(_ skills: [String]) {
        if allSelected(skills) {
            let base = selectedSkills.isEmpty ? Set(allSkills) : selectedSkills
            selectedSkills = base.subtracting(skills)
        } else {
            let base = selectedSkills.isEmpty ? Set(allSkills) : selectedSkills
            selectedSkills = base.union(skills)
        }
    }
}
