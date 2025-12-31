# Direct Cuts Support Playbook

**Version:** 1.0.0
**Last Updated:** 2025-12-31
**Support Email:** support@direct-cuts.com
**Legal Entity:** Direct Cuts LLC

---

## Support Philosophy

### Core Principles

1. **Speed Over Perfection** - A quick helpful response beats a perfect slow one
2. **Assume Good Intent** - Users are frustrated, not malicious (until proven otherwise)
3. **Empower Self-Service** - Every ticket is a documentation opportunity
4. **Protect Both Sides** - Customers and barbers are both our users
5. **Document Everything** - If it's not written down, it didn't happen

### The Solo Founder Reality

You're one person. These processes are designed for:
- Maximum efficiency with minimum time investment
- 80/20 rule: Handle 80% of issues with pre-written macros
- Clear escalation triggers so you know when to stop and think
- Batch processing to protect your focus time

### Daily Support Routine (30-45 min total)

**Morning Block (15-20 min) - 9:00 AM**
1. Check Stripe Dashboard for overnight chargebacks/disputes (5 min)
2. Scan support inbox, flag P0/P1 issues (5 min)
3. Respond to P0 issues immediately (5-10 min)
4. Batch respond to P2 issues with macros (5 min)

**Evening Block (15-20 min) - 6:00 PM**
1. Follow up on morning P1 issues (5 min)
2. Process remaining P2 tickets (10 min)
3. Check app store reviews (5 min)
4. Update any documentation if patterns emerge

**Weekly Review (Friday, 30 min)**
1. Review ticket volume by category
2. Identify if any new macros needed
3. Check chargeback ratio in Stripe
4. Review any pending disputes
5. Update this playbook if needed

---

## Ticket Categories

### P0 - Critical (Respond within 2 hours)

| Category | Description | Examples |
|----------|-------------|----------|
| **SAFETY** | Physical safety concerns | Threats, harassment, assault allegations |
| **FRAUD-ACTIVE** | Ongoing fraud/theft | Stolen payment method, account takeover |
| **SERVICE-DOWN** | App completely unusable | Login broken for all users, payments failing globally |
| **CHARGEBACK** | Active Stripe dispute | New chargeback notification |

**P0 Triggers:**
- Keywords: "unsafe", "threatened", "stolen", "fraud", "police", "lawsuit"
- Stripe webhook: `dispute.created`
- Multiple users reporting same issue

### P1 - High (Respond within 4 hours, resolve within 24 hours)

| Category | Description | Examples |
|----------|-------------|----------|
| **PAYMENT-FAILED** | Individual payment issue | Charged but booking failed, double charge |
| **NO-SHOW-BARBER** | Barber didn't show up | Customer waiting, no communication |
| **ACCOUNT-LOCKED** | Can't access account | Login issues, verification stuck |
| **VERIFICATION-FAIL** | Identity verification rejected | Barber can't complete onboarding |

### P2 - Normal (Respond within 24 hours, resolve within 72 hours)

| Category | Description | Examples |
|----------|-------------|----------|
| **NO-SHOW-CUSTOMER** | Customer didn't show | Barber waiting, wants compensation |
| **BOOKING-HELP** | Booking assistance | How to cancel, reschedule questions |
| **SERVICE-QUALITY** | Unhappy with haircut | Wants refund for bad service |
| **FEATURE-REQUEST** | Product feedback | "You should add X feature" |
| **REVIEW-DISPUTE** | Challenging a review | Barber wants review removed |
| **STRIPE-SETUP** | Barber payment setup | Can't connect Stripe, payout questions |
| **APP-BUG** | Non-critical bugs | UI glitch, notification not received |
| **GENERAL** | Everything else | How-to questions, general inquiries |

---

## Triage Decision Tree

