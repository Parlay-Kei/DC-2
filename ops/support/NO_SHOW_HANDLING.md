# No-Show Handling Procedures

**Version:** 1.0.0
**Last Updated:** 2025-12-31

---

## Overview

No-shows hurt everyone:
- **Customer no-shows** waste barbers' time and income
- **Barber no-shows** ruin customers' plans and damage trust

This document defines fair, consistent processes for both scenarios.

---

## Customer No-Show Process

### Definition

A customer no-show occurs when:
- Customer does not arrive at scheduled time
- Customer is unreachable after 15 minutes past appointment time
- Customer cancels less than 1 hour before (treated as no-show)

### Timeline for Barbers

| Time | Action |
|------|--------|
| Appointment time | Barber arrives/is ready |
| +5 minutes | Barber sends in-app message: "Hi! I'm here for your appointment" |
| +10 minutes | Barber attempts call/text through app |
| +15 minutes | Barber can mark as no-show in app |

### No-Show Fee Structure

**Standard No-Show Fee:** 50% of booked service price

| Service Price | No-Show Fee to Barber | Customer Charged |
|---------------|----------------------|------------------|
| $20 | $10 | $10 |
| $40 | $20 | $20 |
| $60 | $30 | $30 |
| $100 | $50 | $50 |

**Fee Distribution:**
- 100% of no-show fee goes to barber (platform takes no cut on no-shows)
- This is pre-authorized when customer books

### How to Process Customer No-Show

**Step 1: Barber Reports No-Show**

Barber marks appointment as no-show in app, which:
- Sends notification to customer
- Creates support ticket for review
- Holds payment pending confirmation

**Step 2: Verify the No-Show (Within 24 Hours)**

Before processing fee, verify:
- [ ] Barber was at correct location (check-in data)
- [ ] Barber arrived on time or early
- [ ] Barber attempted to contact customer (check messages)
- [ ] Customer didn't respond or cancel

**Step 3: Process the Fee**

If verified:
1. In Supabase, update booking status to `no_show_customer`
2. No-show fee is captured from customer's payment method
3. Fee is added to barber's payout
4. Customer receives notification with fee explanation

**Step 4: Update Customer Record**

Track no-shows on customer profile:
- First no-show: Warning email
- Second no-show: Account flagged
- Third no-show: Require prepayment for future bookings
- Fourth no-show: Account suspension review

### Customer No-Show Email Templates

**First No-Show:**
```
Subject: Missed Appointment - Direct Cuts

Hi [NAME],

We noticed you missed your appointment with [BARBER] on [DATE].

Your barber set aside time specifically for you, so a no-show fee
of $[AMOUNT] has been charged to your payment method on file.

We understand things come up! To avoid future fees:
- Cancel at least 12 hours in advance for a 50% refund
- Cancel at least 24 hours in advance for a full refund
- Or reschedule instead of canceling

Questions? Reply to this email.

Best,
Direct Cuts Support
```

**Second No-Show:**
```
Subject: Second Missed Appointment - Direct Cuts

Hi [NAME],

This is your second missed appointment on Direct Cuts.

We understand life happens, but repeated no-shows affect our barbers
who depend on appointments for their income.

A $[AMOUNT] no-show fee has been charged.

Please note: Another no-show may result in your account requiring
prepayment for future bookings.

Best,
Direct Cuts Support
```

**Third No-Show - Prepayment Required:**
```
Subject: Account Update - Prepayment Required

Hi [NAME],

Due to multiple missed appointments, your Direct Cuts account now
requires full prepayment at time of booking.

This helps protect our barbers while still allowing you to use
the platform.

If you believe this was applied in error, please reply to this email.

Best,
Direct Cuts Support
```

### Disputing a Customer No-Show Fee

If customer disputes:

**Valid Dispute Reasons:**
- Emergency (medical, family) - with some evidence
- Barber was actually late/no-show
- App error prevented cancellation
- Previous communication about cancellation

