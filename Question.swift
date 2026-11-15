import Foundation

struct Question: Identifiable, Codable {
    let id: String
    let prompt: String
    let options: [String]
    let correctAnswerIndex: Int
    let explanation: String
    let domain: String
    let difficulty: String
    let chartImageName: String?
    let topic: String
    let skill: String

    let blurb: String?

    let passage: String
    let passage2: String?
    let question: String?
    let vocabWord: String?
    let underlinedText: [String]?
    let bank: String
}


extension Question {
    var shortSkillLabel: String { Question.shortSkillLabel(for: skill) }


    static func shortSkillLabel(for skill: String) -> String {
        switch skill {
        case "Words in Context": return "Vocab"
        case "Central Ideas and Details": return "Main Idea"
        case "Text Structure and Purpose": return "Main Purpose"
        case "Inferences": return "Inference"
        case "Command of Evidence": return "Evidence"
        case "Cross-Text Connections": return "Cross-Text"
        case "Rhetorical Synthesis": return "Synthesis"
        case "Transitions": return "Transitions"
        case "Boundaries": return "Punctuation"
        case "Form, Structure, and Sense": return "Grammar"
        default: return skill
        }
    }
}

