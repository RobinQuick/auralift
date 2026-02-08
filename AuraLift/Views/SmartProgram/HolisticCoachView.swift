import SwiftUI
import CoreData

// MARK: - HolisticCoachView

/// Main weekly dashboard for the Pareto Aesthetic Engine.
/// Shows program progress, today's session, nutrition sync, and predictions.
struct HolisticCoachView: View {
    @StateObject private var viewModel: SmartProgramViewModel
    @Environment(\.managedObjectContext) private var viewContext

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: SmartProgramViewModel(context: context))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AuraTheme.Spacing.xl) {
                // Program header
                programHeader

                // Week day strip
                if !viewModel.weekDays.isEmpty {
                    WeekDayStripView(
                        days: viewModel.weekDays,
                        todayIndex: todayDayIndex
                    )
                    .padding(.horizontal, AuraTheme.Spacing.lg)
                }

                // Session adaptation banner
                if let adaptation = viewModel.sessionAdaptation {
                    adaptationBanner(adaptation)
                }

                // Today's session
                todaySessionSection

                // Nutrition sync
                nutritionCard

                // Prediction card
                if !viewModel.waistPrediction.isEmpty {
                    predictionCard
                }

                Spacer(minLength: AuraTheme.Spacing.xxl)
            }
            .padding(.top, AuraTheme.Spacing.lg)
        }
        .auraBackground()
        .navigationTitle("Smart Program")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadActiveProgram()
            viewModel.checkSessionAdaptation()
        }
        .sheet(isPresented: $viewModel.showSwapSheet) {
            if let swapping = viewModel.swappingExercise {
                ExerciseSwapSheet(
                    suggestions: viewModel.swapSuggestions,
                    currentExerciseName: swapping.exerciseName
                ) { suggestion in
                    viewModel.applySwap(suggestion, for: swapping)
                }
            }
        }
        .sheet(isPresented: $viewModel.showOverloadSummary) {
            OverloadSummaryView(decisions: viewModel.overloadDecisions)
        }
    }

    // MARK: - Program Header

    private var programHeader: some View {
        VStack(spacing: AuraTheme.Spacing.sm) {
            if let program = viewModel.activeProgram {
                Text(program.name.uppercased())
                    .font(AuraTheme.Fonts.heading())
                    .foregroundColor(.auraTextPrimary)

                HStack(spacing: AuraTheme.Spacing.md) {
                    // Week badge
                    HStack(spacing: AuraTheme.Spacing.xs) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                        Text("Week \(program.currentWeekNumber)/12")
                            .font(AuraTheme.Fonts.mono())
                    }
                    .foregroundColor(.neonBlue)

                    // Week type badge
                    if let week = viewModel.currentWeek {
                        Text(week.parsedWeekType.displayName.uppercased())
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(.auraBlack)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(week.parsedWeekType.badgeColor))
                    }

                    // Goal badge
                    Text(program.parsedGoal.displayName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(program.parsedGoal.accentColor)
                }
            } else {
                Text("NO ACTIVE PROGRAM")
                    .font(AuraTheme.Fonts.heading())
                    .foregroundColor(.auraTextSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    // MARK: - Today's Session

    private var todaySessionSection: some View {
        VStack(alignment: .leading, spacing: AuraTheme.Spacing.md) {
            HStack {
                Text("TODAY'S SESSION")
                    .auraSectionHeader()

                Spacer()

                if let day = viewModel.todayDay {
                    Text(day.dayLabel.uppercased())
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(.neonBlue)

                    if day.estimatedDurationMinutes > 0 {
                        Text("~\(day.estimatedDurationMinutes) min")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.auraTextDisabled)
                    }
                }
            }

            if let day = viewModel.todayDay, day.isRestDay {
                restDayCard
            } else if viewModel.todayExercises.isEmpty {
                emptyDayCard
            } else {
                ForEach(viewModel.todayExercises, id: \.id) { progEx in
                    ProgramExerciseRow(programExercise: progEx) {
                        viewModel.requestSwap(for: progEx)
                    }
                }
            }
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    private var restDayCard: some View {
        HStack(spacing: AuraTheme.Spacing.md) {
            Image(systemName: "bed.double.fill")
                .font(.system(size: 24))
                .foregroundColor(.neonPurple)

            VStack(alignment: .leading, spacing: 2) {
                Text("REST DAY")
                    .font(AuraTheme.Fonts.subheading())
                    .foregroundColor(.neonPurple)

                Text("Recovery is part of the program. Focus on sleep and nutrition.")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)
            }
        }
        .darkCard()
    }

    private var emptyDayCard: some View {
        HStack(spacing: AuraTheme.Spacing.md) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 24))
                .foregroundColor(.auraTextDisabled)

            Text("No session scheduled for today.")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)
        }
        .darkCard()
    }

    // MARK: - Adaptation Banner

    private func adaptationBanner(_ adaptation: SessionAdaptation) -> some View {
        HStack(spacing: AuraTheme.Spacing.sm) {
            Image(systemName: adaptation.mode == .technique ? "gauge.with.dots.needle.0percent" : "exclamationmark.triangle.fill")
                .font(.system(size: 18))
                .foregroundColor(adaptation.mode == .technique ? .cyberOrange : .neonRed)

            VStack(alignment: .leading, spacing: 2) {
                Text(adaptation.mode == .technique ? "TECHNIQUE MODE" : "LOAD ADJUSTED")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(adaptation.mode == .technique ? .cyberOrange : .neonRed)

                Text(adaptation.whyMessage)
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .darkCard()
        .overlay(
            RoundedRectangle(cornerRadius: AuraTheme.Radius.medium)
                .stroke(Color.cyberOrange.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    // MARK: - Nutrition Card

    private var nutritionCard: some View {
        VStack(alignment: .leading, spacing: AuraTheme.Spacing.sm) {
            HStack {
                Text("NUTRITION SYNC")
                    .auraSectionHeader()

                Spacer()

                Text(viewModel.trainingDayType.rawValue.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.neonGreen)
            }

            if let macros = viewModel.todayMacros {
                HStack(spacing: AuraTheme.Spacing.md) {
                    macroCircle(value: Int(macros.calories), label: "kcal", color: .neonBlue)
                    macroCircle(value: Int(macros.proteinGrams), label: "P (g)", color: .neonGreen)
                    macroCircle(value: Int(macros.carbsGrams), label: "C (g)", color: .cyberOrange)
                    macroCircle(value: Int(macros.fatGrams), label: "F (g)", color: .neonPurple)
                }
            } else {
                Text("Complete your profile to see nutrition targets.")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextDisabled)
            }
        }
        .darkCard()
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    private func macroCircle(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(AuraTheme.Fonts.statValue(18))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.auraTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Prediction Card

    private var predictionCard: some View {
        HStack(spacing: AuraTheme.Spacing.sm) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 22))
                .foregroundColor(.neonGreen)

            VStack(alignment: .leading, spacing: 2) {
                Text("PREDICTION")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundColor(.neonGreen)

                Text(viewModel.waistPrediction)
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextPrimary)
            }

            Spacer()
        }
        .darkCard()
        .neonGlow(color: .neonGreen, radius: AuraTheme.Shadows.subtleGlowRadius)
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    // MARK: - Helpers

    private var todayDayIndex: Int? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return viewModel.weekDays.firstIndex { day in
            guard let scheduled = day.scheduledDate else { return false }
            return calendar.isDate(scheduled, inSameDayAs: today)
        }
    }
}