**Process:**
1. Review in-app messages
2. Check barber's check-in data
3. Ask customer for any supporting information
4. Make decision within 24 hours

**If Dispute Upheld:**
- Refund no-show fee to customer
- Still pay barber (we absorb the cost this time)
- Document the exception

---

## Barber No-Show Process

### Definition

A barber no-show occurs when:
- Barber does not arrive within 15 minutes of scheduled time
- Barber is unreachable after customer attempts contact
- Barber cancels less than 2 hours before appointment

### This is Unacceptable

Barber no-shows are treated much more seriously than customer no-shows because:
- Customers are paying for a service
- It severely damages platform trust
- It's unprofessional

### Timeline for Customers

| Time | Action |
|------|--------|
| Appointment time | Customer at location |
| +5 minutes | Customer can message barber through app |
| +10 minutes | Customer receives prompt: "Is your barber running late?" |
| +15 minutes | Customer can report barber no-show |

### Immediate Response to Barber No-Show Report

**Within 15 Minutes of Report:**

1. **Attempt to Reach Barber**
   - In-app message
   - Push notification
   - SMS if available

2. **Respond to Customer**
   Use MACRO-C08 or:
   ```
   Hi [NAME],

   I'm so sorry - I'm trying to reach [BARBER] now.
   Give me 10 minutes to get you an update.

   If they can't make it, I'll process your full refund immediately.
   ```

3. **If Barber Unreachable After 10 Minutes**
   - Process full refund
   - Add credit to customer account
   - Mark as barber no-show

### Customer Compensation for Barber No-Show

| Item | Amount |
|------|--------|
| Full refund | 100% of booking |
| Goodwill credit | $10-25 depending on service price |
| Priority rebooking | Offer to find alternative barber |

### Barber Consequences for No-Show

**First No-Show:**
- Warning email sent
- Documented on profile
- No payout for that booking (obviously)

**Second No-Show (within 90 days):**
- Account temporarily suspended (24-48 hours)
- Required to acknowledge policies before reactivation
- Profile may be demoted in search results

**Third No-Show (within 90 days):**
- Extended suspension (1 week)
- Video call review of situation
- Final warning

**Fourth No-Show or Pattern:**
- Permanent removal from platform

### Barber No-Show Notification Templates

**First No-Show Warning:**
```
Subject: Missed Appointment - Action Required

Hi [NAME],

A customer reported that you didn't show up for your appointment
on [DATE] at [TIME].

Customer: [CUSTOMER NAME]
Service: [SERVICE]
Location: [LOCATION]

No-shows damage trust in Direct Cuts and hurt your reputation.
This is documented on your account.

If there were extenuating circumstances, please reply with details.

Going forward:
- If you can't make an appointment, cancel ASAP (minimum 2 hours before)
- Communicate with customers if running late
- Set realistic availability to avoid overbooking

This is a warning. Future no-shows will result in account suspension.

Best,
Direct Cuts Support
```

**Second No-Show - Suspension:**
```
Subject: Account Suspended - No-Show Policy Violation

Hi [NAME],

Your account has been temporarily suspended due to a second no-show
within 90 days.

Previous: [DATE]
Today: [DATE]

Suspension period: 48 hours
Your account will be automatically reactivated on [DATE].

When reactivated, you'll need to acknowledge our reliability policies.
Another no-show within 90 days will result in a longer suspension.

We want you to succeed on Direct Cuts, but we must protect customer trust.

Best,
Direct Cuts Support
```

### Exception: Legitimate Emergencies

If a barber misses due to genuine emergency (accident, medical, family death):

