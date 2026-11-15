import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Flow Layout
// A simple wrapping layout (like text wrapping) so tappable "words" flow onto
// multiple lines instead of overflowing. Requires iOS 16 / macOS 13+.
struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth && rowWidth > 0 {
                totalHeight += rowHeight + spacing
                totalWidth = max(totalWidth, rowWidth)
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        totalWidth = max(totalWidth, rowWidth)
        return CGSize(width: maxWidth.isFinite ? maxWidth : totalWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

private struct WordFramePreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

private let highlightCoordinateSpace = "highlightCoordinateSpace"

struct HighlightableText: View {
    let text: String
    @Binding var isHighlightModeOn: Bool
    var font: Font = .title3

    var vocabWord: String? = nil

    var underlinedText: [String]? = nil

    @State private var highlightedIndices: Set<Int> = []
    @State private var wordFrames: [Int: CGRect] = [:]
    @State private var isDragging = false
    @State private var dragIsAdding = true
    @State private var lastTouchedIndex: Int? = nil
    @State private var dictionaryTerm: DictionaryTerm? = nil

    private var words: [String] {
        text.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
    }

    private func normalize(_ s: String) -> String {
        s.lowercased().trimmingCharacters(in: CharacterSet.punctuationCharacters.union(.whitespaces))
    }

    private func matchIndices(for phrase: String) -> Set<Int> {
        let target = phrase.split(separator: " ").map { normalize(String($0)) }.filter { !$0.isEmpty }
        guard !target.isEmpty else { return [] }
        let normalizedWords = words.map(normalize)
        guard normalizedWords.count >= target.count else { return [] }
        for start in 0...(normalizedWords.count - target.count) {
            if Array(normalizedWords[start..<(start + target.count)]) == target {
                return Set(start..<(start + target.count))
            }
        }
        return []
    }

    private var vocabIndices: Set<Int> {
        guard let vocabWord, !vocabWord.isEmpty else { return [] }
        return matchIndices(for: vocabWord)
    }

    private var underlineTextIndices: Set<Int> {
        guard let underlinedText else { return [] }
        return underlinedText.reduce(into: Set<Int>()) { result, phrase in
            result.formUnion(matchIndices(for: phrase))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            FlowLayout(spacing: 4) {
                ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                    Text(word)
                        .font(font)
                        .fontWeight(vocabIndices.contains(index) ? .semibold : .regular)
                        .underline(
                            vocabIndices.contains(index) || underlineTextIndices.contains(index),
                            color: vocabIndices.contains(index) ? .blue : .primary
                        )
                        .foregroundColor(vocabIndices.contains(index) ? .blue : .primary)
                        .padding(.horizontal, 2)
                        .padding(.vertical, 1)
                        .background(
                            highlightedIndices.contains(index)
                                ? Color.yellow.opacity(0.6)
                                : Color.clear
                        )
                        .cornerRadius(3)
                        .background(
                            GeometryReader { proxy in
                                Color.clear
                                    .preference(
                                        key: WordFramePreferenceKey.self,
                                        value: [index: proxy.frame(in: .named(highlightCoordinateSpace))]
                                    )
                            }
                        )
                        .contextMenu {
                            Button {
                                lookUpDefinition(for: word)
                            } label: {
                                Label("Look Up \u{201C}\(normalize(word))\u{201D}", systemImage: "character.book.closed")
                            }
                        }
                }
            }
            .coordinateSpace(name: highlightCoordinateSpace)
            .onPreferenceChange(WordFramePreferenceKey.self) { frames in
                wordFrames = frames
            }
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named(highlightCoordinateSpace))
                    .onChanged(handleDragChanged)
                    .onEnded { _ in
                        isDragging = false
                        lastTouchedIndex = nil
                    },
                including: isHighlightModeOn ? .all : .subviews
            )

            if isHighlightModeOn {
                HStack(spacing: 8) {
                    Image(systemName: "highlighter")
                        .font(.caption)
                    Text("Highlighter on — drag across words to mark them")
                        .font(.caption)
                    Spacer()
                    if !highlightedIndices.isEmpty {
                        Button("Clear") {
                            highlightedIndices.removeAll()
                        }
                        .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
            }
        }
        .sheet(item: $dictionaryTerm) { term in
            #if os(iOS)
            DictionaryLookupView(term: term.term)
            #else
            EmptyView()
            #endif
        }
    }

    private func lookUpDefinition(for word: String) {
        let cleaned = normalize(word)
        guard !cleaned.isEmpty else { return }
        #if os(iOS)
        dictionaryTerm = DictionaryTerm(term: cleaned)
        #elseif os(macOS)
        let encoded = cleaned.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? cleaned
        if let url = URL(string: "dict:///\(encoded)") {
            NSWorkspace.shared.open(url)
        }
        #endif
    }

    private func handleDragChanged(_ value: DragGesture.Value) {
        guard isHighlightModeOn else { return }
        guard let index = wordFrames.first(where: { $0.value.contains(value.location) })?.key else { return }

        if !isDragging {
            dragIsAdding = !highlightedIndices.contains(index)
            isDragging = true
        }

        guard lastTouchedIndex != index else { return }
        lastTouchedIndex = index

        if dragIsAdding {
            highlightedIndices.insert(index)
        } else {
            highlightedIndices.remove(index)
        }
    }
}

private struct DictionaryTerm: Identifiable {
    let term: String
    var id: String { term }
}

#if os(iOS)
private struct DictionaryLookupView: UIViewControllerRepresentable {
    let term: String

    func makeUIViewController(context: Context) -> UIReferenceLibraryViewController {
        UIReferenceLibraryViewController(term: term)
    }

    func updateUIViewController(_ uiViewController: UIReferenceLibraryViewController, context: Context) {}
}
#endif

