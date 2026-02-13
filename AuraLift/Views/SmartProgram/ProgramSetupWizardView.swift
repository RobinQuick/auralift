import SwiftUI

// MARK: - ProgramSetupWizardView

/// 4-step wizard for creating a new Pareto training program.
struct ProgramSetupWizardView: View {
    @ObservedObject var viewModel: SmartProgramViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep = 0
    @State private var showGymEditor = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Step indicator
                stepIndicator
                    .padding(.top, AuraTheme.Spacing.md)

                // Content
                TabView(selection: $currentStep) {
                    frequencyStep.tag(0)
                    goalStep.tag(1)
                    gymStep.tag(2)
                    reviewStep.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)

                // Navigation buttons
                navigationBar
            }
            .auraBackground()
            .navigationTitle("AUREA BLUEPRINT")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.neonBlue)
                        .accessibilityLabel("Cancel program setup")
                }
            }
            .sheet(isPresented: $showGymEditor) {
                GymProfileEditorView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: AuraTheme.Spacing.sm) {
            ForEach(0..<4, id: \.self) { step in
                VStack(spacing: AuraTheme.Spacing.xxs) {
                    Circle()
                        .fill(step <= currentStep ? Color.neonBlue : Color.auraSurfaceElevated)
                        .frame(width: 8, height: 8)

                    Text(stepLabel(step))
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(step <= currentStep ? .neonBlue : .auraTextDisabled)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Step \(step + 1): \(stepLabel(step)), \(step <= currentStep ? "completed" : "upcoming")")
            }
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    private func stepLabel(_ step: Int) -> String {
        switch step {
        case 0: return "SPLIT"
        case 1: return "GOAL"
        case 2: return "GYM"
        case 3: return "REVIEW"
        default: return ""
        }
    }

    // MARK: - Step 1: Frequency

    private var frequencyStep: some View {
        ScrollView {
            VStack(spacing: AuraTheme.Spacing.xl) {
                stepHeader(
                    icon: "calendar",
                    title: "Training Split",
                    subtitle: "How many days can you train per week?"
                )

                ForEach(ProgramFrequency.allCases, id: \.rawValue) { freq in
                    frequencyCard(freq)
                }
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)
            .padding(.top, AuraTheme.Spacing.xl)
        }
    }

    private func frequencyCard(_ freq: ProgramFrequency) -> some View {
        let isSelected = viewModel.selectedFrequency == freq

        return Button {
            viewModel.selectedFrequency = freq
        } label: {
            VStack(alignment: .leading, spacing: AuraTheme.Spacing.sm) {
                HStack {
                    Text(freq.displayName)
                        .font(AuraTheme.Fonts.subheading())
                        .foregroundColor(isSelected ? .neonBlue : .auraTextPrimary)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.neonBlue)
                    }
                }

                Text(freq.description)
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)
                    .multilineTextAlignment(.leading)

                // Day labels preview
                HStack(spacing: AuraTheme.Spacing.xs) {
                    ForEach(Array(freq.weekDayLabels.prefix(7).enumerated()), id: \.offset) { _, label in
                        Text(label.prefix(3))
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(label == "Rest" ? .auraTextDisabled : .neonBlue)
                    }
                }
            }
            .darkCard()
            .overlay(
                RoundedRectangle(cornerRadius: AuraTheme.Radius.medium)
                    .stroke(isSelected ? Color.neonBlue.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
        .accessibilityLabel("\(freq.displayName). \(freq.description)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    // MARK: - Step 2: Goal

    private var goalStep: some View {
        ScrollView {
            VStack(spacing: AuraTheme.Spacing.xl) {
                stepHeader(
                    icon: "sparkles",
                    title: "Aesthetic Goal",
                    subtitle: "Which physique archetype do you want to build?"
                )

                ForEach(AestheticGoal.allCases, id: \.rawValue) { goal in
                    goalCard(goal)
                }
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)
            .padding(.top, AuraTheme.Spacing.xl)
        }
    }

    private func goalCard(_ goal: AestheticGoal) -> some View {
        let isSelected = viewModel.selectedGoal == goal

        return Button {
            viewModel.selectedGoal = goal
        } label: {
            VStack(alignment: .leading, spacing: AuraTheme.Spacing.sm) {
                HStack {
                    Image(systemName: goal.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(goal.accentColor)

                    Text(goal.displayName)
                        .font(AuraTheme.Fonts.subheading())
                        .foregroundColor(isSelected ? goal.accentColor : .auraTextPrimary)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(goal.accentColor)
                    }
                }

                Text(goal.description)
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)
                    .multilineTextAlignment(.leading)

                // Priority muscles
                Text("PRIORITY MUSCLES")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundColor(.cyberOrange)

                FlowLayout(spacing: 4) {
                    ForEach(goal.priorityMuscles, id: \.self) { muscle in
                        Text(muscle)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.auraBlack)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(goal.accentColor.opacity(0.8)))
                    }
                }
            }
            .darkCard()
            .overlay(
                RoundedRectangle(cornerRadius: AuraTheme.Radius.medium)
                    .stroke(isSelected ? goal.accentColor.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
        .accessibilityLabel("\(goal.displayName). \(goal.description)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    // MARK: - Step 3: Gym

    private var gymStep: some View {
        ScrollView {
            VStack(spacing: AuraTheme.Spacing.xl) {
                stepHeader(
                    icon: "building.2.fill",
                    title: "Your Gym",
                    subtitle: "Select your gym or create a new one."
                )

                // Existing profiles
                ForEach(viewModel.gymProfiles, id: \.id) { profile in
                    gymProfileCard(profile)
                }

                // Create new
                Button {
                    showGymEditor = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.neonGreen)
                        Text("Create New Gym Profile")
                            .font(AuraTheme.Fonts.subheading())
                            .foregroundColor(.neonGreen)
                    }
                    .frame(maxWidth: .infinity)
                    .darkCard()
                    .overlay(
                        RoundedRectangle(cornerRadius: AuraTheme.Radius.medium)
                            .stroke(Color.neonGreen.opacity(0.3), lineWidth: 1)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                    )
                }
                .accessibilityLabel("Create new gym profile")
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)
            .padding(.top, AuraTheme.Spacing.xl)
        }
    }

    private func gymProfileCard(_ profile: GymProfile) -> some View {
        let isSelected = viewModel.selectedGymProfile?.id == profile.id

        return Button {
            viewModel.selectedGymProfile = profile
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: AuraTheme.Spacing.xxs) {
                    Text(profile.name)
                        .font(AuraTheme.Fonts.subheading())
                        .foregroundColor(isSelected ? .neonBlue : .auraTextPrimary)

                    Text("\(profile.equipmentList.count) equipment types, \(profile.brandList.count) brands")
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.auraTextSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.neonBlue)
                }
            }
            .darkCard()
            .overlay(
                RoundedRectangle(cornerRadius: AuraTheme.Radius.medium)
                    .stroke(isSelected ? Color.neonBlue.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
        .accessibilityLabel("\(profile.name), \(profile.equipmentList.count) equipment types, \(profile.brandList.count) brands")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    // MARK: - Step 4: Review

    private var reviewStep: some View {
        ScrollView {
            VStack(spacing: AuraTheme.Spacing.xl) {
                stepHeader(
                    icon: "sparkle.magnifyingglass",
                    title: "Review",
                    subtitle: "Confirm your 12-week program setup."
                )

                // Summary
                VStack(alignment: .leading, spacing: AuraTheme.Spacing.md) {
                    reviewRow(label: "SPLIT", value: viewModel.selectedFrequency.displayName)
                    reviewRow(label: "GOAL", value: viewModel.selectedGoal.displayName)
                    reviewRow(label: "GYM", value: viewModel.selectedGymProfile?.name ?? "None selected")
                    reviewRow(label: "DURATION", value: "12 weeks")
                    reviewRow(label: "PERIODIZATION", value: "Ramp → Normal → Overload → Deload")
                }
                .darkCard()

                // Priority muscles recap
                VStack(alignment: .leading, spacing: AuraTheme.Spacing.sm) {
                    Text("PRIORITY MUSCLES (60% volume)")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(.cyberOrange)

                    FlowLayout(spacing: 4) {
                        ForEach(viewModel.selectedGoal.priorityMuscles, id: \.self) { muscle in
                            Text(muscle)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.auraBlack)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.cyberOrange))
                        }
                    }
                }
                .darkCard()
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)
            .padding(.top, AuraTheme.Spacing.xl)
        }
    }

    private func reviewRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.auraTextSecondary)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextPrimary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack(spacing: AuraTheme.Spacing.lg) {
            if currentStep > 0 {
                NeonOutlineButton(title: "BACK", icon: "chevron.left") {
                    withAnimation { currentStep -= 1 }
                }
            }

            Spacer()

            if currentStep < 3 {
                NeonButton(title: "NEXT", icon: "chevron.right", color: .neonBlue) {
                    withAnimation { currentStep += 1 }
                }
            } else {
                NeonButton(title: "GENERATE", icon: "bolt.fill", color: .neonGreen) {
                    viewModel.generateNewProgram()
                    dismiss()
                }
                .disabled(viewModel.selectedGymProfile == nil)
                .opacity(viewModel.selectedGymProfile == nil ? 0.5 : 1)
            }
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
        .padding(.vertical, AuraTheme.Spacing.md)
        .background(Color.auraBlack.opacity(0.8))
    }

    // MARK: - Step Header

    private func stepHeader(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: AuraTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.neonBlue)

            Text(title.uppercased())
                .font(AuraTheme.Fonts.heading())
                .foregroundColor(.auraTextPrimary)

            Text(subtitle)
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - FlowLayout

/// Simple flow layout for pill badges.
struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}
