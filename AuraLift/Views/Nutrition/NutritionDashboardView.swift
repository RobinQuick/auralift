import SwiftUI
import CoreData

/// Main Nutrition dashboard with macro tracking, goal selector, carb cycling indicator,
/// and Greek ideal nutrition plan — all with cyberpunk styling.
struct NutritionDashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: NutritionViewModel

    @State private var selectedSegment = 0

    init() {
        _viewModel = StateObject(wrappedValue: NutritionViewModel(
            context: PersistenceController.shared.container.viewContext
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AuraTheme.Spacing.xl) {
                // MARK: - Header
                headerSection

                // MARK: - Goal Selector
                goalSelector

                // MARK: - Segment Picker
                Picker("View", selection: $selectedSegment) {
                    Text("Macros").tag(0)
                    Text("Body Stats").tag(1)
                    Text("Supplements").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AuraTheme.Spacing.lg)

                // MARK: - Content
                switch selectedSegment {
                case 0:
                    macrosSection
                case 1:
                    BodyStatsView(viewModel: viewModel)
                case 2:
                    SupplementView(viewModel: viewModel)
                default:
                    macrosSection
                }

                Spacer(minLength: AuraTheme.Spacing.xxl)
            }
        }
        .auraBackground()
        .task {
            await viewModel.refreshAll()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: AuraTheme.Spacing.sm) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 36))
                .cyberpunkText(color: .neonBlue)

            Text("NUTRITION")
                .font(AuraTheme.Fonts.title())
                .cyberpunkText(color: .neonBlue)

            HStack(spacing: AuraTheme.Spacing.sm) {
                Text(viewModel.trainingDay.rawValue)
                    .font(AuraTheme.Fonts.mono())
                    .foregroundColor(.cyberOrange)
                Text("Day")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)
            }
        }
        .padding(.top, AuraTheme.Spacing.xl)
    }

    // MARK: - Goal Selector

    private var goalSelector: some View {
        HStack(spacing: AuraTheme.Spacing.sm) {
            ForEach(NutritionGoal.allCases, id: \.rawValue) { goal in
                Button {
                    viewModel.setGoal(goal)
                } label: {
                    Text(goal.rawValue)
                        .font(AuraTheme.Fonts.mono(12))
                        .foregroundColor(viewModel.currentGoal == goal ? .auraBlack : .auraTextSecondary)
                        .padding(.horizontal, AuraTheme.Spacing.md)
                        .padding(.vertical, AuraTheme.Spacing.xs)
                        .background(
                            viewModel.currentGoal == goal
                                ? Color.neonBlue
                                : Color.auraSurfaceElevated
                        )
                        .cornerRadius(AuraTheme.Radius.pill)
                }
            }
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    // MARK: - Macros Section

    private var macrosSection: some View {
        VStack(spacing: AuraTheme.Spacing.lg) {
            // Calorie ring
            calorieRing

            // Macro rings row
            macroRingsRow

            // Water intake
            waterSection

            // Nutrition plan card (if available)
            if let plan = viewModel.nutritionPlan {
                planCard(plan)
            }

            // Carb cycling info
            carbCyclingCard
        }
    }

    // MARK: - Calorie Ring

    private var calorieRing: some View {
        let progress = min(viewModel.calorieProgress, 1.0)
        let color: Color = progress >= 0.9 ? .neonGreen : (progress >= 0.5 ? .neonBlue : .auraTextDisabled)

        return ZStack {
            Circle()
                .stroke(Color.auraSurfaceElevated, lineWidth: 14)
                .frame(width: 160, height: 160)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.5), radius: 8)
                .animation(.easeInOut(duration: 0.8), value: progress)

            VStack(spacing: AuraTheme.Spacing.xxs) {
                Text("\(Int(viewModel.actualCalories))")
                    .font(AuraTheme.Fonts.statValue(30))
                    .foregroundColor(.auraTextPrimary)
                Text("/ \(Int(viewModel.targetCalories)) kcal")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)
            }
        }
    }

    // MARK: - Macro Rings

    private var macroRingsRow: some View {
        HStack(spacing: AuraTheme.Spacing.lg) {
            macroRing(
                label: "Protein",
                current: viewModel.actualProtein,
                target: viewModel.targetProtein,
                unit: "g",
                color: .cyberOrange
            )
            macroRing(
                label: "Carbs",
                current: viewModel.actualCarbs,
                target: viewModel.targetCarbs,
                unit: "g",
                color: .neonGreen
            )
            macroRing(
                label: "Fat",
                current: viewModel.actualFat,
                target: viewModel.targetFat,
                unit: "g",
                color: .neonPurple
            )
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    private func macroRing(label: String, current: Double, target: Double, unit: String, color: Color) -> some View {
        let progress = target > 0 ? min(current / target, 1.0) : 0

        return VStack(spacing: AuraTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .stroke(Color.auraSurfaceElevated, lineWidth: 8)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: color.opacity(0.4), radius: 4)

                Text("\(Int(current))")
                    .font(AuraTheme.Fonts.mono(16))
                    .foregroundColor(.auraTextPrimary)
            }

            Text(label)
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)

            Text("\(Int(current))/\(Int(target))\(unit)")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Water Section

    private var waterSection: some View {
        VStack(spacing: AuraTheme.Spacing.md) {
            HStack(spacing: AuraTheme.Spacing.md) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.neonBlue)

                VStack(alignment: .leading, spacing: AuraTheme.Spacing.xs) {
                    Text("Hydration")
                        .font(AuraTheme.Fonts.subheading())
                        .foregroundColor(.auraTextPrimary)

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: AuraTheme.Radius.pill)
                                .fill(Color.auraSurface)
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: AuraTheme.Radius.pill)
                                .fill(Color.neonBlue)
                                .frame(width: geometry.size.width * min(viewModel.waterProgress, 1.0), height: 8)
                                .shadow(color: .neonBlue.opacity(0.5), radius: 4)
                        }
                    }
                    .frame(height: 8)
                }

                Text(String(format: "%.1f/%.1fL", viewModel.actualWater, viewModel.targetWater))
                    .font(AuraTheme.Fonts.mono())
                    .foregroundColor(.neonBlue)
            }
            .darkCard()
            .padding(.horizontal, AuraTheme.Spacing.lg)
        }
    }

    // MARK: - Nutrition Plan Card

    private func planCard(_ plan: NutritionPlan) -> some View {
        VStack(alignment: .leading, spacing: AuraTheme.Spacing.sm) {
            HStack(spacing: AuraTheme.Spacing.sm) {
                Image(systemName: "target")
                    .foregroundColor(.neonGold)
                Text("SCULPT PROTOCOL")
                    .font(AuraTheme.Fonts.subheading())
                    .foregroundColor(.auraTextPrimary)
                Spacer()
                Text(plan.goal.rawValue)
                    .font(AuraTheme.Fonts.mono())
                    .foregroundColor(.neonGold)
            }

            Text(plan.summary)
                .font(AuraTheme.Fonts.body())
                .foregroundColor(.auraTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if plan.weeksDuration > 0 {
                HStack(spacing: AuraTheme.Spacing.lg) {
                    VStack(spacing: AuraTheme.Spacing.xxs) {
                        Text("Duration")
                            .font(AuraTheme.Fonts.caption())
                            .foregroundColor(.auraTextDisabled)
                        Text("\(plan.weeksDuration) weeks")
                            .font(AuraTheme.Fonts.mono())
                            .foregroundColor(.neonGold)
                    }
                    .frame(maxWidth: .infinity)

                    if plan.carbReductionPercent > 0 {
                        VStack(spacing: AuraTheme.Spacing.xxs) {
                            Text("Carb Reduction")
                                .font(AuraTheme.Fonts.caption())
                                .foregroundColor(.auraTextDisabled)
                            Text("-\(plan.carbReductionPercent)% rest days")
                                .font(AuraTheme.Fonts.mono())
                                .foregroundColor(.cyberOrange)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .darkCard()
        .neonGlow(color: .neonGold, radius: AuraTheme.Shadows.subtleGlowRadius)
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    // MARK: - Carb Cycling Card

    private var carbCyclingCard: some View {
        VStack(alignment: .leading, spacing: AuraTheme.Spacing.sm) {
            HStack(spacing: AuraTheme.Spacing.sm) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.neonGreen)
                Text("CARB CYCLING")
                    .font(AuraTheme.Fonts.subheading())
                    .foregroundColor(.auraTextPrimary)
            }

            HStack(spacing: AuraTheme.Spacing.sm) {
                carbDayBadge(type: .rest, isActive: viewModel.trainingDay == .rest)
                carbDayBadge(type: .light, isActive: viewModel.trainingDay == .light)
                carbDayBadge(type: .moderate, isActive: viewModel.trainingDay == .moderate)
                carbDayBadge(type: .intense, isActive: viewModel.trainingDay == .intense)
            }
        }
        .darkCard()
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    private func carbDayBadge(type: TrainingDayType, isActive: Bool) -> some View {
        let modifier = Int((type.carbModifier - 1.0) * 100)
        let sign = modifier >= 0 ? "+" : ""
        let color: Color = isActive ? .neonGreen : .auraTextDisabled

        return VStack(spacing: AuraTheme.Spacing.xxs) {
            Text(type.rawValue)
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(isActive ? .auraTextPrimary : .auraTextDisabled)
            Text("\(sign)\(modifier)%")
                .font(AuraTheme.Fonts.mono(12))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AuraTheme.Spacing.xs)
        .background(isActive ? Color.neonGreen.opacity(0.1) : Color.clear)
        .cornerRadius(AuraTheme.Radius.small)
    }
}

// MARK: - Preview

#Preview {
    NutritionDashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
