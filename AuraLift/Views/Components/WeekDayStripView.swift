import SwiftUI

// MARK: - WeekDayStripView

/// Horizontal Mon-Sun strip showing day status dots for the current program week.
struct WeekDayStripView: View {
    let days: [ProgramDay]
    let todayIndex: Int?

    private let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        HStack(spacing: AuraTheme.Spacing.xs) {
            ForEach(0..<7, id: \.self) { idx in
                dayColumn(for: idx)
            }
        }
        .padding(.horizontal, AuraTheme.Spacing.md)
        .padding(.vertical, AuraTheme.Spacing.sm)
        .background(Color.auraSurfaceElevated)
        .cornerRadius(AuraTheme.Radius.medium)
    }

    // MARK: - Day Column

    private func dayColumn(for index: Int) -> some View {
        let day = days.count > index ? days[index] : nil
        let isToday = todayIndex == index

        return VStack(spacing: AuraTheme.Spacing.xxs) {
            Text(dayLabels[index])
                .font(.system(size: 10, weight: isToday ? .bold : .regular, design: .monospaced))
                .foregroundColor(isToday ? .neonBlue : .auraTextSecondary)

            Circle()
                .fill(dotColor(day: day, isToday: isToday))
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(isToday ? Color.neonBlue : Color.clear, lineWidth: 1.5)
                        .frame(width: 14, height: 14)
                )

            if let day, !day.isRestDay {
                Text(day.dayLabel.prefix(4))
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(isToday ? .auraTextPrimary : .auraTextDisabled)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(dayLabels[index])\(isToday ? ", today" : "")\(day?.isRestDay == true ? ", rest day" : "")\(day?.isCompleted == true ? ", completed" : "")")
    }

    // MARK: - Dot Color

    private func dotColor(day: ProgramDay?, isToday: Bool) -> Color {
        guard let day else { return .auraSurfaceElevated }

        if day.isRestDay {
            return .auraTextDisabled.opacity(0.3)
        }

        if day.isCompleted {
            return .neonGreen
        }

        if isToday {
            return .neonBlue
        }

        return .auraSurface
    }
}