1. Request brief documentation (don't be invasive)
2. Waive the strike against their account
3. Help reschedule affected customers
4. Send customer extra goodwill credit
5. Document the exception

**Examples of Valid Emergencies:**
- Medical emergency (self or immediate family)
- Car accident
- Death in family
- Natural disaster

**Not Valid Emergencies:**
- Overslept
- Double-booked
- "Forgot"
- Car trouble (preventable with buffer time)

---

## Repeat Offender Handling

### Tracking Framework

Maintain a simple tracker:

| User | Type | No-Show Count (90 days) | Status | Notes |
|------|------|-------------------------|--------|-------|
| customer@email.com | Customer | 2 | Flagged | Prepay next |
| barber@email.com | Barber | 1 | Warning | 12/15 |

### Escalation Thresholds

**Customers:**
- 1 no-show: Email warning
- 2 no-shows: Account flagged, email warning
- 3 no-shows: Prepayment required
- 4 no-shows: Manual review, possible suspension

**Barbers:**
- 1 no-show: Warning, documented
- 2 no-shows: 48-hour suspension
- 3 no-shows: 1-week suspension
- 4 no-shows: Permanent removal review

### 90-Day Rolling Window

No-shows "expire" after 90 days:
- Customer with 2 no-shows in January starts fresh in April
- This rewards improved behavior
- Exceptions: Severe patterns may warrant permanent notes

---

## Mobile vs. In-Shop Appointment Considerations

### Mobile Appointments (Barber Comes to Customer)

**Additional Verification:**
- Barber GPS check-in at customer location
- Customer receives "barber is on the way" notification
- Customer receives "barber has arrived" notification

**If Customer Claims No-Show:**
- Check GPS data first
- If barber was there, it's not a barber no-show
- If barber wasn't there, process as barber no-show

**If Barber Claims No-Show:**
- Check if customer was at provided location
- Verify barber attempted contact
- If customer genuinely not there, process as customer no-show

### In-Shop Appointments

**Verification:**
- Barber marks appointment started/completed
- Less GPS verification possible
- Rely more on communication records

---

## Dispute Resolution: Conflicting Claims

Sometimes both parties claim the other no-showed.

### Investigation Process

1. **Gather Evidence**
   - All in-app messages
   - GPS/check-in data
   - Any photos
   - Timing of who reported first

2. **Look for Patterns**
   - Has this customer disputed before?
   - Has this barber had complaints before?
   - Any red flags in communication?

3. **Default Positions**
   - If evidence unclear: Refund customer, don't penalize barber
   - If pattern suggests bad actor: Act accordingly
   - Document heavily for future reference

4. **Resolution Timeline**
   - Acknowledge within 4 hours
   - Decision within 24 hours
   - Final answer within 48 hours

### Communication When Unclear

```
Hi [NAME],

After reviewing the situation, I wasn't able to conclusively
determine what happened with your appointment on [DATE].

Here's what I've done:
- [For customer: Processed a full refund]
- [For barber: No strike added to your account]

I know this may not feel fully resolved, but without clear evidence
either way, I want to be fair to both parties.

Going forward, [suggest prevention: communication, confirming address, etc.]

Best,
Direct Cuts Support
```

---

## Prevention Features

### For Customers

- **Booking reminders:** 24 hours and 1 hour before
- **Easy cancellation:** Clear cancel button in app
- **Calendar integration:** Add to phone calendar
- **Confirmation required:** Tap to confirm 24 hours before (future feature)

### For Barbers

- **Calendar sync:** Prevent double-booking
- **Route planning:** Show travel time for mobile appointments
- **Reminder notifications:** Alert for upcoming appointments
- **Availability buffer:** Auto-block time between mobile appointments

---

## Quick Reference

### Customer No-Show
- Wait 15 minutes before marking
- 50% fee (all to barber)
- Track repeat offenders
- 4th offense = suspension review

### Barber No-Show
- Full refund + credit to customer
- 1st = warning, 2nd = 48hr suspension
- 3rd = 1 week, 4th = permanent review
- Genuine emergencies exempted

### When in Doubt
- Refund the customer
- Don't penalize barber without evidence
- Document everything
- Patterns matter more than single incidents

---

*Fair enforcement builds trust with both customers and barbers. Be consistent but compassionate.*
