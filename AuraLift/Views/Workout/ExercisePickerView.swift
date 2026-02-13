import SwiftUI
import CoreData

/// Exercise selection list backed by CoreData with search, category filters,
/// and morpho-scan risk badges.
struct ExercisePickerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        entity: NSEntityDescription.entity(forEntityName: "Exercise", in: PersistenceController.shared.container.viewContext)!,
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
    ) private var exercises: FetchedResults<Exercise>

    @State private var searchText = ""
    @State private var selectedCategory: String? = nil

    /// Called when an exercise is selected.
    var onSelect: ((Exercise) -> Void)?

    private let categories = ["compound", "isolation"]

    private var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            let matchesCategory = selectedCategory == nil || exercise.category == selectedCategory
            let matchesSearch = searchText.isEmpty || exercise.name.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            VStack(spacing: AuraTheme.Spacing.sm) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 32))
                    .cyberpunkText(color: .neonBlue)

                Text("SELECT EXERCISE")
                    .font(AuraTheme.Fonts.title())
                    .cyberpunkText(color: .neonBlue)
            }
            .padding(.top, AuraTheme.Spacing.xl)
            .padding(.bottom, AuraTheme.Spacing.lg)

            // MARK: - Search Bar
            searchBar

            // MARK: - Category Filters
            categoryFilterRow
                .padding(.vertical, AuraTheme.Spacing.md)

            // MARK: - Exercise List
            ScrollView {
                LazyVStack(spacing: AuraTheme.Spacing.sm) {
                    ForEach(filteredExercises, id: \.id) { exercise in
                        Button {
                            onSelect?(exercise)
                            dismiss()
                        } label: {
                            exerciseRow(exercise)
                        }
                        .accessibilityLabel(exerciseAccessibilityLabel(exercise))
                    }
                }
                .padding(.horizontal, AuraTheme.Spacing.lg)
                .padding(.bottom, AuraTheme.Spacing.xxl)
            }
        }
        .auraBackground()
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: AuraTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.auraTextSecondary)

            TextField("Search exercises...", text: $searchText)
                .font(AuraTheme.Fonts.body())
                .foregroundColor(.auraTextPrimary)
                .accessibilityLabel("Search exercises")

            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.auraTextSecondary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(AuraTheme.Spacing.md)
        .background(Color.auraSurfaceElevated)
        .cornerRadius(AuraTheme.Radius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AuraTheme.Radius.medium)
                .stroke(Color.auraBorder, lineWidth: 0.5)
        )
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    // MARK: - Category Filters

    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AuraTheme.Spacing.sm) {
                categoryChip(nil, label: "All")
                ForEach(categories, id: \.self) { category in
                    categoryChip(category, label: category.capitalized)
                }
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)
        }
    }

    private func categoryChip(_ category: String?, label: String) -> some View {
        let isSelected = selectedCategory == category
        return Button {
            selectedCategory = category
        } label: {
            Text(label)
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(isSelected ? .auraBlack : .auraTextSecondary)
                .padding(.horizontal, AuraTheme.Spacing.md)
                .padding(.vertical, AuraTheme.Spacing.xs)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.neonBlue : Color.auraSurfaceElevated)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.auraBorder, lineWidth: 0.5)
                )
        }
        .accessibilityLabel("Filter \(label)\(isSelected ? ", selected" : "")")
    }

    // MARK: - Exercise Row

    private func exerciseRow(_ exercise: Exercise) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: AuraTheme.Spacing.xs) {
                HStack(spacing: AuraTheme.Spacing.sm) {
                    Text(exercise.name)
                        .font(AuraTheme.Fonts.subheading())
                        .foregroundColor(.auraTextPrimary)

                    riskBadge(for: exercise)
                }

                HStack(spacing: AuraTheme.Spacing.sm) {
                    if let category = exercise.category {
                        Text(category.capitalized)
                            .font(AuraTheme.Fonts.caption())
                            .foregroundColor(.auraTextSecondary)
                    }

                    if let equipment = exercise.equipmentType {
                        Text(equipment.capitalized)
                            .font(AuraTheme.Fonts.caption())
                            .foregroundColor(.auraTextDisabled)
                    }

                    if let primary = exercise.primaryMuscle {
                        Text(primary.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(AuraTheme.Fonts.caption())
                            .foregroundColor(.neonBlue)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextDisabled)
        }
        .darkCard()
    }

    // MARK: - Risk Badge

    private func riskBadge(for exercise: Exercise) -> some View {
        let risk = ExerciseRisk(rawValue: exercise.riskLevel ?? "optimal") ?? .optimal

        return Group {
            if risk != .optimal {
                Text(risk.displayName)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: risk.colorHex))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color(hex: risk.colorHex).opacity(0.15))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color(hex: risk.colorHex).opacity(0.4), lineWidth: 0.5)
                    )
            }
        }
    }

    // MARK: - Accessibility Helpers

    private func exerciseAccessibilityLabel(_ exercise: Exercise) -> String {
        var parts = [exercise.name]
        let risk = ExerciseRisk(rawValue: exercise.riskLevel ?? "optimal") ?? .optimal
        if risk != .optimal {
            parts.append(risk.displayName)
        }
        if let category = exercise.category {
            parts.append(category.capitalized)
        }
        if let primary = exercise.primaryMuscle {
            parts.append(primary.replacingOccurrences(of: "_", with: " ").capitalized)
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Preview

#Preview {
    ExercisePickerView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
