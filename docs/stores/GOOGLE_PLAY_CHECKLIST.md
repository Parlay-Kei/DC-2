# Google Play Console Checklist - Direct Cuts

Complete checklist for submitting Direct Cuts to the Google Play Store.

**App Name:** Direct Cuts
**Package Name:** com.directcuts.app
**Legal Entity:** Direct Cuts LLC
**Support Email:** support@direct-cuts.com

---

## Table of Contents

1. [Account Setup](#1-account-setup)
2. [App Creation](#2-app-creation)
3. [Store Listing](#3-store-listing)
4. [Content Rating](#4-content-rating)
5. [Data Safety](#5-data-safety)
6. [App Access](#6-app-access)
7. [Testing Tracks](#7-testing-tracks)
8. [Production Release](#8-production-release)
9. [Policy Compliance](#9-policy-compliance)
10. [Submission Checklist](#10-submission-checklist)

---

## 1. Account Setup

### Google Play Developer Account

- [ ] **Register for Google Play Console** ($25 one-time fee)
  - URL: https://play.google.com/console/signup
  - Use organization account (Direct Cuts LLC)

- [ ] **Complete identity verification**
  - Required for new accounts
  - May require government ID and business documents

- [ ] **Set up Google Cloud Project**
  - For Play Developer API access (Fastlane integration)

### Service Account Setup (for Fastlane)

1. [ ] Go to Google Cloud Console
2. [ ] Create new project or use existing
3. [ ] Enable Google Play Developer API
4. [ ] Create Service Account with role: "Service Account User"
5. [ ] Download JSON key file
6. [ ] In Play Console: Users & Permissions > Invite > [Service Account Email]
7. [ ] Grant permissions:
   - [ ] Release to production, exclude devices, and use Play App Signing
   - [ ] Manage store presence
   - [ ] Manage testing tracks

### Required Information

| Item | Value | Status |
|------|-------|--------|
| Developer Name | Direct Cuts LLC | [ ] |
| Developer Email | developer@direct-cuts.com | [ ] |
| Physical Address | [Business Address] | [ ] |
| Website | https://direct-cuts.com | [ ] |
| Phone Number | [Business Phone] | [ ] |

---

## 2. App Creation

### Create New Application

- [ ] Go to All Apps > Create app
- [ ] Fill in initial details:

| Field | Value | Status |
|-------|-------|--------|
| App name | Direct Cuts | [ ] |
| Default language | English (United States) | [ ] |
| App or game | App | [ ] |
| Free or paid | Free | [ ] |

### Declarations

- [ ] Accept Developer Program Policies
- [ ] Accept US export laws compliance
- [ ] Acknowledge app meets Play policies

---

## 3. Store Listing

### Main Store Listing

Navigate to: Grow > Store presence > Main store listing

#### App Details

| Field | Value | Max Length | Status |
|-------|-------|------------|--------|
| App name | Direct Cuts | 30 chars | [ ] |
| Short description | Book verified barbers near you. Instant booking, real reviews, secure payments. | 80 chars | [ ] |
| Full description | See fastlane/metadata/android/en-US/full_description.txt | 4000 chars | [ ] |

#### Graphics

##### App Icon

- [ ] **High-res icon:** 512 x 512 px, PNG, 32-bit with alpha
- [ ] Transparent background allowed
- [ ] No badges, text, or promotional content

##### Feature Graphic

- [ ] **Size:** 1024 x 500 px
- [ ] JPG or PNG (24-bit, no alpha)
- [ ] Used for Play Store featuring and promotions

##### Screenshots

**Phone Screenshots (Required)**

| Aspect | Resolution | Quantity | Status |
|--------|------------|----------|--------|
| Portrait | 1080 x 1920 px (min) | 2-8 | [ ] |
| Landscape | 1920 x 1080 px (optional) | 0-8 | [ ] |

**7-inch Tablet Screenshots**

| Aspect | Resolution | Quantity | Status |
|--------|------------|----------|--------|
| Portrait | 1200 x 1920 px | 2-8 | [ ] |
| Landscape | 1920 x 1200 px | 0-8 | [ ] |

**10-inch Tablet Screenshots**

| Aspect | Resolution | Quantity | Status |
|--------|------------|----------|--------|
| Portrait | 1600 x 2560 px | 2-8 | [ ] |
| Landscape | 2560 x 1600 px | 0-8 | [ ] |

##### Video (Optional)

- [ ] YouTube URL (unlisted OK)
- [ ] 30 seconds to 2 minutes
- [ ] Landscape orientation recommended

#### Screenshot Content Guidelines

**DO USE:**
- "Identity-verified barbers"
- "Verified professionals"
- Actual app UI

**DO NOT USE:**
- "Background check" terminology
- "Background screening"
- Misleading imagery

### Contact Details

| Field | Value | Status |
|-------|-------|--------|
| Email | support@direct-cuts.com | [ ] |
| Phone | [Optional - business phone] | [ ] |
| Website | https://direct-cuts.com | [ ] |

### Privacy Policy

- [ ] **URL:** https://direct-cuts.com/privacy
- [ ] Must be accessible
- [ ] Must cover data collection practices

---

## 4. Content Rating

Navigate to: Policy > App content > Content rating

### IARC Questionnaire

Complete the International Age Rating Coalition questionnaire:

| Question | Answer | Notes |
|----------|--------|-------|
| Violence | No | |
| Sexual content | No | |
| Profanity | Yes - Mild | User reviews may contain |
| Gambling | No | |
| Drugs | No | |
| Controlled substances | No | |
| User interaction | Yes | Messaging, reviews |
| Shares location | Yes | For finding barbers |
| Digital purchases | Yes | Service bookings |

### Expected Rating

- **ESRB:** Everyone
- **PEGI:** 3
- **USK:** 0

---

## 5. Data Safety

Navigate to: Policy > App content > Data safety

**CRITICAL:** Be accurate - Google verifies this information.

### Data Collection Overview

| Question | Answer |
|----------|--------|
| Does app collect or share required user data types? | Yes |
| Is all collected data encrypted in transit? | Yes |
| Do you provide a way for users to request data deletion? | Yes |

### Data Types

#### Personal Information

| Data Type | Collected | Shared | Purpose |
|-----------|-----------|--------|---------|
| Name | Yes | No | Account, booking |
| Email address | Yes | No | Account, communications |
| Phone number | Yes | Yes (to barber) | Booking contact |
| Address | No | No | - |

#### Financial Information

| Data Type | Collected | Shared | Purpose |
|-----------|-----------|--------|---------|
| Payment info | Yes | Yes (Stripe) | Payment processing |
| Purchase history | Yes | No | Order history |

#### Location

| Data Type | Collected | Shared | Purpose |
|-----------|-----------|--------|---------|
| Precise location | Yes | No | Find nearby barbers |
| Approximate location | Yes | No | App functionality |

#### Personal Identifiers

| Data Type | Collected | Shared | Purpose |
|-----------|-----------|--------|---------|
| User IDs | Yes | No | Account management |
| Device identifiers | No | No | - |

#### Photos and Videos

| Data Type | Collected | Shared | Purpose |
|-----------|-----------|--------|---------|
| Photos | Yes | Yes (public profile) | Profile, portfolio |

#### App Activity

| Data Type | Collected | Shared | Purpose |
|-----------|-----------|--------|---------|
| App interactions | Yes | No | Analytics |
| In-app search history | Yes | No | App functionality |

### Data Handling Practices

- [ ] Data is encrypted in transit (HTTPS)
- [ ] Data is encrypted at rest (Supabase)
- [ ] Users can request data deletion
- [ ] Deletion request method: In-app or email support@direct-cuts.com

### Third-Party Data Sharing

| Third Party | Data Shared | Purpose |
|-------------|-------------|---------|
| Stripe | Payment info | Payment processing |
| Supabase | User data | Backend services |
| Mapbox | Location | Map display |
| OneSignal | Device tokens | Push notifications |

---

## 6. App Access

Navigate to: Policy > App content > App access

### Access Instructions for Review

Since Direct Cuts requires account creation:

- [ ] Select "All or some functionality is restricted"
- [ ] Provide demo credentials:

```
Demo Account Type: Client
Email: review@direct-cuts.com
Password: [Create secure password]

Demo Account Type: Barber (Optional)
Email: barber.review@direct-cuts.com
Password: [Create secure password]

Instructions:
1. Sign in with demo credentials
2. Allow location access for barber discovery
3. Browse barbers on the map
4. View barber profiles and reviews
5. Test booking flow (no real charges)

Note: Identity verification in this app refers to confirming
barber identities only. No background checks or criminal
screenings are performed.
```

---

## 7. Testing Tracks

Navigate to: Release > Testing

### Internal Testing (Recommended First)

- [ ] Create internal testing track
- [ ] Add internal testers (up to 100 via email)
- [ ] Upload AAB (not APK)
- [ ] Create release and roll out

### Closed Testing (Alpha)

- [ ] Create closed testing track
- [ ] Create tester list or use Google Groups
- [ ] Upload AAB
- [ ] Roll out to closed testers

### Open Testing (Beta)

- [ ] Create open testing track (if needed)
- [ ] Anyone with link can join
- [ ] Good for wider testing before production

### Testing Track Promotion

```
Internal -> Closed -> Open -> Production
```

Use Fastlane `promote_internal` lane to promote builds.

---

## 8. Production Release

Navigate to: Release > Production

### Pre-Launch Checklist

- [ ] App content sections complete
- [ ] Store listing complete
- [ ] Content rating complete
- [ ] Data safety complete
- [ ] Target audience set
- [ ] App access instructions provided

### Country/Region Availability

- [ ] Select countries for initial release
- [ ] Recommended: Start with US, expand later
- [ ] Consider compliance requirements per region

### Release Configuration

| Setting | Recommended Value | Notes |
|---------|-------------------|-------|
| Release type | Staged rollout | Safer for new apps |
| Rollout percentage | 10% | Increase gradually |
| Update priority | Default | |

### App Signing

- [ ] **Opt in to Play App Signing** (Recommended)
  - Google manages your app signing key
  - You only need upload key
  - Enables key upgrade if compromised

### Version Management

| Field | Source | Notes |
|-------|--------|-------|
| Version name | pubspec.yaml | e.g., "2.0.0" |
| Version code | pubspec.yaml | Build number (integer) |

---

## 9. Policy Compliance

### Key Policies for Direct Cuts

#### User Data Policy

- [ ] Privacy policy accessible
- [ ] Data Safety form accurate
- [ ] Data handling transparent

#### Payments Policy

- [ ] In-app purchases for digital goods use Google Play Billing
- [ ] Payments for physical services (haircuts) can use external payment (Stripe) - **ALLOWED**

#### Deceptive Behavior

- [ ] App description matches functionality
- [ ] No misleading claims
- [ ] No "background check" claims (use "identity verification")

#### Ads Policy

- [ ] No deceptive ads
- [ ] No inappropriate ad placement
- [ ] Currently no ads in Direct Cuts

#### Families Policy

- [ ] App NOT designed for children
- [ ] Do NOT select "Designed for Families" program
- [ ] Target audience: General (adults)

### Identity Verification Language

**CRITICAL:** Use correct terminology throughout.

**APPROVED TERMS:**
- "Identity-verified barbers"
- "Verified professionals"
- "Identity verification process"
- "Confirmed identity"

**PROHIBITED TERMS:**
- "Background check"
- "Background screening"
- "Criminal check"
- "Vetted" (ambiguous)

### Target Audience and Content

Navigate to: Policy > App content > Target audience

- [ ] Select target age group: 18+
- [ ] App does NOT appeal primarily to children
- [ ] App is NOT designed for children

---

## 10. Submission Checklist

### Store Presence

- [ ] App name (30 chars)
- [ ] Short description (80 chars)
- [ ] Full description (4000 chars)
- [ ] App icon (512x512 PNG)
- [ ] Feature graphic (1024x500)
- [ ] Phone screenshots (2-8)
- [ ] Tablet screenshots (optional but recommended)
- [ ] Privacy policy URL
- [ ] Contact email

### App Content

- [ ] Content rating questionnaire complete
- [ ] Data safety form complete
- [ ] App access instructions provided
- [ ] Target audience selected
- [ ] Ads declaration (No ads)
- [ ] Government apps (No)
- [ ] Financial features (Payment processing - Yes)
- [ ] Health features (No)

### Technical Requirements

- [ ] AAB signed with upload key
- [ ] Target SDK meets minimum (currently 33+)
- [ ] 64-bit support included
- [ ] No obvious crashes or ANRs
- [ ] Permissions declared in manifest
- [ ] All permission requests have explanations

### Release Process

1. [ ] Upload AAB to Internal Testing
2. [ ] Test on multiple devices
3. [ ] Promote to Closed Testing
4. [ ] Collect feedback
5. [ ] Promote to Production
6. [ ] Start with 10% staged rollout
7. [ ] Monitor crash reports and reviews
8. [ ] Increase rollout percentage
9. [ ] Full rollout at 100%

### Post-Release

- [ ] Monitor Android Vitals dashboard
- [ ] Respond to reviews within 48 hours
- [ ] Track key metrics:
  - Install rate
  - Uninstall rate
  - Crash rate
  - ANR rate
  - Ratings and reviews

---

## Fastlane Commands

```bash
# Validate environment
fastlane android validate

# Build AAB
fastlane android build

# Upload to Internal Testing
fastlane android beta

# Promote to Production
fastlane android promote_internal rollout:0.1

# Full Production Release
fastlane android release rollout:1.0
```

---

## Reference Links

- [Google Play Console](https://play.google.com/console)
- [Play Console Help](https://support.google.com/googleplay/android-developer)
- [Developer Policy Center](https://play.google.com/about/developer-content-policy/)
- [Data Safety Guide](https://support.google.com/googleplay/android-developer/answer/10787469)
- [Launch Checklist](https://developer.android.com/distribute/best-practices/launch/launch-checklist)

---

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2024-XX-XX | DevOps Agent | Initial checklist |

---

*This checklist is specific to Direct Cuts. Last updated: January 2025*
