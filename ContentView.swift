import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ReadingPracticeView()
        }
    }
}


struct ReadingPracticeView: View {

    @ObservedObject private var progress = ProgressStore.shared

 
    @State private var allQuestions: [Question] = []
    @State private var currentIndex: Int = 0
    @State private var selectedOptionIndex: Int? = nil
    @State private var isSubmitted: Bool = false
    @State private var isHighlightModeOn: Bool = false
    @State private var isEliminatorModeOn: Bool = false
    @State private var showSelector: Bool = false
    @State private var selectedDifficulties: Set<String> = [] // empty = all difficulties
    @State private var selectedSkills: Set<String> = [] // empty = all concepts/skills
    @State private var selectedBanks: Set<String> = [] // empty = all question banks
    @State private var showResetConfirmation: Bool = false
    @State private var showReports: Bool = false
    @State private var showConceptSelector: Bool = false
    @State private var showDifficultySelector: Bool = false
    @State private var showBankSelector: Bool = false

    static let difficultyLevels = ["Easy", "Medium", "Hard"]
    // SAT's 4 official Reading & Writing content domains, in the order
    // College Board lists them
    static let topics = [
        "Information and Ideas",
        "Craft and Structure",
        "Expression of Ideas",
        "Standard English Conventions"
    ]

    static let skillsByTopic: [String: [String]] = [
        "Information and Ideas": ["Central Ideas and Details", "Command of Evidence", "Inferences"],
        "Craft and Structure": ["Words in Context", "Text Structure and Purpose", "Cross-Text Connections"],
        "Expression of Ideas": ["Rhetorical Synthesis", "Transitions"],
        "Standard English Conventions": ["Boundaries", "Form, Structure, and Sense"]
    ]


    var availableBanks: [String] {
        Array(Set(allQuestions.map(\.bank))).sorted()
    }


    var filteredQuestions: [Question] {
        allQuestions.filter { question in
            (selectedDifficulties.isEmpty || selectedDifficulties.contains(question.difficulty)) &&
            (selectedSkills.isEmpty || selectedSkills.contains(question.skill)) &&
            (selectedBanks.isEmpty || selectedBanks.contains(question.bank))
        }
    }

