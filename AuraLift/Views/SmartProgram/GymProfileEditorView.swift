import SwiftUI

// MARK: - GymProfileEditorView

/// Editor for creating or editing a gym profile with equipment and brand selection.
struct GymProfileEditorView: View {
    @ObservedObject var viewModel: SmartProgramViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var gymName = ""
    @State private var selectedEquipment: Set<String> = []
    @State private var selectedBrands: Set<String> = []

    private let equipmentOptions = [
        ("barbell", "Barbell", "figure.strengthtraining.traditional"),
        ("dumbbell", "Dumbbell", "dumbbell.fill"),
        ("cable", "Cable", "cable.connector"),
        ("machine", "Machine", "gearshape.fill"),
        ("bodyweight", "Bodyweight", "figure.stand"),
        ("band", "Band", "circle.dotted"),
        ("kettlebell", "Kettlebell", "figure.strengthtraining.functional"),
    ]

    private let brandOptions = [
        "Gym80", "Hammer Strength", "Panatta", "Eleiko", "Technogym"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AuraTheme.Spacing.xl) {
                    // Gym name
                    nameSection

                    // Equipment toggles
                    equipmentSection

                    // Brand selection
                    brandSection

                    // Save button
                    NeonButton(title: "SAVE GYM", icon: "checkmark.circle.fill", color: .neonGreen) {
                        saveProfile()
                    }
                    .padding(.horizontal, AuraTheme.Spacing.lg)
                    .disabled(gymName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(gymName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)

                    Spacer(minLength: AuraTheme.Spacing.xxl)
                }
                .padding(.top, AuraTheme.Spacing.lg)
            }
            .auraBackground()
            .navigationTitle("Your Gym")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.neonBlue)
                }
            }
        }
    }

    // MARK: - Name Section

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: AuraTheme.Spacing.sm) {
            Text("GYM NAME")
                .auraSectionHeader()

            TextField("My Gym", text: $gymName)
                .font(AuraTheme.Fonts.body())
                .foregroundColor(.auraTextPrimary)
                .padding(AuraTheme.Spacing.md)
                .background(Color.auraSurfaceElevated)
                .cornerRadius(AuraTheme.Radius.small)
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    // MARK: - Equipment Section

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: AuraTheme.Spacing.sm) {
            Text("AVAILABLE EQUIPMENT")
                .auraSectionHeader()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AuraTheme.Spacing.sm) {
                ForEach(equipmentOptions, id: \.0) { (key, name, icon) in
                    equipmentToggle(key: key, name: name, icon: icon)
                }
            }
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    private func equipmentToggle(key: String, name: String, icon: String) -> some View {
        let isSelected = selectedEquipment.contains(key)

        return Button {
            if isSelected {
                selectedEquipment.remove(key)
            } else {
                selectedEquipment.insert(key)
            }
        } label: {
            HStack(spacing: AuraTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .neonBlue : .auraTextDisabled)

                Text(name)
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(isSelected ? .auraTextPrimary : .auraTextSecondary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.neonGreen)
                }
            }
            .padding(AuraTheme.Spacing.sm)
            .background(isSelected ? Color.neonBlue.opacity(0.1) : Color.auraSurfaceElevated)
            .cornerRadius(AuraTheme.Radius.small)
            .overlay(
                RoundedRectangle(cornerRadius: AuraTheme.Radius.small)
                    .stroke(isSelected ? Color.neonBlue.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
    }

    // MARK: - Brand Section

    private var brandSection: some View {
        VStack(alignment: .leading, spacing: AuraTheme.Spacing.sm) {
            Text("MACHINE BRANDS")
                .auraSectionHeader()

            Text("Select brands available at your gym for optimal machine matching.")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)
                .padding(.horizontal, AuraTheme.Spacing.lg)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AuraTheme.Spacing.sm) {
                ForEach(brandOptions, id: \.self) { brand in
                    brandToggle(brand: brand)
                }
            }
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    private func brandToggle(brand: String) -> some View {
        let isSelected = selectedBrands.contains(brand)

        return Button {
            if isSelected {
                selectedBrands.remove(brand)
            } else {
                selectedBrands.insert(brand)
            }
        } label: {
            Text(brand)
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(isSelected ? .auraTextPrimary : .auraTextSecondary)
                .padding(.horizontal, AuraTheme.Spacing.md)
                .padding(.vertical, AuraTheme.Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.neonPurple.opacity(0.15) : Color.auraSurfaceElevated)
                .cornerRadius(AuraTheme.Radius.small)
                .overlay(
                    RoundedRectangle(cornerRadius: AuraTheme.Radius.small)
                        .stroke(isSelected ? Color.neonPurple.opacity(0.4) : Color.clear, lineWidth: 1)
                )
        }
    }

    // MARK: - Save

    private func saveProfile() {
        let name = gymName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        viewModel.saveGymProfile(
            name: name,
            equipment: Array(selectedEquipment),
            brands: Array(selectedBrands)
        )
        dismiss()
    }
}
