import SwiftUI
import Combine

struct QuestionTimerView: View {
    let isPaused: Bool

    @State private var elapsed: TimeInterval = 0
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "timer")
                .font(.headline)
            Text(formatted)
                .font(.title3)
                .fontWeight(.bold)
                .monospacedDigit()
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(isPaused ? Color.gray : Color.blue)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
        .onReceive(ticker) { _ in
            guard !isPaused else { return }
            elapsed += 1
        }
    }

    private var formatted: String {
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
