import SwiftUI
import AVFoundation

// MARK: - AudioSettingsView

/// Settings screen for voice pack selection, volume controls, and audio feature toggles.
struct AudioSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: - Settings State

    @State private var selectedPersona: PersonaMode = .spartan
    @State private var masterVolume: Float = 0.8
    @State private var voiceVolume: Float = 0.8
    @State private var sfxVolume: Float = 0.7
    @State private var voiceEnabled: Bool = true
    @State private var sfxEnabled: Bool = true
    @State private var hapticsEnabled: Bool = true
    @State private var showPaywall: Bool = false

    // MARK: - Preview

    private let previewSynthesizer = AVSpeechSynthesizer()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AuraTheme.Spacing.xl) {
                    voicePackSection
                    volumeSection
                    togglesSection
                    Spacer(minLength: AuraTheme.Spacing.xxl)
                }
                .padding(.top, AuraTheme.Spacing.lg)
            }
            .auraBackground()
            .navigationTitle("Persona & Voice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.neonBlue)
                }
            }
            .onAppear { loadSettings() }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Persona Section

    private var voicePackSection: some View {
        VStack(spacing: AuraTheme.Spacing.md) {
            Text("PERSONA")
                .auraSectionHeader()

            VStack(spacing: AuraTheme.Spacing.sm) {
                ForEach(PersonaMode.allCases, id: \.rawValue) { persona in
                    personaCard(persona)
                }
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)
        }
    }

    private func personaCard(_ persona: PersonaMode) -> some View {
        let isSelected = selectedPersona == persona

        return Button {
            selectedPersona = persona
            saveSettings()
        } label: {
            HStack(spacing: AuraTheme.Spacing.md) {
                Image(systemName: persona.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .aureaPrimary : .aureaTextSecondary)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: AuraTheme.Spacing.xs) {
                    Text(persona.displayName)
                        .font(AuraTheme.Fonts.subheading())
                        .foregroundColor(.aureaTextPrimary)

                    Text(persona.description)
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.aureaTextSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.aureaPrimary)
                }
            }
            .aureaCard()
            .overlay(
                RoundedRectangle(cornerRadius: AuraTheme.Radius.medium)
                    .stroke(isSelected ? Color.aureaPrimary.opacity(0.6) : Color.clear, lineWidth: 1)
            )
        }
        .contextMenu {
            Button {
                previewPersona(persona)
            } label: {
                Label("Preview", systemImage: "play.circle")
            }
        }
    }

    // MARK: - Volume Section

    private var volumeSection: some View {
        VStack(spacing: AuraTheme.Spacing.md) {
            Text("VOLUME")
                .auraSectionHeader()

            VStack(spacing: AuraTheme.Spacing.sm) {
                volumeSlider(label: "Master", value: $masterVolume, color: .neonBlue)
                volumeSlider(label: "Voice", value: $voiceVolume, color: .neonGreen)
                volumeSlider(label: "SFX", value: $sfxVolume, color: .cyberOrange)
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)
        }
    }

    private func volumeSlider(label: String, value: Binding<Float>, color: Color) -> some View {
        VStack(spacing: AuraTheme.Spacing.xs) {
            HStack {
                Text(label)
                    .font(AuraTheme.Fonts.body())
                    .foregroundColor(.auraTextPrimary)

                Spacer()

                Text("\(Int(value.wrappedValue * 100))%")
                    .font(AuraTheme.Fonts.mono())
                    .foregroundColor(color)
            }

            Slider(value: value, in: 0...1, step: 0.05)
                .accentColor(color)
                .onChange(of: value.wrappedValue) { _ in saveSettings() }
        }
        .darkCard()
    }

    // MARK: - Toggles Section

    private var togglesSection: some View {
        VStack(spacing: AuraTheme.Spacing.md) {
            Text("FEATURES")
                .auraSectionHeader()

            VStack(spacing: AuraTheme.Spacing.sm) {
                featureToggle(
                    label: "Voice Announcer",
                    description: "Spoken performance feedback during workouts",
                    icon: "waveform",
                    isOn: $voiceEnabled,
                    color: .neonGreen
                )
                featureToggle(
                    label: "Sound Effects",
                    description: "Procedural audio cues for reps, combos, and events",
                    icon: "speaker.wave.2.fill",
                    isOn: $sfxEnabled,
                    color: .cyberOrange
                )
                featureToggle(
                    label: "Haptic Feedback",
                    description: "Vibration patterns for reps, sets, and safety alerts",
                    icon: "iphone.radiowaves.left.and.right",
                    isOn: $hapticsEnabled,
                    color: .neonBlue
                )
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)

            // Preview button
            Button {
                previewPersona(selectedPersona)
            } label: {
                HStack(spacing: AuraTheme.Spacing.sm) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 18))
                    Text("Preview Persona")
                        .font(AuraTheme.Fonts.subheading())
                }
                .foregroundColor(.aureaPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AuraTheme.Spacing.md)
                .background(Color.aureaPrimary.opacity(0.1))
                .cornerRadius(AuraTheme.Radius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: AuraTheme.Radius.medium)
                        .stroke(Color.aureaPrimary.opacity(0.3), lineWidth: 0.5)
                )
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)
        }
    }

    private func featureToggle(label: String, description: String, icon: String, isOn: Binding<Bool>, color: Color) -> some View {
        HStack(spacing: AuraTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AuraTheme.Fonts.body())
                    .foregroundColor(.auraTextPrimary)

                Text(description)
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(color)
                .onChange(of: isOn.wrappedValue) { _ in saveSettings() }
        }
        .darkCard()
    }

    // MARK: - Preview

    private func previewPersona(_ persona: PersonaMode) {
        let engine = PersonaEngine()
        engine.currentPersona = persona
        let line = engine.lineFor(event: .sessionStart)
        let config = persona.voiceConfig

        let utterance = AVSpeechUtterance(string: line)
        utterance.preUtteranceDelay = 0
        utterance.volume = masterVolume * voiceVolume

        if let identifier = config.voiceIdentifier {
            utterance.voice = AVSpeechSynthesisVoice(identifier: identifier)
                ?? AVSpeechSynthesisVoice(language: "en-US")
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }

        utterance.pitchMultiplier = config.pitch
        utterance.rate = config.rate

        if previewSynthesizer.isSpeaking {
            previewSynthesizer.stopSpeaking(at: .immediate)
        }
        previewSynthesizer.speak(utterance)
    }

    // MARK: - Persistence

    private func loadSettings() {
        let defaults = UserDefaults.standard
        let personaRaw = defaults.string(forKey: "persona.mode") ?? ""
        selectedPersona = PersonaMode(rawValue: personaRaw) ?? .spartan
        masterVolume = defaults.object(forKey: "audio.masterVolume") as? Float ?? 0.8
        voiceVolume = defaults.object(forKey: "audio.voiceVolume") as? Float ?? 0.8
        sfxVolume = defaults.object(forKey: "audio.sfxVolume") as? Float ?? 0.7
        voiceEnabled = defaults.object(forKey: "audio.voiceEnabled") as? Bool ?? true
        sfxEnabled = defaults.object(forKey: "audio.sfxEnabled") as? Bool ?? true
        hapticsEnabled = defaults.object(forKey: "audio.hapticsEnabled") as? Bool ?? true
    }

    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(selectedPersona.rawValue, forKey: "persona.mode")
        defaults.set(masterVolume, forKey: "audio.masterVolume")
        defaults.set(voiceVolume, forKey: "audio.voiceVolume")
        defaults.set(sfxVolume, forKey: "audio.sfxVolume")
        defaults.set(voiceEnabled, forKey: "audio.voiceEnabled")
        defaults.set(sfxEnabled, forKey: "audio.sfxEnabled")
        defaults.set(hapticsEnabled, forKey: "audio.hapticsEnabled")
    }
}

// MARK: - Preview

#Preview {
    AudioSettingsView()
}
