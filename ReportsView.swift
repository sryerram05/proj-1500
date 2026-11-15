import SwiftUI
import Charts


struct ReportsView: View {
    let allQuestions: [Question]
    let answers: [String: AnswerRecord]
    let dailyActivity: [String: Int]
   
    let onReviewQuestion: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    private var questionsByID: [String: Question] {
        Dictionary(uniqueKeysWithValues: allQuestions.map { ($0.id, $0) })
    }

    private var totalAttempted: Int { answers.count }
    private var totalCorrect: Int { answers.values.filter(\.isCorrect).count }
    private var overallAccuracy: Double {
        totalAttempted == 0 ? 0 : Double(totalCorrect) / Double(totalAttempted)
    }

  
    private var skillStats: [SkillPerformance] {
        var stats: [String: SkillPerformance] = [:]
        for (topic, skills) in ReadingPracticeView.skillsByTopic {
            for skill in skills {
                stats[skill] = SkillPerformance(skill: skill, topic: topic, attempted: 0, correct: 0)
            }
        }
        for (id, record) in answers {
            guard let q = questionsByID[id] else { continue }
            stats[q.skill, default: SkillPerformance(skill: q.skill, topic: q.topic, attempted: 0, correct: 0)].attempted += 1
            if record.isCorrect {
                stats[q.skill]?.correct += 1
            }
        }
        return stats.values.sorted { $0.skill < $1.skill }
    }

    private var attemptedSkillStats: [SkillPerformance] {
        skillStats.filter { $0.attempted > 0 }.sorted { $0.accuracy < $1.accuracy }
    }


    private var weakestSkill: SkillPerformance? {
        attemptedSkillStats.first(where: { $0.attempted >= 3 }) ?? attemptedSkillStats.first
    }

    private var difficultyStats: [DifficultyPerformance] {
        ReadingPracticeView.difficultyLevels.map { level in
            let ids = questionsByID.values.filter { $0.difficulty == level }.map(\.id)
            let attempted = ids.filter { answers[$0] != nil }
            let correct = attempted.filter { answers[$0]?.isCorrect == true }
            return DifficultyPerformance(level: level, attempted: attempted.count, correct: correct.count)
        }
    }

    private var recentMisses: [(question: Question, record: AnswerRecord)] {
        answers.compactMap { id, record -> (Question, AnswerRecord)? in
            guard let q = questionsByID[id], !record.isCorrect else { return nil }
            return (q, record)
        }
        .sorted { $0.1.answeredAt > $1.1.answeredAt }
        .prefix(12)
        .map { ($0.0, $0.1) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ActivityHeatmapSection(dailyActivity: dailyActivity)

                    Divider()

                    overallSummary

                    if let weakestSkill {
                        insightCard(for: weakestSkill)
                    }

                    if !attemptedSkillStats.isEmpty {
                        skillChartSection
                    }

                    difficultySection

                    if !recentMisses.isEmpty {
                        recentMissesSection
                    }

                    if totalAttempted == 0 {
                        emptyState
                    }
                }
                .padding()
            }
            .navigationTitle("Your Reports")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }



    private var overallSummary: some View {
        HStack(spacing: 12) {
            statCard(value: "\(totalAttempted)", label: "Answered")
            statCard(value: "\(totalCorrect)", label: "Correct")
            statCard(
                value: totalAttempted == 0 ? "—" : "\(Int((overallAccuracy * 100).rounded()))%",
                label: "Accuracy"
            )
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }

    private func insightCard(for skill: SkillPerformance) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundColor(.purple)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text("Focus area: \(Question.shortSkillLabel(for: skill.skill))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text("You're getting \(Int((skill.accuracy * 100).rounded()))% right on \(skill.skill) (\(skill.correct) of \(skill.attempted)). This is your weakest tracked area — worth extra practice.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.purple.opacity(0.25), lineWidth: 1)
        )
        .cornerRadius(10)
    }

    private var skillChartSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Accuracy by Skill")
                .font(.headline)

            Chart(attemptedSkillStats) { stat in
                BarMark(
                    x: .value("Accuracy", stat.accuracy),
                    y: .value("Skill", Question.shortSkillLabel(for: stat.skill))
                )
                .foregroundStyle(barColor(for: stat.accuracy))
                .annotation(position: .trailing) {
                    Text("\(Int((stat.accuracy * 100).rounded()))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .chartXScale(domain: 0...1)
            .chartXAxis(.hidden)
            .frame(height: CGFloat(attemptedSkillStats.count) * 32 + 20)
        }
    }

    private func barColor(for accuracy: Double) -> Color {
        if accuracy < 0.6 { return .red }
        if accuracy < 0.8 { return .orange }
        return .green
    }

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Accuracy by Difficulty")
                .font(.headline)

            ForEach(difficultyStats) { stat in
                HStack {
                    Text(stat.level)
                        .font(.subheadline)
                        .frame(width: 70, alignment: .leading)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.15))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(barColor(for: stat.accuracy))
                                .frame(width: geo.size.width * stat.accuracy)
                        }
                    }
                    .frame(height: 10)

                    Text(stat.attempted == 0 ? "—" : "\(stat.correct)/\(stat.attempted)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 46, alignment: .trailing)
                }
            }
        }
    }

    private var recentMissesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Misses")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(recentMisses, id: \.question.id) { item in
                    Button {
                        onReviewQuestion(item.question.id)
                        dismiss()
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .padding(.top, 2)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(Question.shortSkillLabel(for: item.question.skill))
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                Text(item.question.question ?? item.question.prompt)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Image(systemName: "arrow.uturn.backward.circle")
                                .foregroundColor(.secondary)
                        }
                        .padding(10)
                        .background(Color.red.opacity(0.05))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No questions answered yet")
                .font(.subheadline)
                .fontWeight(.semibold)
            Text("Answer a few questions and come back — this is where you'll see which skills need the most work.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }
}



private struct SkillPerformance: Identifiable {
    let skill: String
    let topic: String
    var attempted: Int
    var correct: Int
    var id: String { skill }
    var accuracy: Double { attempted == 0 ? 0 : Double(correct) / Double(attempted) }
}

private struct DifficultyPerformance: Identifiable {
    let level: String
    let attempted: Int
    let correct: Int
    var id: String { level }
    var accuracy: Double { attempted == 0 ? 0 : Double(correct) / Double(attempted) }
}

