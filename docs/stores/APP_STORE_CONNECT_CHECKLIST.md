# App Store Connect Checklist - Direct Cuts

Complete checklist for submitting Direct Cuts to the Apple App Store.

**App Name:** Direct Cuts
**Bundle ID:** com.directcuts.app
**Legal Entity:** Direct Cuts LLC
**Support Email:** support@direct-cuts.com

---

## Table of Contents

1. [Account Setup](#1-account-setup)
2. [App Store Connect App Creation](#2-app-store-connect-app-creation)
3. [App Information](#3-app-information)
4. [Pricing and Availability](#4-pricing-and-availability)
5. [App Privacy](#5-app-privacy)
6. [Version Information](#6-version-information)
7. [Screenshots](#7-screenshots)
8. [TestFlight Setup](#8-testflight-setup)
9. [App Review Guidelines](#9-app-review-guidelines)
10. [Submission Checklist](#10-submission-checklist)

---

## 1. Account Setup

### Apple Developer Program Enrollment

- [ ] **Enroll in Apple Developer Program** ($99/year)
  - URL: https://developer.apple.com/programs/enroll/
  - Use: Direct Cuts LLC (Organization account)
  - Requires D-U-N-S Number for organization enrollment

- [ ] **Obtain D-U-N-S Number** (if not already have one)
  - Free from Dun & Bradstreet
  - URL: https://developer.apple.com/support/D-U-N-S/
  - Processing time: 5-7 business days

- [ ] **Complete enrollment verification**
  - Apple may call to verify organization details
  - Have legal entity documents ready

### Account Configuration

- [ ] **Add team members** (Settings > Users and Access)
  - Admin: Full access
  - App Manager: App-level access
  - Developer: Development access only

- [ ] **Set up App Store Connect API** (for Fastlane)
  - Go to: Users and Access > Keys > App Store Connect API
  - Create new key with "App Manager" role
  - Download .p8 file (only available once!)
  - Note Key ID and Issuer ID

- [ ] **Configure certificates** (Certificates, Identifiers & Profiles)
  - Create iOS Distribution Certificate
  - Or use Fastlane Match (recommended)

### Required Information

| Item | Value | Status |
|------|-------|--------|
| Apple ID | [developer@direct-cuts.com] | [ ] |
| Team ID | [XXXXXXXXXX] | [ ] |
| Team Name | Direct Cuts LLC | [ ] |
| D-U-N-S Number | [XXXXXXXXX] | [ ] |

---

## 2. App Store Connect App Creation

### Create New App

- [ ] Go to App Store Connect > My Apps > (+) New App
- [ ] Select platform: **iOS**

### Basic Information

| Field | Value | Max Length | Status |
|-------|-------|------------|--------|
| Name | Direct Cuts | 30 chars | [ ] |
| Primary Language | English (U.S.) | - | [ ] |
| Bundle ID | com.directcuts.app | - | [ ] |
| SKU | directcuts-ios | Unique | [ ] |
| User Access | Full Access | - | [ ] |

---

## 3. App Information

### General App Information

- [ ] **Name:** Direct Cuts (30 characters max)
- [ ] **Subtitle:** Book Verified Barbers Near You (30 characters max)

### Category Selection

| Category Type | Selection | Status |
|---------------|-----------|--------|
| Primary Category | Lifestyle | [ ] |
| Secondary Category | Business | [ ] |

### Content Rights

- [ ] Confirm app does not contain third-party content that requires rights clearance
- [ ] OR provide documentation of rights

### Age Rating

Complete the questionnaire honestly:

| Content Type | Selection | Notes |
|--------------|-----------|-------|
| Cartoon/Fantasy Violence | None | |
| Realistic Violence | None | |
| Prolonged Graphic Violence | None | |
| Sexual Content/Nudity | None | |
| Profanity/Crude Humor | Infrequent | User reviews may contain |
| Alcohol/Tobacco/Drugs | None | |
| Mature/Suggestive Themes | None | |
| Simulated Gambling | None | |
| Horror/Fear Themes | None | |
| Medical/Treatment Info | None | |
| Unrestricted Web Access | No | |
| Gambling with Real Currency | No | |

**Expected Rating:** 4+ or 9+

---

## 4. Pricing and Availability

### Pricing

- [ ] **Price:** Free
- [ ] **In-App Purchases:** No (payments handled through Stripe)

### Availability

- [ ] **Countries:** All territories initially (can restrict later)
- [ ] **Pre-Order:** Not applicable for initial release
- [ ] **Release Date:** Set to automatic upon approval OR specific date

### App Distribution

- [ ] Standard App Store distribution
- [ ] NOT using App Clips (future consideration)
- [ ] NOT using Custom Apps

---

## 5. App Privacy

### Privacy Policy

- [ ] **Privacy Policy URL:** https://direct-cuts.com/privacy
- [ ] Ensure policy is accessible and accurate
- [ ] Policy must be in English (localized versions for other regions)

### App Privacy Details (Data Collection)

**IMPORTANT:** Be accurate - Apple verifies this information.

#### Data Types Collected

| Data Type | Collected | Used for Tracking | Linked to User |
|-----------|-----------|-------------------|----------------|
| **Contact Info** | | | |
| - Name | Yes | No | Yes |
| - Email | Yes | No | Yes |
| - Phone Number | Yes | No | Yes |
| **Financial Info** | | | |
| - Payment Info | Yes (Stripe) | No | Yes |
| **Location** | | | |
| - Precise Location | Yes | No | Yes |
| - Coarse Location | Yes | No | Yes |
| **Identifiers** | | | |
| - User ID | Yes | No | Yes |
| - Device ID | No | No | No |
| **Usage Data** | | | |
| - Product Interaction | Yes | No | Yes |
| **User Content** | | | |
| - Photos | Yes | No | Yes |
| - Customer Support | Yes | No | Yes |

#### Data Use Purposes

For each data type above, indicate:

- [ ] **Analytics** - Yes (for app improvement)
- [ ] **Product Personalization** - Yes (barber recommendations)
- [ ] **App Functionality** - Yes (core features)
- [ ] **Third-Party Advertising** - No
- [ ] **Developer Advertising** - No

#### Third-Party SDKs

| SDK | Data Shared | Purpose |
|-----|-------------|---------|
| Supabase | User data | Backend services |
| Stripe | Payment info | Payment processing |
| Mapbox | Location | Maps display |
| OneSignal | Device tokens | Push notifications |

---

## 6. Version Information

### App Version Details

| Field | Value | Max Length | Status |
|-------|-------|------------|--------|
| Version Number | 2.0.0 | - | [ ] |
| Build String | Matches pubspec.yaml | - | [ ] |
| Copyright | 2024 Direct Cuts LLC | - | [ ] |

### What's New (Release Notes)

```
Thanks for using Direct Cuts! This version includes:

- Find and book identity-verified barbers near you
- Real-time availability and instant booking
- Secure in-app payments
- Reviews from verified customers
- In-app messaging with barbers

Questions? Contact support@direct-cuts.com
```

### Description (4000 characters max)

See: `fastlane/metadata/ios/en-US/description.txt`

### Keywords (100 characters max, comma-separated)

```
barber,haircut,booking,fade,appointment,barbershop,grooming,mens,hair,trim
```

### Support URL

- [ ] **URL:** https://direct-cuts.com/support
- [ ] Ensure page is live and functional

### Marketing URL (Optional)

- [ ] **URL:** https://direct-cuts.com

---

## 7. Screenshots

### Required Screenshot Sizes

**IMPORTANT:** At least one screenshot set required for each device size.

#### iPhone Screenshots (Required)

| Device | Resolution | Quantity | Status |
|--------|------------|----------|--------|
| 6.7" Display (iPhone 15 Pro Max) | 1290 x 2796 px | 3-10 | [ ] |
| 6.5" Display (iPhone 14 Plus) | 1284 x 2778 px | 3-10 | [ ] |
| 5.5" Display (iPhone 8 Plus) | 1242 x 2208 px | 3-10 | [ ] |

#### iPad Screenshots (If supporting iPad)

| Device | Resolution | Quantity | Status |
|--------|------------|----------|--------|
| iPad Pro 12.9" (6th gen) | 2048 x 2732 px | 3-10 | [ ] |
| iPad Pro 12.9" (2nd gen) | 2048 x 2732 px | 3-10 | [ ] |

### Screenshot Content Recommendations

1. **Home/Map Screen** - Show barber discovery
2. **Barber Profile** - Verified badge visible
3. **Booking Flow** - Date/time selection
4. **Confirmation** - Successful booking
5. **Reviews** - Social proof

### Screenshot Guidelines

- [ ] Do NOT include "background check" terminology
- [ ] Use "identity-verified" or "verified barbers" instead
- [ ] Show real app UI (no placeholders)
- [ ] May include device frames
- [ ] Text overlays should be minimal
- [ ] Avoid iPhone notch area for critical content

### App Preview Videos (Optional)

| Device | Resolution | Duration | Status |
|--------|------------|----------|--------|
| 6.7" Display | 1290 x 2796 | 15-30 sec | [ ] |
| 6.5" Display | 1284 x 2778 | 15-30 sec | [ ] |

---

## 8. TestFlight Setup

### Internal Testing

- [ ] Add internal testers (up to 100)
- [ ] Build uploads automatically become available

### External Testing

- [ ] Create test group (e.g., "Beta Testers")
- [ ] Add external testers (up to 10,000)
- [ ] Submit for Beta App Review (required for external)

### Beta App Information

| Field | Value | Status |
|-------|-------|--------|
| Test Information | How to test the app | [ ] |
| Email | support@direct-cuts.com | [ ] |
| Privacy Policy URL | https://direct-cuts.com/privacy | [ ] |
| Contact Info | Required contact details | [ ] |

### Beta Build Expiration

- TestFlight builds expire after 90 days
- Plan releases accordingly

---

## 9. App Review Guidelines

### Critical Guidelines for Direct Cuts

#### Identity Verification Language

**DO USE:**
- "Identity-verified barbers"
- "Verified professionals"
- "Identity verification process"

**DO NOT USE:**
- "Background check" (implies criminal/legal investigation)
- "Background screening"
- "Vetted" (can be misinterpreted)

#### Guideline Compliance

| Guideline | Requirement | Compliant |
|-----------|-------------|-----------|
| 1.1 Objectionable Content | No offensive material | [ ] |
| 2.1 App Completeness | Fully functional | [ ] |
| 2.3 Accurate Metadata | Description matches app | [ ] |
| 3.1.1 In-App Purchase | Stripe OK for physical services | [ ] |
| 4.2 Minimum Functionality | Beyond basic web wrapper | [ ] |
| 5.1 Privacy | Policy in place | [ ] |
| 5.1.1 Data Collection | Disclosed accurately | [ ] |

#### Location Permission

- [ ] **NSLocationWhenInUseUsageDescription** is accurate:
  > "Direct Cuts needs your location to find barbers near you."

- [ ] **NSLocationAlwaysAndWhenInUseUsageDescription** is accurate (if used)

#### Push Notification Permission

- [ ] Request permission in context (after explaining benefit)
- [ ] Do NOT request immediately on launch

#### Photo/Camera Permission

- [ ] **NSCameraUsageDescription** explains use:
  > "Direct Cuts needs camera access to take profile photos and send images in chat."

### Common Rejection Reasons to Avoid

1. **Incomplete Information** - All fields filled
2. **Broken Links** - Test all URLs
3. **Bugs/Crashes** - Thorough testing
4. **Misleading Description** - Accurate to actual features
5. **Privacy Issues** - Data collection accurately disclosed
6. **Login Issues** - Demo account for review

### App Review Notes

Provide the following to Apple Review team:

```
Demo Account:
Email: review@direct-cuts.com
Password: [Create demo account]

Notes:
- Direct Cuts is a barber booking platform
- Clients can find and book barbers
- Barbers can manage their schedule and receive payments
- Identity verification refers to confirming barber identities
- No background checks or criminal screenings are performed
- Payments processed via Stripe (physical services)

Test Location:
Use any major US city for barber search

Contact:
support@direct-cuts.com
```

---

## 10. Submission Checklist

### Pre-Submission

- [ ] All metadata complete
- [ ] Screenshots uploaded for all required sizes
- [ ] Privacy policy URL accessible
- [ ] Support URL accessible
- [ ] App built with production configuration
- [ ] App tested on physical devices
- [ ] No crashes in Xcode Organizer
- [ ] Demo account created for Apple Review
- [ ] App Review notes prepared

### Build Upload

- [ ] Build uploaded via Xcode or Fastlane
- [ ] Build visible in App Store Connect
- [ ] No "Missing Compliance" issues
- [ ] Export compliance questions answered

### Export Compliance

Answer YES to: "Does your app use encryption?"
- App uses HTTPS for network communication

Answer YES to: "Does your app qualify for any exemptions?"
- Standard encryption for HTTPS qualifies for exemption

### Submit for Review

- [ ] Select build for submission
- [ ] Answer advertising identifier questions
- [ ] Add App Review notes
- [ ] Submit for review

### Post-Submission

- [ ] Monitor status in App Store Connect
- [ ] Check email for reviewer communications
- [ ] Be ready to respond within 24 hours
- [ ] Prepare rollback plan if rejected

---

## Reference Links

- [App Store Connect](https://appstoreconnect.apple.com)
- [Apple Developer Portal](https://developer.apple.com)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [App Store Product Page Guidelines](https://developer.apple.com/app-store/product-page/)

---

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2024-XX-XX | DevOps Agent | Initial checklist |

---

*This checklist is specific to Direct Cuts. Last updated: January 2025*
