import SwiftUI

struct QuestionSelectorSheet: View {
    let questions: [Question]
    let currentIndex: Int
    let markedForReview: Set<String>
    let answers: [String: AnswerRecord]
    let onSelect: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var jumpToText: String = ""
    @State private var statusFilter: StatusFilter = .all
    @FocusState private var jumpFieldFocused: Bool

    enum StatusFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case unanswered = "Unanswered"
        case answered = "Answered"
        case incorrect = "Incorrect"

        var id: String { rawValue }
    }


    private struct Cell: Identifiable {
        let index: Int
        let question: Question
        var id: String { question.id }
    }

    private var allCells: [Cell] {
        questions.enumerated().map { Cell(index: $0.offset, question: $0.element) }
    }

    private var visibleCells: [Cell] {
        allCells.filter { cell in
            switch statusFilter {
            case .all: return true
            case .unanswered: return answers[cell.question.id] == nil
            case .answered: return answers[cell.question.id] != nil
            case .incorrect: return answers[cell.question.id]?.isCorrect == false
            }
        }
    }

    private var jumpTargetNumber: Int? {
        guard let n = Int(jumpToText), n >= 1, n <= questions.count else { return nil }
        return n
    }

    private var answeredInSet: Int {
        questions.filter { answers[$0.id] != nil }.count
    }

    private var correctInSet: Int {
        questions.filter { answers[$0.id]?.isCorrect == true }.count
    }

    private let gridColumns = [GridItem(.adaptive(minimum: 46, maximum: 46), spacing: 10)]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    TextField("Go to # (1–\(questions.count))", text: $jumpToText)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .textFieldStyle(.roundedBorder)
                        .focused($jumpFieldFocused)
                        .onSubmit(jump)

                    Button("Go", action: jump)
                        .buttonStyle(.borderedProminent)
                        .disabled(jumpTargetNumber == nil)
                }
                .padding()

                Text("\(answeredInSet) of \(questions.count) answered · \(correctInSet) correct")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("Show", selection: $statusFilter) {
                    ForEach(StatusFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 6)

                legend
                    .padding(.top, 10)
                    .padding(.bottom, 8)

                Divider()

                if visibleCells.isEmpty {
                    Spacer()
                    Text(statusFilter == .unanswered
                         ? "Nothing left — you've answered every question here."
                         : "No questions match this filter.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: gridColumns, spacing: 10) {
                            ForEach(visibleCells) { cell in
                                Button {
                                    onSelect(cell.index)
                                    dismiss()
                                } label: {
                                    QuestionCell(
                                        number: cell.index + 1,
                                        difficulty: cell.question.difficulty,
                                        record: answers[cell.question.id],
                                        isMarked: markedForReview.contains(cell.question.id),
                                        isCurrent: cell.index == currentIndex
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Jump to Question")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                jumpFieldFocused = true
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendItem(color: .green, label: "Easy")
            legendItem(color: .orange, label: "Medium")
            legendItem(color: .red, label: "Hard")
            Spacer()
            HStack(spacing: 4) {
                Circle().fill(Color.green.opacity(0.25)).frame(width: 10, height: 10)
                    .overlay(Circle().strokeBorder(Color.green, lineWidth: 1.5))
                Text("Correct").font(.caption2).foregroundColor(.secondary)
            }
            HStack(spacing: 4) {
                Circle().fill(Color.red.opacity(0.25)).frame(width: 10, height: 10)
                    .overlay(Circle().strokeBorder(Color.red, lineWidth: 1.5))
                Text("Wrong").font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(color, lineWidth: 2)
                .frame(width: 10, height: 10)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
    }

    private func jump() {
        guard let n = jumpTargetNumber else { return }
        onSelect(n - 1)
        dismiss()
    }
}

private struct QuestionCell: View {
    let number: Int
    let difficulty: String
    let record: AnswerRecord?
    let isMarked: Bool
    let isCurrent: Bool

    private var difficultyColor: Color {
        switch difficulty.lowercased() {
        case "easy": return .green
        case "medium": return .orange
        case "hard": return .red
        default: return .gray
        }
    }

    private var fillColor: Color {
        guard let record else { return Color(white: 0.5).opacity(0.06) }
        return (record.isCorrect ? Color.green : Color.red).opacity(0.18)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 8)
                .fill(fillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(difficultyColor, lineWidth: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.blue, lineWidth: isCurrent ? 2.5 : 0)
                        .padding(isCurrent ? -2 : 0)
                )
                .frame(width: 44, height: 44)

            Text("\(number)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)

            if let record {
                Image(systemName: record.isCorrect ? "checkmark" : "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(record.isCorrect ? .green : .red)
                    .padding(3)
                    .background(Color(white: 1), in: Circle())
                    .offset(x: 4, y: -4)
            }

            if isMarked {
                Image(systemName: "flag.fill")
                    .font(.system(size: 7))
                    .foregroundColor(.orange)
                    .padding(3)
                    .background(Color(white: 1), in: Circle())
                    .offset(x: -4, y: 4)
                    .frame(width: 44, height: 44, alignment: .bottomLeading)
            }
        }
        .frame(width: 44, height: 44)
    }
}

