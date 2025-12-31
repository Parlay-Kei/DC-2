# Mobile Test Plan - Direct Cuts

**Version:** 1.0.0
**Last Updated:** 2025-12-31
**Platform:** Flutter 3.27.0

## Overview

This document outlines the comprehensive testing strategy for the Direct Cuts mobile application. The test plan covers integration tests, smoke tests, and critical user flow validation.

## Test Environment

### Requirements
- Flutter SDK 3.27.0+
- Dart SDK 3.6.0+
- Android Emulator (API 29+) or physical device
- iOS Simulator (iOS 15+) or physical device
- Supabase test environment
- Stripe test mode keys

### Environment Variables
```bash
SUPABASE_URL=<test-instance-url>
SUPABASE_ANON_KEY=<test-anon-key>
STRIPE_PUBLISHABLE_KEY=pk_test_xxx
MAPBOX_ACCESS_TOKEN=<test-token>
ONESIGNAL_APP_ID=<test-app-id>
```

## Test Categories

### 1. Authentication Flow Tests
**File:** `test/integration/auth_flow_test.dart`

| Test Case | Priority | Description |
|-----------|----------|-------------|
| Customer Registration | P0 | New user can create account with email/password |
| Customer Login | P0 | Existing user can login successfully |
| Barber Registration | P0 | Barber can register with required info |
| Identity Verification Flow | P0 | Identity verification submission works |
| Password Reset | P1 | Password reset email sent and works |
| Session Persistence | P1 | User stays logged in across app restart |
| Logout | P1 | User can logout cleanly |
| Token Refresh | P1 | Expired tokens refresh automatically |

### 2. Barber Search & Discovery Tests
**File:** `test/integration/barber_search_test.dart`

| Test Case | Priority | Description |
|-----------|----------|-------------|
| Location-Based Search | P0 | Barbers found within radius |
| Map Display | P0 | Mapbox renders barber locations |
| Filter by Service | P1 | Filter results by service type |
| Filter by Availability | P1 | Filter by available time slots |
| Barber Profile View | P0 | View full barber profile/portfolio |
| Reviews Display | P1 | Reviews and ratings shown correctly |
| Distance Calculation | P1 | Accurate distance to barber shown |

### 3. Booking Flow Tests
**File:** `test/integration/booking_flow_test.dart`

| Test Case | Priority | Description |
|-----------|----------|-------------|
| Select Barber | P0 | Navigate to barber booking page |
| Select Service | P0 | Choose service from barber's list |
| Select Time Slot | P0 | Pick available appointment time |
| Confirm Booking | P0 | Complete booking submission |
| Booking Confirmation | P0 | Confirmation screen shows details |
| View Upcoming Bookings | P1 | My appointments list accurate |
| Cancel Booking | P1 | Customer can cancel booking |
| Reschedule Booking | P2 | Customer can reschedule |
| No-Show Handling | P1 | No-show policy enforced correctly |

### 4. Payment Flow Tests
**File:** `test/integration/payment_flow_test.dart`

| Test Case | Priority | Description |
|-----------|----------|-------------|
| Add Payment Method | P0 | Stripe card element works |
| Payment Processing | P0 | Payment completes successfully |
| Payment Failure | P0 | Failed payment shows error |
| Refund Processing | P1 | Refunds reflect in app |
| Tip Addition | P1 | Customer can add tip |
| Payment History | P2 | Past payments viewable |
| Stripe Connect Payout | P1 | Barber sees earnings correctly |

### 5. Notification Tests
**File:** `test/integration/notification_test.dart`

| Test Case | Priority | Description |
|-----------|----------|-------------|
| OneSignal Registration | P0 | Device registers for push |
| Booking Confirmation Push | P0 | Push sent on booking |
| Reminder Notifications | P1 | 24hr/1hr reminders sent |
| Local Notification Display | P1 | Local notifications work |
| Deep Link from Push | P1 | Push opens correct screen |
| Notification Preferences | P2 | User can manage preferences |

## Test Execution

### Running All Integration Tests
```bash
flutter test test/integration/
```

### Running Specific Test Suite
```bash
flutter test test/integration/auth_flow_test.dart
flutter test test/integration/booking_flow_test.dart
flutter test test/integration/payment_flow_test.dart
```

### Running with Coverage
```bash
flutter test --coverage test/integration/
genhtml coverage/lcov.info -o coverage/html
```

### CI Pipeline Execution
Integration tests run automatically on:
- Every pull request to `main` or `develop`
- Every push to `main` branch
- Nightly scheduled runs at 2 AM UTC

See `.github/workflows/mobile_pr.yml` for configuration.

## Test Data Management

### Test Users
| Role | Email | Password | Notes |
|------|-------|----------|-------|
| Customer | test.customer@direct-cuts.com | Test123! | Standard customer |
| Barber | test.barber@direct-cuts.com | Test123! | Verified barber |
| Admin | test.admin@direct-cuts.com | Test123! | Admin access |

### Test Payment Cards (Stripe Test Mode)
| Card | Number | Result |
|------|--------|--------|
| Success | 4242424242424242 | Payment succeeds |
| Decline | 4000000000000002 | Payment declined |
| Auth Required | 4000002500003155 | 3DS required |

## Smoke Test Checklist

Before every release, manually verify:

- [ ] App launches without crash
- [ ] Login works for existing user
- [ ] Map loads and shows barbers
- [ ] Can view barber profile
- [ ] Can select service and time
- [ ] Payment form loads
- [ ] Push notifications received
- [ ] Logout works cleanly

## Performance Benchmarks

| Metric | Target | Measurement |
|--------|--------|-------------|
| App Cold Start | < 3s | Time to interactive |
| Map Load | < 2s | Markers visible |
| Search Results | < 1s | Results displayed |
| Payment Processing | < 5s | Confirmation shown |
| Image Load | < 1s | Barber photos loaded |

## Bug Severity Classification

- **P0 (Critical):** App crash, payment failure, security issue
- **P1 (High):** Core flow blocked, data loss, major UX issue
- **P2 (Medium):** Feature degraded, workaround exists
- **P3 (Low):** Cosmetic issues, minor inconvenience

## Test Coverage Goals

| Category | Current | Target |
|----------|---------|--------|
| Integration Tests | 80% | 85% |
| Unit Tests | 70% | 80% |
| Widget Tests | 60% | 75% |

## Appendix: Test File Structure

```
test/
├── integration/
│   ├── auth_flow_test.dart
│   ├── barber_search_test.dart
│   ├── booking_flow_test.dart
│   ├── notification_test.dart
│   └── payment_flow_test.dart
├── unit/
│   └── (unit test files)
└── widget/
    └── (widget test files)
```

## Contact

- **QA Lead:** TBD
- **Test Issues:** File in GitHub Issues with `qa` label
- **Support:** support@direct-cuts.com
