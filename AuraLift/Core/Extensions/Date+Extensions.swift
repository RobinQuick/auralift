import Foundation

extension Date {
    /// Returns a short date string (e.g., "Jan 15, 2025")
    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// Returns a time string (e.g., "3:45 PM")
    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// Returns a relative time string (e.g., "2 hours ago")
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Returns duration string between two dates (e.g., "1h 23m")
    func durationString(to end: Date) -> String {
        let interval = end.timeIntervalSince(self)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    /// Start of the current day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Start of the current week
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    /// Days since a given date
    func daysSince(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: date.startOfDay, to: self.startOfDay).day ?? 0
    }
}
