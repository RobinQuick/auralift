# iOS Production & TestFlight Readiness Checklist

This checklist is specific to **AuraLift iOS** and is intended to replace generic web deployment assumptions.

## 1) Project generation & local build

1. Install XcodeGen (`brew install xcodegen`).
2. Generate the project from `project.yml`:
   ```bash
   xcodegen generate
   ```
3. Open `AuraLift.xcodeproj` in Xcode 15+.
4. In **Signing & Capabilities**:
   - Set a valid Team.
   - Confirm bundle identifier.
   - Enable required capabilities (HealthKit, in-app purchase, camera usage strings in Info.plist).
5. Run on a real device (camera + HealthKit features require hardware).

## 2) Production hardening checks

- No placeholder services in critical user paths.
- No fatal crashes for recoverable runtime issues.
- Release build uses `-O` and whole-module optimization.
- App does not rely on preview/in-memory storage outside debug contexts.
- StoreKit product IDs mapped to App Store Connect products.
- HealthKit permission denial flows handled gracefully.

## 3) Performance checks (minimum)

- Workout camera pipeline sustains smooth UI on iPhone 12+.
- Pose processing backpressure behaves correctly under load.
- No visible frame drops when toggling front/back camera.
- Startup time measured on cold launch.
- Memory profile checked during 20+ minute workout session.

## 4) App Store Connect / TestFlight

1. Create app record in App Store Connect.
2. Configure:
   - Privacy policy URL
   - Support URL
   - Age rating
   - Export compliance
3. Build archive in Xcode (Release configuration).
4. Upload build using Organizer.
5. Add internal testers, then external testers after beta app review.
6. Include detailed test notes covering:
   - Camera pose detection
   - MorphoScan
   - HealthKit permissions and data usage

## 5) Documentation required before submission

- Architecture overview (`architecture.md`)
- Data model and persistence (`database-schema.md`)
- Testing protocol (`TEST_GUIDE.md`)
- Product behavior and constraints (`spec.md`)
- iOS release checklist (this file)

## 6) CI recommendation for iOS

At minimum, add a CI job that runs:

```bash
xcodegen generate
xcodebuild -project AuraLift.xcodeproj -scheme AuraLift -configuration Debug -destination 'generic/platform=iOS' build
```

Optionally add unit/UI tests once test targets are created.

## 7) Xcode documentation generation (DocC)

To generate API documentation from Xcode/CLI:

```bash
xcodebuild docbuild \
  -project AuraLift.xcodeproj \
  -scheme AuraLift \
  -destination 'generic/platform=iOS'
```

In Xcode, use **Product → Build Documentation** and review warnings before release.

If you plan to publish docs, add a dedicated DocC catalog and host generated archives as part of CI artifacts.

