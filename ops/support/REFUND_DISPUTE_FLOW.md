# Refund and Dispute Handling Flow

**Version:** 1.0.0
**Last Updated:** 2025-12-31
**Payment Processor:** Stripe Connect

---

## Overview

This document covers:
1. When to issue refunds
2. How to process refunds in Stripe
3. Chargeback response procedures
4. Evidence collection for disputes
5. Timeline expectations

**Critical Metric:** Keep chargeback rate under 0.75% of transactions. Above this, Stripe may take action including account termination.

---

## Refund Eligibility Matrix

### Automatic Approval (Process Immediately)

| Situation | Refund Amount | Notes |
|-----------|---------------|-------|
| Barber no-show | 100% | Plus credit for inconvenience |
| Charged but no booking created | 100% | System error |
| Double charge | 100% of duplicate | Keep original charge |
| Customer cancels 24+ hours before | 100% | Per cancellation policy |
| Barber cancels appointment | 100% | Not customer's fault |

### Approval Required (Review Before Processing)

| Situation | Default Refund | When to Deviate |
|-----------|----------------|-----------------|
| Customer cancels 12-24 hours before | 50% | 100% if first booking ever |
| Customer cancels <12 hours before | 0% | 50% for exceptional circumstances |
| Service quality complaint | Case-by-case | See quality review process below |
| Customer claims barber was late | 25-50% | If verified, more if significantly late |
| Customer and barber disagree | Case-by-case | Review messages, evidence |

### Refund Denied (Do Not Process)

| Situation | Why | What to Do Instead |
|-----------|-----|---------------------|
| Customer no-show | Customer's fault | No-show fee to barber |
| "Changed my mind" after service | Service was delivered | Offer future credit if goodwill |
| Fishing for free service | Fraud pattern | Document and monitor |
| Review manipulation attempt | "Refund or I post bad review" | Do not negotiate |

---

## Refund Processing: Step-by-Step

### Step 1: Verify the Charge

1. Go to **Stripe Dashboard** (dashboard.stripe.com)
2. Navigate to **Payments**
3. Search by:
   - Customer email
   - Amount
   - Date
   - Payment ID (if provided)
4. Click on the payment to view details

**Verify:**
- Amount matches customer claim
- Date matches
- Payment status is "Succeeded"
- Not already refunded

### Step 2: Document the Reason

Before processing, note in your support ticket:
- Payment ID from Stripe
- Amount to refund (full or partial)
- Reason for refund
- Who approved (if over $50)

### Step 3: Process the Refund

**For Full Refund:**
1. Click on the payment in Stripe
2. Click **Refund** button (top right)
3. Leave amount as full payment amount
4. Select reason from dropdown:
   - `duplicate` - Double charge
   - `fraudulent` - Fraud/unauthorized
   - `requested_by_customer` - Customer requested
5. Add internal note with ticket number
6. Click **Refund**

**For Partial Refund:**
1. Click on the payment in Stripe
2. Click **Refund** button
3. Change amount to partial refund amount
4. Select reason and add note
5. Click **Refund**

### Step 4: Notify the Customer

Use appropriate macro from MACROS.md and include:
- Confirmation refund was processed
- Amount refunded
- Expected timeline (5-10 business days)
- Ticket number for reference

### Step 5: Handle Barber Impact

When you refund a customer, the barber's payout is affected.

**If refund is NOT barber's fault** (system error, your mistake):
- Process refund
- Manually compensate barber via Stripe (if already paid out)
- Or adjust their next payout

**If refund IS related to barber** (no-show, quality issue):
- Refund comes from what would have been paid to barber
- Document on barber's record
- If pattern emerges, review barber status

### Stripe Refund Impact on Connected Accounts

```
Original Flow:
Customer pays $100
→ Platform fee: $15 (kept by Direct Cuts)
→ Barber receives: $85

Full Refund Flow:
Customer refunded: $100
→ Platform fee reversed: $15
→ Barber payout reversed: $85

If Barber Already Paid:
→ Creates negative balance on barber's account
→ Deducted from next earnings
→ Or you eat the loss (your call)
```

