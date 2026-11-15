import Foundation

enum QuestionLoader {
    private static let bankFiles = ["questions", "questions2"]


    static func loadQuestions() -> [Question] {
        var all: [Question] = []
        for file in bankFiles {
            guard let url = Bundle.main.url(forResource: file, withExtension: "json") else {
                print("QuestionLoader: could not find \(file).json in the app bundle.")
                continue
            }
            do {
                let data = try Data(contentsOf: url)
                let questions = try JSONDecoder().decode([Question].self, from: data)
                all.append(contentsOf: questions)
            } catch {
                print("QuestionLoader: failed to decode \(file).json — \(error)")
            }
        }
        return all
    }
}

