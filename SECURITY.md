# Security Policy

## Reporting a Vulnerability

The Direct Cuts team takes security seriously. We appreciate your efforts to responsibly disclose your findings.

### How to Report

**Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, please report them using one of these methods:

1. **GitHub Security Advisories (Preferred)**
   - Go to the [Security tab](https://github.com/Parlay-Kei/DC-2/security/advisories)
   - Click "Report a vulnerability"
   - Fill out the form with details

2. **Direct Contact**
   - Email security concerns to the repository owner
   - Use "SECURITY" in the subject line

### What to Include

Please include as much of the following information as possible:

- Type of vulnerability
- Full paths of source file(s) related to the vulnerability
- Location of the affected source code (tag/branch/commit or direct URL)
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if available)
- Impact of the vulnerability
- Any possible mitigations you've identified

### Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Fix Timeline**: Varies by severity (critical issues prioritized)

## Security Measures

### Current Protections

1. **Dependency Scanning**
   - Automated Dependabot security updates enabled
   - Weekly dependency audits via GitHub Actions
   - Vulnerability alerts active

2. **Code Scanning**
   - Secret scanning enabled
   - Trivy vulnerability scanner in CI/CD
   - Dependency review on pull requests

3. **Access Control**
   - Branch protection on main (can be enabled when needed)
   - Required code reviews for sensitive changes
   - Signed commits recommended

### Best Practices for Contributors

1. **Never Commit Secrets**
   - No API keys, passwords, or tokens
   - Use environment variables for sensitive data
   - Review `.gitignore` before committing

2. **Dependency Management**
   - Keep dependencies up to date
   - Review security advisories
   - Use specific versions, not wildcard ranges

3. **Input Validation**
   - Validate all user inputs
   - Sanitize data before database operations
   - Use parameterized queries

4. **Authentication & Authorization**
   - Use Supabase's built-in auth mechanisms
   - Implement proper RLS (Row Level Security) policies
   - Never trust client-side validation alone

5. **Data Protection**
   - Encrypt sensitive data at rest
   - Use HTTPS for all network communication
   - Implement proper session management

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 2.0.x   | :white_check_mark: |
| < 2.0   | :x:                |

## Known Security Considerations

### Flutter Secure Storage
- Keys stored in Android Keystore and iOS Keychain
- Biometric authentication available
- Secure enclave usage on supported devices

### Supabase Integration
- Row Level Security (RLS) enabled on all tables
- API keys stored securely using flutter_secure_storage
- JWT tokens managed by Supabase client

### Payment Processing (Stripe)
- PCI DSS compliance through Stripe
- No card data stored locally
- Tokenization for all payment methods

### Location Services
- Location permissions requested only when needed
- Location data not stored permanently
- User can revoke permissions at any time

## Security Updates

Security updates will be released as needed. Critical vulnerabilities will be patched immediately and released as hotfixes.

Users should:
- Keep the app updated to the latest version
- Enable automatic updates when possible
- Review release notes for security-related changes

## Disclosure Policy

- We will acknowledge your report within 48 hours
- We will provide a detailed response within 7 days
- We will notify you when the vulnerability is fixed
- We appreciate responsible disclosure and will credit researchers (if desired)

## Bug Bounty Program

Currently, we do not have a bug bounty program. However, we greatly appreciate security research and will publicly acknowledge researchers who report valid vulnerabilities (with their permission).

---

Last updated: 2025-12-07
