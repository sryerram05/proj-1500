import SwiftUI


struct ActivityHeatmapSection: View {

    let dailyActivity: [String: Int]

    private let calendar = Calendar.current

    private struct Day {
        let date: Date
        let count: Int
    }

    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    private static let fullDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        return f
    }()

 
    private var currentWeekDays: [Day] {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today) // 1 = Sunday
        guard let sunday = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) else { return [] }
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: sunday) else { return nil }
            return Day(date: date, count: dailyActivity[ProgressStore.dayKey(for: date)] ?? 0)
        }
    }

    private var totalThisWeek: Int {
        currentWeekDays.reduce(0) { $0 + $1.count }
    }


    private var currentStreak: Int {
        var day = calendar.startOfDay(for: Date())
        if (dailyActivity[ProgressStore.dayKey(for: day)] ?? 0) == 0 {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var streak = 0
        while (dailyActivity[ProgressStore.dayKey(for: day)] ?? 0) > 0 {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    private var longestStreak: Int {
        let dates = dailyActivity.keys.compactMap { ProgressStore.dayKeyFormatter.date(from: $0) }.sorted()
        guard !dates.isEmpty else { return 0 }
        var longest = 1
        var current = 1
        for i in 1..<dates.count {
            let gap = calendar.dateComponents([.day], from: dates[i - 1], to: dates[i]).day ?? 0
            if gap == 1 {
                current += 1
                longest = max(longest, current)
            } else if gap > 1 {
                current = 1
            }
        }
        return longest
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("This Week")
                .font(.headline)

            HStack(spacing: 20) {
                stat(value: totalThisWeek, label: "this week")
                stat(value: currentStreak, label: "day streak")
                stat(value: longestStreak, label: "longest streak")
            }

            HStack(spacing: 8) {
                ForEach(currentWeekDays, id: \.date) { day in
                    dayCell(day)
                }
            }

            legend
        }
    }

    private func dayCell(_ day: Day) -> some View {
        let isToday = calendar.isDateInToday(day.date)
        return VStack(spacing: 4) {
            Text(Self.weekdayFormatter.string(from: day.date))
                .font(.caption2)
                .foregroundColor(.secondary)

            RoundedRectangle(cornerRadius: 6)
                .fill(color(for: day.count))
                .frame(height: 34)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(isToday ? Color.blue : Color.clear, lineWidth: 2)
                )

            Text("\(calendar.component(.day, from: day.date))")
                .font(.caption2)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(isToday ? .blue : .secondary)
        }
        .frame(maxWidth: .infinity)
        .help("\(Self.fullDateFormatter.string(from: day.date)) — \(day.count) question\(day.count == 1 ? "" : "s")")
    }

    private func stat(value: Int, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var legend: some View {
        HStack(spacing: 4) {
            Text("Less")
                .font(.caption2)
                .foregroundColor(.secondary)
            ForEach([0, 2, 5, 9, 15], id: \.self) { level in
                RoundedRectangle(cornerRadius: 3)
                    .fill(color(for: level))
                    .frame(width: 14, height: 14)
            }
            Text("More")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func color(for count: Int) -> Color {
        switch count {
        case 0: return Color.gray.opacity(0.12)
        case 1...2: return Color.green.opacity(0.35)
        case 3...5: return Color.green.opacity(0.6)
        case 6...9: return Color.green.opacity(0.8)
        default: return Color.green
        }
    }
}

