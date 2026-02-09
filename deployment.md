# AUREA — iOS Deployment Guide

## Prerequisites

- Xcode 15.0+ with iOS 16.0+ SDK
- Apple Developer Program membership (Team ID: `CTK8664PKS`)
- Physical iPhone for camera/HealthKit testing

## Local Build

```bash
# Generate Xcode project from project.yml (requires XcodeGen)
xcodegen generate

# Build for simulator
xcodebuild -scheme AuraLift -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# Build for device (requires signing)
xcodebuild -scheme AuraLift -destination 'generic/platform=iOS' build
```

## Signing & Provisioning

- **Code Sign Style:** Automatic (managed by Xcode)
- **Team:** CTK8664PKS
- **Bundle ID:** `com.aurea.app`
- **Entitlements:** `AuraLift/AuraLift.entitlements` (HealthKit)

Xcode will auto-create provisioning profiles when you select the team in Signing & Capabilities.

## TestFlight

1. In Xcode: **Product > Archive**
2. In Organizer: **Distribute App > TestFlight & App Store**
3. Wait for processing in App Store Connect (~15 min)
4. Add internal/external testers in TestFlight tab

## App Store Submission

1. Archive a Release build
2. Upload via Xcode Organizer or `xcrun altool`
3. In App Store Connect:
   - Fill in app metadata (description, screenshots, keywords)
   - Set pricing and availability
   - Add privacy policy URL (required)
   - Submit for review

## Required Assets (User Must Provide)

- **App Icon:** 1024x1024 PNG in `AuraLift/Resources/Assets.xcassets/AppIcon.appiconset/`
- **Privacy Policy:** Hosted URL required by App Store review
- **Screenshots:** At least one set for each required device size

## Environment Notes

- Zero third-party dependencies — 100% Apple frameworks
- No server component — all data is on-device (CoreData + HealthKit)
- StoreKit 2 product IDs: `com.aurea.pro.monthly`, `com.aurea.pro.yearly`, `com.aurea.pro.lifetime`
- ITSAppUsesNonExemptEncryption: `false` (no custom encryption)