    var currentQuestion: Question? {
        guard !filteredQuestions.isEmpty && currentIndex < filteredQuestions.count else { return nil }
        return filteredQuestions[currentIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            if let question = currentQuestion {
             
                HStack {
                    DifficultyBadge(difficulty: question.difficulty)

                    Text(question.topic)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.gray.opacity(0.12))
                        .cornerRadius(8)
                        .lineLimit(1)

                    if let record = progress.answers[question.id] {
                        Label(
                            record.isCorrect ? "Answered · Correct" : "Answered · Incorrect",
                            systemImage: record.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill"
                        )
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(record.isCorrect ? .green : .red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background((record.isCorrect ? Color.green : Color.red).opacity(0.12))
                        .cornerRadius(8)
                        .lineLimit(1)
                        .fixedSize()
                    }

                    Button {
                        progress.toggleMarkedForReview(question.id)
                    } label: {
                        Image(systemName: progress.markedForReview.contains(question.id) ? "flag.fill" : "flag")
                    }
                    .foregroundColor(progress.markedForReview.contains(question.id) ? .orange : .secondary)
                    .help("Mark for review")

                    Spacer()

                    QuestionTimerView(isPaused: isSubmitted)
                        .id(question.id) // fresh timer per question
                }
                .padding(.horizontal)
                .padding(.top, 12)

                AdaptiveQuestionLayout(
                    question: question,
                    selectedOptionIndex: $selectedOptionIndex,
                    isSubmitted: $isSubmitted,
                    isHighlightModeOn: $isHighlightModeOn,
                    isEliminatorModeOn: isEliminatorModeOn
                )
                .id(question.id) // resets highlights when the question changes
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                bottomBar(for: question)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "tray.fill")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No questions found")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: 900, alignment: .top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("Reading & Writing")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if availableBanks.count > 1 {
                    Button {
                        showBankSelector = true
                    } label: {
                        Image(systemName: "square.stack.3d.up")
                    }
                    .help("Choose which question bank(s) to practice from")
                }

                Button {
                    showDifficultySelector = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .help("Choose which difficulties to practice — pick more than one")

                Button {
                    showConceptSelector = true
                } label: {
                    Image(systemName: "tag")
                }
                .help("Choose which concepts to practice — pick more than one, like Main Purpose and Main Idea together")

                Button {
                    showReports = true
                } label: {
                    Image(systemName: "chart.bar.doc.horizontal")
                }
                .help("Your reports — accuracy by skill, weak areas, recent misses")

                Button {
                    isHighlightModeOn.toggle()
                } label: {
                    Image(systemName: "highlighter")
                }
                .foregroundColor(isHighlightModeOn ? .yellow : .primary)
                .help("Toggle highlighter")

                Button {
                    isEliminatorModeOn.toggle()
                } label: {
                    Image(systemName: "circle.slash")
                }
                .foregroundColor(isEliminatorModeOn ? .red : .primary)
                .help("Toggle Answer Eliminator")

                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .help("Reset saved progress")
            }
        }
        .sheet(isPresented: $showSelector) {
            QuestionSelectorSheet(
                questions: filteredQuestions,
                currentIndex: currentIndex,
                markedForReview: progress.markedForReview,
                answers: progress.answers
            ) { newIndex in
                currentIndex = newIndex
                loadSavedState(for: filteredQuestions[newIndex])
            }
        }
        .sheet(isPresented: $showReports) {
            ReportsView(
                allQuestions: allQuestions,
                answers: progress.answers,
                dailyActivity: progress.dailyActivity,
                onReviewQuestion: reviewQuestion
            )
        }
        .sheet(isPresented: $showConceptSelector) {
            ConceptSelectorSheet(selectedSkills: $selectedSkills)
        }
        .sheet(isPresented: $showDifficultySelector) {
            DifficultySelectorSheet(selectedDifficulties: $selectedDifficulties)
        }
        .sheet(isPresented: $showBankSelector) {
            BankSelectorSheet(availableBanks: availableBanks, selectedBanks: $selectedBanks)
        }
        .confirmationDialog(
            "Reset all saved progress?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset Progress", role: .destructive) {
                progress.resetAll()
                selectedOptionIndex = nil
                isSubmitted = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears every answer you've saved and all review flags. This can't be undone.")
        }
        .onAppear {
            allQuestions = QuestionLoader.loadQuestions()
            if let question = currentQuestion {
                loadSavedState(for: question)
            }
        }
        .onChange(of: selectedDifficulties) { oldValue, newValue in
            currentIndex = 0
            if let question = currentQuestion {
                loadSavedState(for: question)
            }
        }
        .onChange(of: selectedSkills) { oldValue, newValue in
            currentIndex = 0
            if let question = currentQuestion {
                loadSavedState(for: question)
            }
        }
        .onChange(of: selectedBanks) { oldValue, newValue in
            currentIndex = 0
            if let question = currentQuestion {
                loadSavedState(for: question)
            }
        }
    }

    private func loadSavedState(for question: Question) {
        if let record = progress.answers[question.id] {
            selectedOptionIndex = record.selectedOptionIndex
            isSubmitted = true
        } else {
            selectedOptionIndex = nil
            isSubmitted = false
        }
    }
    private func bottomBar(for question: Question) -> some View {
        HStack {
            Button(action: previousQuestion) {
                Label("Back", systemImage: "chevron.left")
                    .labelStyle(.titleAndIcon)
            }
            .disabled(currentIndex == 0)
            .tint(.white)

            Spacer()

            Button {
                showSelector = true
            } label: {
                VStack(spacing: 2) {
                    Text("Question \(currentIndex + 1) of \(filteredQuestions.count)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.caption2)
                }
            }
            .tint(.white)

            Spacer()

            if !isSubmitted {
                Button {
                    withAnimation { isSubmitted = true }
                    if let selectedOptionIndex {
                        progress.record(
                            questionID: question.id,
                            selectedOptionIndex: selectedOptionIndex,
                            isCorrect: selectedOptionIndex == question.correctAnswerIndex
                        )
                    }
                } label: {
                    Text("Check Answer")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(selectedOptionIndex != nil ? Color.blue : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(selectedOptionIndex == nil)
                .buttonStyle(.plain)
            } else {
                // Lets you redo an already-graded question. Your previous answer stays recorded until you check a new one — so re-answering still updates whether it counts as correct.
                Button {
                    withAnimation {
                        selectedOptionIndex = nil
                        isSubmitted = false
                    }
                } label: {
                    Text("Try Again")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.15))
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                        )
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button(action: nextQuestion) {
                    Text(currentIndex < filteredQuestions.count - 1 ? "Next" : "Start Over")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .foregroundColor(.white)
        .background(Color.black)
    }

    private func previousQuestion() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        loadSavedState(for: filteredQuestions[currentIndex])
    }

    private func nextQuestion() {
        if currentIndex < filteredQuestions.count - 1 {
            currentIndex += 1
        } else {
            currentIndex = 0
        }
        loadSavedState(for: filteredQuestions[currentIndex])
    }


    private func reviewQuestion(id: String) {
        selectedDifficulties = []
        selectedSkills = []
        selectedBanks = []
        guard let index = allQuestions.firstIndex(where: { $0.id == id }) else { return }
        currentIndex = index
        loadSavedState(for: allQuestions[index])
    }
}


struct AdaptiveQuestionLayout: View {
    let question: Question
    @Binding var selectedOptionIndex: Int?
    @Binding var isSubmitted: Bool
    @Binding var isHighlightModeOn: Bool
    let isEliminatorModeOn: Bool

    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        Group {
            if sizeClass == .regular {

                HStack(alignment: .top, spacing: 0) {
                    ScrollView {
                        promptView
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                    Divider()

                    ScrollView {
                        OptionsList(question: question, selectedIndex: $selectedOptionIndex, isSubmitted: isSubmitted, isEliminatorModeOn: isEliminatorModeOn)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            } else {
        
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        promptView

                        OptionsList(question: question, selectedIndex: $selectedOptionIndex, isSubmitted: isSubmitted, isEliminatorModeOn: isEliminatorModeOn)
                    }
                    .padding()
                }
            }
        }
    }

    @ViewBuilder
    private var promptView: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let chartImageName = question.chartImageName {
                ChartImageView(imageName: chartImageName)
            }

    
            if let blurb = question.blurb {
                Text(blurb)
                    .font(.subheadline)
                    .italic()
                    .foregroundColor(.secondary)
            }

            if let passage2 = question.passage2 {

                DualPassageBlock(label: "Text 1", text: question.passage, isHighlightModeOn: $isHighlightModeOn, underlinedText: question.underlinedText)
                DualPassageBlock(label: "Text 2", text: passage2, isHighlightModeOn: $isHighlightModeOn, underlinedText: question.underlinedText)
            } else {
                HighlightableText(text: question.passage, isHighlightModeOn: $isHighlightModeOn, vocabWord: question.vocabWord, underlinedText: question.underlinedText)
            }


            if let questionText = question.question {
                QuestionPromptBox(text: questionText, skillLabel: question.shortSkillLabel)
            }


            if isSubmitted && !question.explanation.isEmpty {
                ExplanationBox(text: question.explanation)
            }
        }
    }
}


