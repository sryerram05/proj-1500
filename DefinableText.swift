import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif


struct DefinableText: View {
    let text: String
    var font: Font = .body
    var textColor: Color = .primary
    var isStrikethrough: Bool = false

    @State private var dictionaryTerm: DefinableDictionaryTerm? = nil

    private var words: [String] {
        text.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
    }

    private func normalize(_ s: String) -> String {
        s.lowercased().trimmingCharacters(in: CharacterSet.punctuationCharacters.union(.whitespaces))
    }

    var body: some View {
        FlowLayout(spacing: 4) {
            ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                Text(word)
                    .font(font)
                    .foregroundColor(textColor)
                    .strikethrough(isStrikethrough, color: .secondary)
                    .contextMenu {
                        Button {
                            lookUpDefinition(for: word)
                        } label: {
                            Label("Look Up \u{201C}\(normalize(word))\u{201D}", systemImage: "character.book.closed")
                        }
                    }
            }
        }
        .sheet(item: $dictionaryTerm) { term in
            #if os(iOS)
            DefinableDictionaryLookupView(term: term.term)
            #else
            EmptyView()
            #endif
        }
    }

    private func lookUpDefinition(for word: String) {
        let cleaned = normalize(word)
        guard !cleaned.isEmpty else { return }
        #if os(iOS)
        dictionaryTerm = DefinableDictionaryTerm(term: cleaned)
        #elseif os(macOS)
        let encoded = cleaned.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? cleaned
        if let url = URL(string: "dict:///\(encoded)") {
            NSWorkspace.shared.open(url)
        }
        #endif
    }
}

private struct DefinableDictionaryTerm: Identifiable {
    let term: String
    var id: String { term }
}

#if os(iOS)
private struct DefinableDictionaryLookupView: UIViewControllerRepresentable {
    let term: String

    func makeUIViewController(context: Context) -> UIReferenceLibraryViewController {
        UIReferenceLibraryViewController(term: term)
    }

    func updateUIViewController(_ uiViewController: UIReferenceLibraryViewController, context: Context) {}
}
#endif
