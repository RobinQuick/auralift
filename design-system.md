# Design System — AUREA Clinical Luxury Gold

> Visual language for the Prestige Athlete: OLED black, gold accents, clinical luxury

## Design Principles

1. **OLED Black Canvas** — Pure black (#000000) backgrounds maximize contrast and battery life on OLED displays
2. **Neon Accent Hierarchy** — Neon Blue (primary), Cyber Orange (secondary/action), color-coded status
3. **Glow, Not Shadow** — Elements emit light (neon glow/shadow) rather than casting traditional shadows
4. **Information Density** — HUD-style overlays during workouts; clean cards at rest

---

## Color Palette

### Brand Colors (defined in `Color+AuraLift.swift`)
```swift
Color.aureaVoid            // #000000 — OLED black, primary background
Color.aureaPrimary         // #D4AF37 — Primary accent (Gold)
Color.aureaSecondary       // #C0C0C0 — Secondary accent (Silver)
// Legacy aliases (auraBlack, neonBlue, cyberOrange) still compile
```

### Status Colors
```swift
Color.aureaSuccess         // #4CAF50 — Success, optimal form
Color.aureaAlert           // #CF6679 — Danger, poor form
Color.aureaPrestige        // #FFD700 — Achievements, gold tier
Color.aureaMystic          // #7C4DFF — Special/elite, premium features
// Legacy aliases (neonGreen, neonRed, neonGold, neonPurple) still compile
```

### Surface Colors
```swift
Color.auraSurface         // #0A0A0F — Card backgrounds
Color.auraSurfaceElevated // #12121A — Elevated surface (modals, sheets)
Color.auraBorder          // #1A1A2E — Subtle borders
```

### Text Colors
```swift
Color.auraTextPrimary     // #FFFFFF — Primary text (bright white)
Color.auraTextSecondary   // #8B8B9E — Secondary/label text
Color.auraTextDisabled    // #4A4A5A — Disabled/placeholder text
```

### Rank Tier Colors
```swift
Color.rankIron            // #8B8B8B    Color.rankPlatinum   // #00CED1
Color.rankBronze          // #CD7F32    Color.rankDiamond    // #B9F2FF
Color.rankSilver          // #C0C0C0    Color.rankMaster     // #9B59B6
Color.rankGold            // #FFD700    Color.rankGrandmaster // #FF4444
                                        Color.rankChallenger  // #FF6B00
```

---

## Typography (defined in `AuraTheme.Fonts`)

All fonts use system SF Pro with specific weights and designs:

| Token | Size | Weight | Design | Usage |
|-------|------|--------|--------|-------|
| `title()` | 28pt | .black | .default | Screen titles |
| `heading()` | 22pt | .bold | .default | Section headers |
| `subheading()` | 17pt | .semibold | .default | Card titles, button labels |
| `body()` | 15pt | .regular | .default | Body text |
| `caption()` | 12pt | .medium | .default | Labels, HUD captions |
| `mono()` | 14pt | .medium | .monospaced | Code, technical values |
| `statValue()` | 36pt | .black | .monospaced | Rep counts, large stats |

All font functions accept a custom size parameter: `AuraTheme.Fonts.title(32)`.

---

## Spacing (defined in `AuraTheme.Spacing`)

4px base unit system:

| Token | Value | Usage |
|-------|-------|-------|
| `xxs` | 2pt | Micro gaps (glow offsets) |
| `xs` | 4pt | Tight inline spacing |
| `sm` | 8pt | Related element spacing |
| `md` | 12pt | Standard internal padding |
| `lg` | 16pt | Card padding, section gaps |
| `xl` | 24pt | Major section spacing |
| `xxl` | 32pt | Screen-level spacing |
| `xxxl` | 48pt | Hero/full-section breaks |

---

## Border Radius (defined in `AuraTheme.Radius`)

```swift
AuraTheme.Radius.small    // 6pt  — Tags, badges, HUD chips
AuraTheme.Radius.medium   // 12pt — Cards, inputs, modals
AuraTheme.Radius.large    // 16pt — Large cards, camera preview
AuraTheme.Radius.pill     // 100pt — Buttons, capsule shapes
```

---

## Shadows & Glow (defined in `AuraTheme.Shadows`)

```swift
AuraTheme.Shadows.glowRadius        // 10pt — Standard neon glow
AuraTheme.Shadows.subtleGlowRadius  // 4pt  — Subtle accent glow
```

**Pattern:** Neon glow uses `shadow(color: neonColor.opacity(0.3-0.6), radius: X)` — never traditional dark shadows.

---

## Animations (defined in `AuraTheme.Animation`)

| Token | Type | Duration | Usage |
|-------|------|----------|-------|
| `quick` | easeOut | 0.2s | Button presses, toggles |
| `standard` | easeInOut | 0.3s | State transitions |
| `smooth` | easeInOut | 0.5s | Card reveals, page transitions |
| `spring` | spring(0.4, 0.7) | ~0.4s | Bouncy UI elements |
| `bouncy` | spring(0.3, 0.5) | ~0.3s | Combo counter, score pops |

---

## Gradients

```swift
AuraTheme.neonBlueGradient     // neonBlue → neonBlue@60% (topLeading→bottomTrailing)
AuraTheme.cyberOrangeGradient  // cyberOrange → cyberOrange@60%
AuraTheme.darkSurfaceGradient  // auraSurface → auraBlack (top→bottom)
```

---

## View Modifiers (defined in `ViewModifiers.swift`)

### `.aureaGlow(color:radius:cornerRadius:)`
Applies card background + gold border stroke + glow shadow.
```swift
someView.aureaGlow(color: .aureaPrimary, radius: 10, cornerRadius: 12)
// Legacy alias: .neonGlow() still compiles
```

### `.aureaText(color:)`
Colored foreground + glow shadow for text.
```swift
Text("SCORE").aureaText(color: .aureaPrimary)
// Legacy alias: .cyberpunkText() still compiles
```

### `.aureaCard()`
Standard card: padding + elevated surface + border stroke.
Legacy alias: `.darkCard()` still compiles.

### `.pulse()`
Repeating scale animation (1.0 → 1.05). Used for combo counters, active states.

### `.aureaBackground()`
Full-screen OLED black background ignoring safe area.
Legacy alias: `.auraBackground()` still compiles.

---

## Components (in `Views/Components/`)

### NeonButton
Primary CTA button with filled neon background and glow.
- Props: `title`, `icon?`, `color`, `isCompact`, `action`
- Foreground: `.auraBlack` (dark text on bright button)
- Shape: `.pill` radius capsule

### NeonOutlineButton
Secondary action with outlined border and neon text.
- Props: `title`, `icon?`, `color`, `action`
- Shape: `.pill` radius capsule with stroke border

### GlowCard
Container card with neon glow border effect.

### CyberpunkTabBar
Custom bottom tab bar with 5 tabs (Dashboard, Workout, Ranking, Recovery, Profile).
Each tab has a distinct accent color.

### AnimatedRankBadge
Rank tier badge with tier-appropriate color and animation.

### MuscleMapView
Visual body map showing muscle group status/recovery.

---

## Workout HUD Layout

During live workout, camera fills the screen with overlaid HUD:

```
┌─────────────────────────────────────────┐
│ BARBELL SQUAT          COMBO            │
│ SET 1             ▸ x3 (pulse) ◀       │
│                                         │
│                                         │
│ ┌─────────┐               ┌─────────┐  │
│ │VELOCITY │               │  FORM   │  │
│ │  0.85   │               │   92    │  │
│ │  m/s    │               │   %     │  │
│ └─────────┘               └─────────┘  │
│                                         │
│              ┌────────┐                 │
│              │  REPS  │                 │
│              │   8    │                 │
│              └────────┘                 │
│                                         │
│  [FLIP]              [START / END]      │
└─────────────────────────────────────────┘
```

- All HUD elements use semi-transparent black backgrounds (`auraBlack.opacity(0.6)`)
- Form score is color-coded: green >= 90, orange >= 70, red < 70
- Skeleton overlay: neon blue lines + cyber orange joint dots