---

## Chargeback (Dispute) Response Playbook

### Understanding Chargebacks

A chargeback occurs when a customer disputes a charge with their bank/card company instead of contacting you. Stripe notifies you and you have a limited time to respond.

**Chargeback Timeline:**
- Day 0: Dispute filed, Stripe notifies you
- Day 0-7: You gather evidence and respond
- Day 7-21: Stripe submits evidence to card network
- Day 21-90: Card network reviews and decides
- Day 90+: Decision issued (final)

**Chargeback Costs:**
- Disputed amount is held by Stripe
- $15 dispute fee (non-refundable if you lose)
- If you win: Amount returned, fee refunded
- If you lose: Amount + fee gone

### When You Receive a Chargeback

**Immediate Actions (Within 2 Hours):**

1. **Check Stripe Dashboard**
   - Go to Disputes
   - Find the new dispute
   - Note the reason code and deadline

2. **Review the Transaction**
   - Find original booking in Supabase
   - Pull customer communication history
   - Check if customer contacted support first

3. **Contact the Customer**
   ```
   Hi [NAME],

   We received notice that you disputed your charge of $[AMOUNT] from [DATE]
   with your bank.

   If there was an issue with your booking, I wish you had contacted us first -
   we're always happy to help and can usually resolve things faster than the
   dispute process.

   Could you let me know what happened? If we can resolve this directly,
   you can ask your bank to withdraw the dispute, which is faster for everyone.

   Best,
   [YOUR NAME]
   ```

4. **Assess: Fight or Accept?**

### When to Accept the Dispute (Don't Fight)

- You already approved a refund but didn't process it
- Customer is clearly right and you'd have refunded anyway
- Evidence strongly favors customer
- Amount is very small (<$20) and evidence weak

**To accept:** In Stripe > Disputes > Select dispute > Accept

### When to Fight the Dispute

- Service was clearly delivered
- You have strong evidence
- Customer is attempting fraud
- Pattern of abuse from this customer

### Evidence Collection Checklist

Gather ALL applicable evidence:

**Transaction Evidence:**
- [ ] Payment confirmation/receipt
- [ ] Booking confirmation sent to customer
- [ ] Customer account showing completed booking

**Communication Evidence:**
- [ ] In-app messages between customer and barber
- [ ] Support emails with customer
- [ ] Booking reminder notifications sent

**Service Delivery Evidence:**
- [ ] GPS/location data showing barber at location
- [ ] Barber check-in confirmation
- [ ] Time stamps of service start/end
- [ ] Photos if barber took any

**Terms & Policy Evidence:**
- [ ] Screenshot of terms of service customer agreed to
- [ ] Cancellation policy customer saw during booking
- [ ] Refund policy

**Customer History:**
- [ ] Previous successful bookings
- [ ] Previous disputes
- [ ] Previous refund requests

### Submitting Dispute Response in Stripe

1. Go to **Stripe Dashboard > Disputes**
2. Click on the dispute
3. Click **Submit Evidence**
4. Fill in the form:

**Product Description:**
```
Mobile barber booking service. Customer [NAME] booked a [SERVICE]
appointment with barber [BARBER NAME] on [DATE] at [LOCATION].
```

**Customer Signature/Proof:**
Upload booking confirmation screenshot showing customer agreed to service

**Service Date:**
Enter the appointment date

**Compelling Evidence:**
Write a clear narrative:
```
On [DATE], customer [NAME] booked a [SERVICE] through our platform
for $[AMOUNT]. The booking was confirmed via email and push notification
(evidence attached).

The barber [BARBER NAME] arrived at the scheduled location at [TIME]
and performed the service. The appointment was marked complete at [TIME].

[If applicable: Prior to the dispute, the customer did not contact
our support team about any issues with the service.]

[If applicable: The customer has successfully completed [X] previous
bookings on our platform without issue.]

The service was delivered as described, and we respectfully request
this dispute be found in our favor.
```

5. Upload all evidence files
6. Click **Submit**

### Chargeback Reason Codes & Responses