private struct ExplanationBox: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Explanation")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }

            Text(text)
                .font(.callout)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.yellow.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(10)
    }
}


private struct DualPassageBlock: View {
    let label: String
    let text: String
    @Binding var isHighlightModeOn: Bool
    var underlinedText: [String]? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.purple)
                .cornerRadius(6)

            HighlightableText(text: text, isHighlightModeOn: $isHighlightModeOn, underlinedText: underlinedText)
        }
        .padding(12)
        .background(Color.purple.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.purple.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(10)
    }
}


private struct QuestionPromptBox: View {
    let text: String
    let skillLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(skillLabel.uppercased())
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.blue.opacity(0.15))
                .cornerRadius(6)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)

                Text(text)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.blue.opacity(0.25), lineWidth: 1)
        )
        .cornerRadius(10)
    }
}


struct OptionsList: View {
    let question: Question
    @Binding var selectedIndex: Int?
    let isSubmitted: Bool
    let isEliminatorModeOn: Bool


    @State private var eliminatedIndices: Set<Int> = []

    private let letters = ["A", "B", "C", "D"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(0..<question.options.count, id: \.self) { index in
                let isEliminated = eliminatedIndices.contains(index)

                HStack(spacing: 10) {
                    Button {
                        guard !isSubmitted, !isEliminated else { return }
                        selectedIndex = index
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(badgeFillColor(for: index))
                                    .overlay(
                                        Circle().strokeBorder(badgeBorderColor(for: index), lineWidth: 2)
                                    )
                                    .frame(width: 32, height: 32)

                                if isSubmitted && index == question.correctAnswerIndex {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                } else if isSubmitted && selectedIndex == index {
                                    Image(systemName: "xmark")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                } else {
                                    Text(letters[index])
                                        .font(.subheadline.bold())
                                        .foregroundColor(badgeTextColor(for: index))
                                }
                            }

                            DefinableText(
                                text: question.options[index],
                                textColor: isEliminated ? .secondary : .primary,
                                isStrikethrough: isEliminated
                            )

                            Spacer(minLength: 0)
                        }
                    }
                    .buttonStyle(.plain)
                    .opacity(isEliminated ? 0.55 : 1)

                    if isEliminatorModeOn && !isSubmitted {
                        Button {
                            toggleEliminated(index)
                        } label: {
                            Image(systemName: isEliminated ? "arrow.uturn.backward.circle" : "circle.slash")
                                .font(.title3)
                                .foregroundColor(isEliminated ? .blue : .secondary)
                        }
                        .buttonStyle(.plain)
                        .help(isEliminated ? "Restore this choice" : "Cross out this choice")
                    }
                }
                .padding(12)
                .background(rowBackground(for: index))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(cardBorderColor(for: index), lineWidth: cardBorderWidth(for: index))
                )
                .cornerRadius(10)
            }
        }
    }

    private func toggleEliminated(_ index: Int) {
        if eliminatedIndices.contains(index) {
            eliminatedIndices.remove(index)
        } else {
            eliminatedIndices.insert(index)
            if selectedIndex == index {
                selectedIndex = nil
            }
        }
    }

    private func badgeFillColor(for index: Int) -> Color {
        if isSubmitted {
            if index == question.correctAnswerIndex { return .green }
            if selectedIndex == index { return .red }
            return .clear
        }
        return selectedIndex == index ? .blue : .clear
    }

    private func badgeBorderColor(for index: Int) -> Color {
        if isSubmitted {
            if index == question.correctAnswerIndex { return .green }
            if selectedIndex == index { return .red }
            return Color.gray.opacity(0.4)
        }
        return selectedIndex == index ? .blue : Color.gray.opacity(0.4)
    }

    private func badgeTextColor(for index: Int) -> Color {
        if !isSubmitted && selectedIndex == index { return .white }
        return .primary
    }

    private func cardBorderColor(for index: Int) -> Color {
        if isSubmitted {
            if index == question.correctAnswerIndex { return .green }
            if selectedIndex == index { return .red }
            return Color.gray.opacity(0.25)
        }
        return selectedIndex == index ? .blue : Color.gray.opacity(0.25)
    }

    private func cardBorderWidth(for index: Int) -> CGFloat {
        if isSubmitted {
            return (index == question.correctAnswerIndex || selectedIndex == index) ? 2 : 1
        }
        return selectedIndex == index ? 2 : 1
    }

    private func rowBackground(for index: Int) -> Color {
        if isSubmitted {
            if index == question.correctAnswerIndex { return Color.green.opacity(0.08) }
            if selectedIndex == index { return Color.red.opacity(0.08) }
            return .clear
        }
        return selectedIndex == index ? Color.blue.opacity(0.06) : .clear
    }
}

struct DifficultyBadge: View {
    let difficulty: String

    var color: Color {
        switch difficulty.lowercased() {
        case "easy": return .green
        case "medium": return .orange
        case "hard": return .red
        default: return .gray
        }
    }

    var iconName: String {
        switch difficulty.lowercased() {
        case "easy": return "gauge.with.dots.needle.33percent"
        case "medium": return "gauge.with.dots.needle.67percent"
        case "hard": return "gauge.with.dots.needle.100percent"
        default: return "circle"
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: iconName)
                .font(.caption2)
            Text(difficulty.capitalized)
                .font(.caption)
                .fontWeight(.bold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(8)
    }
}

