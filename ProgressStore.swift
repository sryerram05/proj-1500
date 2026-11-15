import Foundation
import Combine


struct AnswerRecord: Codable {
    let selectedOptionIndex: Int
    let isCorrect: Bool
    let answeredAt: Date
}

final class ProgressStore: ObservableObject {
    static let shared = ProgressStore()

    @Published private(set) var answers: [String: AnswerRecord] = [:]
    @Published private(set) var markedForReview: Set<String> = []

    @Published private(set) var dailyActivity: [String: Int] = [:]

    private let answersKey = "SATProgress.answers.v1"
    private let markedKey = "SATProgress.markedForReview.v1"
    private let dailyActivityKey = "SATProgress.dailyActivity.v1"
    private let defaults = UserDefaults.standard

    private init() {
        load()
    }

    var answeredCount: Int { answers.count }
    var correctCount: Int { answers.values.filter(\.isCorrect).count }


    static let dayKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    static func dayKey(for date: Date) -> String {
        dayKeyFormatter.string(from: date)
    }

    func record(questionID: String, selectedOptionIndex: Int, isCorrect: Bool) {
        answers[questionID] = AnswerRecord(
            selectedOptionIndex: selectedOptionIndex,
            isCorrect: isCorrect,
            answeredAt: Date()
        )
        let today = Self.dayKey(for: Date())
        dailyActivity[today, default: 0] += 1
        save()
    }

    func toggleMarkedForReview(_ questionID: String) {
        if markedForReview.contains(questionID) {
            markedForReview.remove(questionID)
        } else {
            markedForReview.insert(questionID)
        }
        save()
    }


    func resetAll() {
        answers = [:]
        markedForReview = []
        dailyActivity = [:]
        save()
    }

    private func load() {
        if let data = defaults.data(forKey: answersKey),
           let decoded = try? JSONDecoder().decode([String: AnswerRecord].self, from: data) {
            answers = decoded
        }
        if let data = defaults.data(forKey: markedKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            markedForReview = decoded
        }
        if let data = defaults.data(forKey: dailyActivityKey),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            dailyActivity = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(answers) {
            defaults.set(data, forKey: answersKey)
        }
        if let data = try? JSONEncoder().encode(markedForReview) {
            defaults.set(data, forKey: markedKey)
        }
        if let data = try? JSONEncoder().encode(dailyActivity) {
            defaults.set(data, forKey: dailyActivityKey)
        }
    }
}