```
New Ticket Arrives
        |
        v
Contains safety keywords? ----YES----> P0: SAFETY (Escalate immediately)
        |
        NO
        v
Mentions fraud/stolen? --------YES----> P0: FRAUD-ACTIVE (Lock account, investigate)
        |
        NO
        v
Payment/money issue? ----------YES----> Is it a Stripe dispute?
        |                                      |
        NO                              YES: P0: CHARGEBACK
        |                                      |
        v                               NO: P1: PAYMENT-FAILED
Barber no-show? ---------------YES----> P1: NO-SHOW-BARBER
        |
        NO
        v
Account access issue? ---------YES----> P1: ACCOUNT-LOCKED
        |
        NO
        v
Identity verification? --------YES----> P1: VERIFICATION-FAIL
        |
        NO
        v
Customer no-show? -------------YES----> P2: NO-SHOW-CUSTOMER
        |
        NO
        v
Service quality complaint? ----YES----> P2: SERVICE-QUALITY
        |
        NO
        v
Assign to appropriate P2 category
```

---

## SLA Targets

### Response Time (Time to first human response)

| Priority | Target | Maximum |
|----------|--------|---------|
| P0 | 30 minutes | 2 hours |
| P1 | 2 hours | 4 hours |
| P2 | 12 hours | 24 hours |

### Resolution Time (Time to close ticket)

| Priority | Target | Maximum |
|----------|--------|---------|
| P0 | 4 hours | 24 hours |
| P1 | 24 hours | 48 hours |
| P2 | 48 hours | 72 hours |

### Chargeback Response

| Milestone | Target |
|-----------|--------|
| Evidence submission | Within 3 days of dispute |
| Customer contact | Within 24 hours of dispute |
| Resolution attempt | Within 7 days |

---

## Escalation Matrix

### When to Pause and Think

Stop using macros and carefully consider when:
- Legal action threatened
- Media/press involvement mentioned
- Physical safety at risk
- Potential viral social media situation
- Pattern of same issue from multiple users
- You're unsure if refund is appropriate

### Escalation Contacts

| Situation | Action | Contact |
|-----------|--------|---------|
| Legal threat | Document, don't engage on substance | Lawyer (get one on retainer) |
| Safety/violence | Contact authorities if needed | Local police non-emergency |
| Stripe escalation | Stripe support ticket | Stripe Dashboard > Support |
| Identity verification issues | Persona support | Persona Dashboard |
| App store emergency | Priority response | App Store Connect / Play Console |

### Account Actions Authority

| Action | Self-Approve | Requires Review |
|--------|--------------|-----------------|
| Refund < $50 | Yes | No |
| Refund $50-200 | Yes, document reason | No |
| Refund > $200 | No | Sleep on it, review evidence |
| Suspend customer | Yes, document reason | No |
| Suspend barber | Document heavily | Review before permanent |
| Permanent ban | No | 24-hour wait, review evidence |

---

## Tools and Access

### Required Dashboard Access

1. **Stripe Dashboard** (payments.stripe.com)
   - View transactions
   - Process refunds
   - Respond to disputes
   - View Connected Accounts (barbers)

2. **Supabase Dashboard** (app.supabase.com)
   - View user profiles
   - Check booking records
   - Review messages
   - Audit identity verification status

3. **OneSignal Dashboard** (onesignal.com)
   - Send targeted notifications
   - Check delivery status

4. **App Store Connect** (appstoreconnect.apple.com)
   - Respond to reviews
   - View crash reports

5. **Google Play Console** (play.google.com/console)
   - Respond to reviews
   - View crash reports

### Useful Stripe Commands

**Find a transaction:**
```
Stripe Dashboard > Payments > Search by email or amount
```

**Issue a refund:**
```
Stripe Dashboard > Payments > Select payment > Refund > Enter amount > Refund
```

**View Connected Account (barber):**
```
Stripe Dashboard > Connect > Accounts > Search
```

**Check dispute status:**
```
Stripe Dashboard > Disputes > [Select dispute]
```