**Reason: "Fraudulent" / "I didn't authorize this"**
Evidence needed:
- Proof customer created account
- Email/phone verification records
- IP address of booking (if available)
- Previous successful transactions
- AVS/CVV match from payment

**Reason: "Product/Service Not Received"**
Evidence needed:
- Booking confirmation
- Barber check-in/location data
- Communication showing service discussed
- Any photos from appointment

**Reason: "Not as Described"**
Evidence needed:
- Service description from booking
- Price shown at booking time
- Any pre-service communication about expectations
- Your refund/quality policy

**Reason: "Duplicate Transaction"**
Evidence needed:
- Show each charge is for different service/date
- If actually duplicate, accept and refund

**Reason: "Credit Not Processed"**
Evidence needed:
- If you promised refund, show it was processed
- If you didn't promise refund, show why not eligible
- Communication history

---

## Chargeback Prevention Strategies

### Before Booking

- Clear service descriptions with photos
- Transparent pricing (no hidden fees)
- Easy-to-find cancellation policy
- Require email verification

### During Booking

- Confirmation email immediately
- Push notification of booking
- Reminder 24 hours before
- Reminder 1 hour before

### After Service

- Completion notification
- Receipt emailed
- Easy way to contact support
- Proactive check-in for first-time customers

### Ongoing

- Respond to support requests quickly
- Process legitimate refunds fast (before they dispute)
- Monitor for fraud patterns
- Train barbers on service quality

---

## Fraud Detection Red Flags

Watch for these patterns:

**Customer Red Flags:**
- Multiple accounts with same device/IP
- Disputes on first booking
- Pattern of disputing across platforms
- Mismatched billing/service address
- Brand new account with high-value booking

**Transaction Red Flags:**
- Card from different country than service location
- Multiple failed payment attempts
- Different name on card vs. account
- Booking made very close to appointment time

**Service Red Flags:**
- Customer immediately claims no-show without contacting barber
- Story doesn't match barber's account
- Customer unresponsive when you try to resolve

### When You Suspect Fraud

1. Document everything immediately
2. If booking hasn't happened: Cancel and refund proactively
3. If booking completed: Investigate before refunding
4. If pattern of fraud: Suspend customer account
5. Consider reporting to Stripe's Radar

---

## Refund/Dispute Metrics to Track

### Weekly Dashboard

| Metric | Target | Red Flag |
|--------|--------|----------|
| Refund rate (% of transactions) | <3% | >5% |
| Chargeback rate | <0.5% | >0.75% |
| Disputes won | >50% | <30% |
| Avg refund amount | Track trend | Sudden increase |
| Time to refund decision | <24 hours | >48 hours |

### Monthly Review

- Total refunds issued and amounts
- Refund reasons breakdown
- Chargebacks by reason code
- Win/loss ratio on disputes
- Repeat refund requesters
- Barber-specific refund rates

---

## Escalation Triggers

### Escalate to Legal When:

- Customer threatens lawsuit over dispute
- Chargeback involves >$500
- Pattern suggests organized fraud
- Customer claims injury/harm
- Dispute involves regulatory issues

### Escalate to Stripe Support When:

- Technical issue with refund processing
- Dispute evidence submission problems
- Connected account (barber) payment issues
- Chargeback rate approaching 0.75%

---

## Quick Reference

### Refund Timing After Request
- Auto-approve situations: Immediate (same hour)
- Review-required: Same business day
- Complex cases: 24-48 hours max

### Chargeback Response Deadline
- Stripe gives: 7-21 days depending on card network
- Your target: Respond within 3 days (leaves buffer)

### Customer Communication Standard
- Acknowledge refund request: 4 hours
- Refund processed notification: Same day as processing
- Dispute contact attempt: Within 24 hours of notification

### Stripe Refund Time to Customer
- Customer sees refund: 5-10 business days
- Actual processing: Instant on Stripe's end
- Delay is customer's bank, not you

---

*This playbook should handle 95% of refund/dispute situations. When in doubt, err on the side of the customer for small amounts and the side of documentation for large amounts.*