### Useful Supabase Queries

**Find user by email:**
```sql
SELECT * FROM profiles WHERE email ILIKE '%searchterm%';
```

**Find bookings for user:**
```sql
SELECT * FROM bookings WHERE customer_id = 'user-uuid' ORDER BY created_at DESC;
```

**Check barber verification status:**
```sql
SELECT id, email, verification_status, created_at
FROM barber_profiles
WHERE email ILIKE '%searchterm%';
```

---

## Communication Guidelines

### Tone Standards

- **Professional but warm** - Not corporate, not too casual
- **Solution-focused** - Lead with what you CAN do
- **Empathetic** - Acknowledge frustration before solving
- **Clear** - Simple words, short sentences
- **Honest** - Don't promise what you can't deliver

### Words to Use

- "I understand..."
- "Let me help you with..."
- "Here's what I can do..."
- "I appreciate you reaching out..."
- "Thank you for your patience..."

### Words to Avoid

- "Unfortunately..." (sounds like bad news coming)
- "Policy says..." (sounds rigid)
- "You should have..." (blaming)
- "I can't..." (lead with what you CAN do)
- "Background check" (we do IDENTITY VERIFICATION)

### Response Structure

```
1. Acknowledge (1 sentence)
   "Hi [Name], thank you for reaching out about [issue]."

2. Empathize if needed (1 sentence)
   "I understand how frustrating it must be when..."

3. Solution/Action (clear steps)
   "Here's what I've done / what you can do:
   1. Step one
   2. Step two"

4. Set expectations (1 sentence)
   "You should see [outcome] within [timeframe]."

5. Close warmly (1 sentence)
   "Let me know if you have any other questions!"

[Your name]
Direct Cuts Support
```

---

## Metrics to Track (Weekly)

### Volume Metrics
- Total tickets received
- Tickets by category
- Tickets by user type (customer vs barber)

### Performance Metrics
- First response time (average)
- Resolution time (average)
- One-touch resolution rate (% solved in first response)

### Business Health Metrics
- Refund rate (% of transactions refunded)
- Chargeback rate (CRITICAL: Keep under 0.75%)
- Customer satisfaction (if surveying)
- Repeat issue rate (same user, same issue)

### Red Flags (Investigate Immediately)
- Chargeback rate > 0.5%
- Same issue from 5+ users in 24 hours
- Refund rate > 5% of transactions
- Average response time > 24 hours

---

## Document Library

| Document | Purpose | Location |
|----------|---------|----------|
| MACROS.md | Response templates | ops/support/MACROS.md |
| REFUND_DISPUTE_FLOW.md | Refund/chargeback handling | ops/support/REFUND_DISPUTE_FLOW.md |
| NO_SHOW_HANDLING.md | No-show procedures | ops/support/NO_SHOW_HANDLING.md |
| SAFETY_ESCALATION.md | Safety incident response | ops/support/SAFETY_ESCALATION.md |

---

## Quick Reference Card

**P0 (2hr response): SAFETY, FRAUD, SERVICE-DOWN, CHARGEBACK**
- Drop everything, respond immediately
- Document heavily
- Consider account suspension

**P1 (4hr response): PAYMENT-FAILED, NO-SHOW-BARBER, ACCOUNT-LOCKED, VERIFICATION-FAIL**
- Respond same business day
- Most have macros
- Resolve within 24 hours

**P2 (24hr response): Everything else**
- Batch process twice daily
- Use macros liberally
- Resolve within 72 hours

**Refund Authority:**
- Under $50: Auto-approve for customer goodwill
- $50-200: Approve with documentation
- Over $200: Sleep on it, review evidence

**Chargeback Rate Warning:**
- Green: Under 0.5%
- Yellow: 0.5-0.75%
- Red: Over 0.75% (Stripe may take action)

---

*Remember: Every support interaction is a chance to turn a frustrated user into an advocate. Handle with care.*
