# Direct Cuts Support Macros

**Version:** 1.0.0
**Last Updated:** 2025-12-31

Use these templates for 80-90% of support tickets. Copy, personalize the [PLACEHOLDERS], and send.

---

## Table of Contents

1. [Customer - Booking Issues](#customer---booking-issues)
2. [Customer - Payment Issues](#customer---payment-issues)
3. [Customer - No-Show (Barber)](#customer---no-show-barber)
4. [Customer - Service Quality](#customer---service-quality)
5. [Customer - Account Issues](#customer---account-issues)
6. [Barber - Payment/Stripe Issues](#barber---paymentstripe-issues)
7. [Barber - Customer No-Show](#barber---customer-no-show)
8. [Barber - Identity Verification](#barber---identity-verification)
9. [Barber - Review Disputes](#barber---review-disputes)
10. [General - App Issues](#general---app-issues)
11. [Escalation Responses](#escalation-responses)

---

## Customer - Booking Issues

### MACRO-C01: Booking Confirmation Not Received

**When to use:** Customer says they booked but didn't get confirmation email/notification

**Template:**
```
Hi [NAME],

Thank you for reaching out! I can help you verify your booking.

I've checked our system and can confirm your appointment:
- Barber: [BARBER NAME]
- Date/Time: [DATE/TIME]
- Service: [SERVICE]
- Location: [LOCATION]

Your confirmation may have gone to spam - please check there and add support@direct-cuts.com to your contacts for future messages.

To view your bookings anytime, open the app and tap "My Bookings" at the bottom.

You're all set! Let me know if you have any other questions.

Best,
[YOUR NAME]
Direct Cuts Support
```

**Follow-up actions:**
- Verify booking exists in Supabase
- If no booking found, check if payment was captured
- If payment captured but no booking, escalate to P1

---

### MACRO-C02: How to Cancel Booking

**When to use:** Customer wants to cancel an appointment

**Template:**
```
Hi [NAME],

I can help you cancel your booking. Here's how to do it in the app:

1. Open Direct Cuts and tap "My Bookings"
2. Find your appointment with [BARBER NAME]
3. Tap the booking, then tap "Cancel Appointment"
4. Confirm your cancellation

Cancellation Policy Reminder:
- More than 24 hours before: Full refund
- 12-24 hours before: 50% refund
- Less than 12 hours: No refund (barber held that time for you)

Your appointment is on [DATE/TIME], so you're [within/outside] the full refund window.

Would you like me to cancel it for you, or would you prefer to reschedule instead?

Best,
[YOUR NAME]
Direct Cuts Support
```

**Follow-up actions:**
- If customer confirms cancel, process in system
- Apply appropriate refund per policy
- Notify barber of cancellation

---

### MACRO-C03: How to Reschedule

**When to use:** Customer wants to change appointment time

**Template:**
```
Hi [NAME],

Happy to help you reschedule! Here's how:

1. Open Direct Cuts and tap "My Bookings"
2. Tap your appointment with [BARBER NAME]
3. Tap "Reschedule"
4. Select a new date and time from their availability
5. Confirm the new time

The same cancellation policy applies if you're moving to a different day:
- More than 24 hours notice: No fee
- Less than 24 hours notice: May be subject to fees

Your barber [BARBER NAME] has availability on [SUGGEST TIMES IF VISIBLE].

Need me to reschedule it for you instead? Just let me know your preferred new time.

Best,
[YOUR NAME]
Direct Cuts Support
```

**Follow-up actions:**
- Check barber's availability before suggesting times
- If rescheduling for customer, update booking and notify barber

---

### MACRO-C04: No Barbers in My Area

**When to use:** Customer can't find any barbers nearby

**Template:**
```
Hi [NAME],

Thank you for trying Direct Cuts! I'm sorry you're not seeing barbers in your area yet.

We're actively growing our barber network, and your area is on our expansion list. Here's what I can do:

1. I've noted your location ([CITY/AREA]) to prioritize barber recruitment there
2. Try expanding your search radius in the app (tap the filter icon on the discovery screen)
3. Check back in a week or two - we're adding new barbers regularly

In the meantime, if you know any great barbers in your area, send them our way! Barbers can sign up at [BARBER SIGNUP URL].

I'll personally reach out when we have barbers near you. Thanks for your patience as we grow!

Best,
[YOUR NAME]
Direct Cuts Support
```

**Follow-up actions:**
- Log location request for business intelligence
- Add to "areas to expand" tracking list

---

## Customer - Payment Issues

### MACRO-C05: Charged But Booking Failed

**When to use:** Customer was charged but doesn't have a confirmed booking

**Template:**
```
Hi [NAME],

I sincerely apologize for this - that's definitely not the experience we want you to have.

I've located your charge for $[AMOUNT] on [DATE] and can confirm [the booking didn't complete properly / there was a system error].

I've processed a full refund of $[AMOUNT] to your original payment method. You should see it within 5-10 business days depending on your bank.

Would you like me to help you rebook your appointment with [BARBER NAME]? I can ensure it goes through smoothly this time.

Again, my apologies for the inconvenience. Please let me know how else I can help.

Best,
[YOUR NAME]
Direct Cuts Support
```

**Follow-up actions:**
- Verify charge in Stripe Dashboard
- Process refund immediately (Payments > Select > Refund)
- Check if this is a pattern (search for similar issues)
- If pattern, escalate to engineering

---

### MACRO-C06: Double Charged

**When to use:** Customer claims they were charged twice for one booking

**Template:**
```
Hi [NAME],

Thank you for letting me know - I want to get this sorted right away.

I've reviewed your payment history and found:
- Charge 1: $[AMOUNT] on [DATE/TIME] - [STATUS: successful/refunded/pending]
- Charge 2: $[AMOUNT] on [DATE/TIME] - [STATUS]

[IF DOUBLE CHARGE CONFIRMED:]
You're right, and I apologize for this error. I've refunded the duplicate charge of $[AMOUNT]. It should appear back on your statement within 5-10 business days.

[IF ONE IS AUTHORIZATION HOLD:]
The second charge you're seeing is likely a temporary authorization hold, not an actual charge. These typically drop off within 3-5 business days. If it's still there after 5 business days, please let me know and I'll investigate further.

Is there anything else I can help with?

Best,
[YOUR NAME]
Direct Cuts Support
```

**Follow-up actions:**
- Check Stripe for all charges from this customer
- Differentiate between actual charges and auth holds
- If duplicate confirmed, refund immediately

---

### MACRO-C07: Request Refund - General

**When to use:** Customer requesting refund without specific issue

**Template:**
```
Hi [NAME],

Thank you for reaching out. I'd be happy to help with your refund request.

To best assist you, could you please let me know:
1. Which booking this is for (date and barber name)?
2. What happened that you'd like a refund?

Our refund policy:
- Cancellations 24+ hours before: Full refund
- Cancellations 12-24 hours before: 50% refund
- Cancellations under 12 hours: No refund (except barber no-show)
- Service issues: Reviewed case-by-case

Once I understand the situation, I'll get back to you right away with next steps.

Best,
[YOUR NAME]
Direct Cuts Support
```

**Follow-up actions:**
- Wait for customer response
- Look up booking details in Supabase
- Apply appropriate macro based on specific issue

---

## Customer - No-Show (Barber)

### MACRO-C08: Barber No-Show - Immediate Response

**When to use:** Customer reports barber didn't show up for appointment

**Template:**
```
Hi [NAME],

I'm so sorry this happened - a barber not showing up is completely unacceptable and not the experience we stand for.

I've immediately:
1. Processed a FULL refund of $[AMOUNT] to your original payment method
2. Flagged this with [BARBER NAME]'s account for review
3. Added $[CREDIT AMOUNT] in Direct Cuts credit to your account for a future booking

The refund will appear within 5-10 business days. Your credit is available immediately.

We take no-shows very seriously. This barber will be contacted and appropriate action taken - repeat offenders are removed from our platform.

I know this doesn't fix your day, but I hope you'll give us another chance. Would you like me to help you find another barber for today or this week?

Again, my sincere apologies.

Best,
[YOUR NAME]
Direct Cuts Support
```

**Follow-up actions:**
- Process full refund in Stripe immediately
- Add credit to customer account in Supabase
- Document no-show on barber's record
- Follow barber no-show process in NO_SHOW_HANDLING.md

---

### MACRO-C09: Barber Running Late

**When to use:** Customer reports barber is late but hasn't completely no-showed

**Template:**
```
Hi [NAME],

Thank you for letting me know. I understand how frustrating it is to wait.

I'm reaching out to [BARBER NAME] right now to get an update on their ETA. I'll get back to you within 15 minutes with an update.

In the meantime, here are your options:
1. Wait for the barber (I'll confirm ETA shortly)
2. Cancel for a full refund since they're late
3. Reschedule to another time

What would you prefer? And don't worry - if you wait and they're significantly late, we'll make it right with a partial refund or credit.

Best,
[YOUR NAME]
Direct Cuts Support
```

**Follow-up actions:**
- Attempt to contact barber via app/phone
- Update customer within 15 minutes
- If barber unreachable after 20 min, treat as no-show

---

## Customer - Service Quality

### MACRO-C10: Unhappy With Haircut - Review Request

**When to use:** Customer unhappy with service quality, wants refund

**Template:**
```
Hi [NAME],

I'm sorry to hear you weren't happy with your haircut. That's definitely not what we want for you.

I'd like to understand more so I can help:
1. What specifically wasn't right about the cut?
2. Did you communicate your concerns to the barber during or after?
3. Do you have any photos showing the issue?

We take service quality seriously, and here's how we typically handle these situations:

- Minor adjustments needed: Many barbers offer free touch-ups within 7 days
- Significant quality issues: Partial refund or credit considered
- Major problems: Full resolution including potential refund

Once I have a bit more detail, I'll work with you on the best solution.

Best,
[YOUR NAME]
Direct Cuts Support
```

**Follow-up actions:**
- Review customer's booking and barber's history
- Check if barber has pattern of complaints
- Gather evidence before deciding on refund

---

### MACRO-C11: Approving Service Quality Refund

**When to use:** After reviewing service complaint, approving refund

**Template:**
```
Hi [NAME],

Thank you for sharing those details and photos. I can see why you're frustrated - this wasn't up to the standard we expect from our barbers.

I've processed a [FULL/PARTIAL] refund of $[AMOUNT]. You should see it in your account within 5-10 business days.

I've also:
- Documented this feedback on the barber's profile
- Reached out to discuss quality expectations with them

We appreciate you letting us know - it helps us maintain quality across the platform. We'd love for you to give Direct Cuts another try. There are several highly-rated barbers in your area who might be a better fit.

Let me know if there's anything else I can do.

Best,
[YOUR NAME]
Direct Cuts Support
```

**Follow-up actions:**
- Process refund in Stripe
- Add note to barber's internal profile
- If multiple complaints, consider barber review/suspension

---

## Customer - Account Issues

### MACRO-C12: Can't Log In

**When to use:** Customer having login/access problems

**Template:**
```
Hi [NAME],

I'm sorry you're having trouble logging in. Let's get this fixed.

Please try these steps:
1. Make sure you're using the email address you signed up with: [THEIR EMAIL IF KNOWN]
2. Tap "Forgot Password" on the login screen to reset your password
3. Check your spam folder for the reset email
4. If using social login (Google/Apple), make sure you're using the same method you originally signed up with

If none of that works:
- Force close the app and reopen it
- Try uninstalling and reinstalling the app

Still stuck? Let me know:
- What email are you trying to log in with?
- Are you seeing any error message? (screenshot helps!)
- Did you sign up with email/password or Google/Apple?

I'll get you back in!

Best,
[YOUR NAME]
Direct Cuts Support
```

**Follow-up actions:**
- Verify account exists in Supabase
- Check if account is suspended/locked
- If needed, assist with manual password reset

---

## Barber - Payment/Stripe Issues

### MACRO-B01: Stripe Connect Setup Help

**When to use:** Barber struggling to set up their Stripe account

**Template:**
```
Hi [NAME],

Welcome to Direct Cuts! I'm happy to help you get your payment account set up.

Here's how to complete your Stripe Connect setup:

1. In the app, go to your Barber Dashboard
2. Tap "Earnings" or "Payment Setup"
3. You'll be redirected to Stripe's secure onboarding
4. Have ready:
   - Government ID (driver's license or passport)
   - Bank account details (routing + account number)
   - Social Security Number (for tax purposes)
   - Your business address

Common issues and fixes:
- "Verification failed": Make sure your ID photo is clear and matches the name you entered
- "Bank account error": Double-check routing and account numbers
- "Already have an account": You may have an existing Stripe account - use that email

The process usually takes 5-10 minutes. Once approved, you'll receive payouts automatically after each completed booking.

Let me know if you hit any specific error and I'll help you through it.

Best,
[YOUR NAME]
Direct Cuts Support
```

**Follow-up actions:**
- If still stuck, check Stripe Dashboard > Connect > Accounts for their status
- Stripe may require additional verification - relay requirements

---

### MACRO-B02: Payment Not Received

**When to use:** Barber says they didn't get paid for a service

**Template:**
```
Hi [NAME],

I understand - you need to get paid for your work! Let me look into this right away.

I've checked your account and here's what I found:

Booking on [DATE] with [CUSTOMER NAME]:
- Service amount: $[AMOUNT]
- Platform fee: $[FEE]
- Your earnings: $[NET]
- Status: [PENDING/PAID/ISSUE]

[IF PENDING:]
Your payout is scheduled for [DATE]. Stripe processes payouts on [YOUR PAYOUT SCHEDULE - usually daily or weekly], and it takes 2 business days to reach your bank.

[IF PAID:]
This was paid out on [DATE]. Please check your bank account ending in [LAST 4]. If you don't see it, there may be a bank processing delay.

[IF ISSUE:]
I see there's an issue with this payment - [EXPLAIN ISSUE]. Here's what I need to resolve it: [NEXT STEPS].

Does this clear things up? Let me know if you have questions about any other bookings.

Best,
[YOUR NAME]
Direct Cuts Support
```

**Follow-up actions:**
- Check Stripe Connect > Account > Payouts for their payout history
- If genuinely missing, escalate to Stripe support

---

### MACRO-B03: Payout Schedule Questions

**When to use:** Barber asking about when/how they get paid

**Template:**
```
Hi [NAME],

Great question! Here's how payouts work on Direct Cuts:

**Payout Schedule:**
- Earnings are paid out [DAILY/WEEKLY] automatically
- Once initiated, funds arrive in 2 business days
- You can view pending and completed payouts in the app under "Earnings"

**Example Timeline:**
- Saturday haircut completed: Funds available Sunday
- Payout initiated: Monday
- Arrives in your bank: Wednesday

**Your Current Setup:**
- Bank account ending in: [LAST 4]
- Payout schedule: [SCHEDULE]
- Next scheduled payout: [DATE]

**To Change Your Payout Settings:**
Go to Earnings > Payout Settings in the app, or visit your Stripe Express Dashboard.

Need to update your bank account? You can do that in the Stripe settings as well - just make sure to verify the new account.

Let me know if you have other questions!

Best,
[YOUR NAME]
Direct Cuts Support
```

**Follow-up actions:**
- Verify their Stripe account is properly configured
- Check for any holds or issues on their account

---

## Barber - Customer No-Show

### MACRO-B04: Customer No-Show - Compensation

**When to use:** Barber reports customer didn't show up

**Template:**
```
Hi [NAME],

I'm sorry you had a no-show - I know that's frustrating and lost income for you.

I've verified that [CUSTOMER NAME] did not show for their [TIME] appointment for [SERVICE].

Here's what happens next:

1. **Your compensation:** You'll receive a no-show fee of $[AMOUNT] (50% of the booked service). This will be included in your next payout.

2. **Customer penalty:** The customer has been charged the no-show fee and notified. This is their [FIRST/SECOND/THIRD] no-show.

3. **Customer record:** This is documented on their account. Repeat no-shows result in account restrictions.

The no-show fee should appear in your Earnings within 24 hours.

To help prevent no-shows, make sure booking reminders are enabled - customers get notifications 24 hours and 1 hour before their appointment.

Thanks for reporting this. Let me know if you have any questions.

Best,
[YOUR NAME]
Direct Cuts Support
```

**Follow-up actions:**
- Verify no-show (check messages, attempt customer contact if needed)
- Process no-show fee per NO_SHOW_HANDLING.md
- Document on customer's account

---

## Barber - Identity Verification

### MACRO-B05: Identity Verification Failed - First Attempt

**When to use:** Barber's identity verification was rejected

**Template:**
```
Hi [NAME],

Thank you for your interest in joining Direct Cuts! I see your identity verification didn't go through on the first attempt. Don't worry - this is common and usually easy to fix.

**Common reasons for verification issues:**
1. Photo quality: ID photo was blurry or had glare
2. Name mismatch: Name on ID doesn't exactly match what you entered
3. Expired ID: The ID document has expired
4. Wrong document type: We need a government-issued photo ID

**To try again:**
1. Open the Direct Cuts app
2. Go to your Barber Profile
3. Tap "Complete Verification"
4. When taking your ID photo:
   - Use good lighting (natural light works best)
   - Hold the camera steady
   - Make sure all four corners of the ID are visible
   - Avoid glare on the ID surface

**Accepted documents:**
- Driver's license
- State ID
- Passport

Note: This is identity verification to confirm you are who you say you are - we want to build trust between barbers and customers.

Please try again, and let me know if you hit the same issue. I'm here to help!

Best,
[YOUR NAME]
Direct Cuts Support
```

**Follow-up actions:**
- Check Persona dashboard for specific failure reason
- Provide more specific guidance if you can see the issue

---

### MACRO-B06: Identity Verification Failed - Multiple Attempts

**When to use:** Barber has failed verification multiple times

**Template:**
```
Hi [NAME],

I see you've had some difficulty with the identity verification process. I want to help you get this resolved.

I've looked into your verification attempts and see the issue is: [SPECIFIC REASON FROM PERSONA]

Here's what I need from you to manually review:

1. A clear photo of the FRONT of your government ID
2. A clear photo of the BACK of your government ID
3. A selfie holding your ID next to your face

Please reply to this email with those three photos, and I'll process your verification manually. Make sure:
- Photos are well-lit and not blurry
- All text on the ID is readable
- Your face is clearly visible in the selfie

This usually takes 1-2 business days for manual review.

If you have any questions about why we verify identity, I'm happy to explain - it's all about building trust with customers who are inviting barbers into their space.

Looking forward to getting you onboarded!

Best,
[YOUR NAME]
Direct Cuts Support
```

**Follow-up actions:**
- Process manual verification if documents submitted
- If still failing, there may be a legitimate issue - review carefully

---

### MACRO-B07: Identity Verification - Final Rejection

**When to use:** After manual review, barber cannot be verified

**Template:**
```
Hi [NAME],

Thank you for your patience through the verification process. After careful review, I'm sorry to say we're unable to verify your identity at this time.

This could be due to:
- Document issues that couldn't be resolved
- Information that didn't match across verification steps
- Other factors in our verification process

I understand this is disappointing. A few options:

1. **Try again later:** If your circumstances change (new ID, etc.), you're welcome to create a new account and try again.

2. **Questions:** If you believe there's been an error, please let me know what specific documents you submitted and I'll take another look.

Identity verification is essential for our platform - customers need to trust the barbers they book, especially for mobile appointments. We can't make exceptions to this requirement.

I wish you the best in your barbering career.

Best,
[YOUR NAME]
Direct Cuts Support
```

**Follow-up actions:**
- Document final rejection in system
- If they reply with compelling information, consider re-review

---

## Barber - Review Disputes

### MACRO-B08: Review Dispute Request

**When to use:** Barber wants a negative review removed

**Template:**
```
Hi [NAME],

Thank you for reaching out about the review from [CUSTOMER]. I understand negative reviews can be frustrating, especially if you feel they're unfair.

Our review policy:
- We generally don't remove reviews unless they violate our guidelines
- Reviews are removed if they contain: hate speech, personal attacks, false claims of illegal activity, or are clearly fake
- We don't remove reviews just because the barber disagrees with the rating

That said, I've reviewed the feedback and here's what I found:
[DESCRIBE THE REVIEW AND ANY RELEVANT BOOKING DETAILS]

[IF VIOLATES GUIDELINES:]
You're right - this review does violate our guidelines because [REASON]. I've removed it from your profile.

[IF DOESN'T VIOLATE:]
While I understand your frustration, this review reflects the customer's genuine experience and doesn't violate our guidelines. I'm not able to remove it.

**What you can do:**
1. Respond publicly to the review - professional responses show future customers your character
2. Focus on getting more positive reviews to balance it out
3. If there's a pattern in negative feedback, consider it constructive input

Would you like help crafting a professional response to this review?

Best,
[YOUR NAME]
Direct Cuts Support
```

**Follow-up actions:**
- Review the actual review content
- Check if customer has history of abusive reviews
- If removed, notify customer their review was removed and why

---

## General - App Issues

### MACRO-G01: App Crashing

**When to use:** User reporting app crashes

**Template:**
```
Hi [NAME],

I'm sorry the app isn't working properly for you. Let's get this fixed.

Please try these steps in order:

1. **Force close and reopen:**
   - iPhone: Swipe up from bottom, swipe the app away
   - Android: Recent apps button, swipe the app away
   - Reopen Direct Cuts

2. **Update the app:**
   - Check App Store/Play Store for updates
   - Install any available updates

3. **Restart your phone:**
   - Sometimes a fresh restart fixes things

4. **Reinstall if needed:**
   - Delete the app
   - Reinstall from App Store/Play Store
   - Log back in

If it's still crashing after all that, please let me know:
- What phone model do you have?
- What were you doing when it crashed?
- Does it crash every time or just sometimes?

I'll escalate to our technical team if needed.

Best,
[YOUR NAME]
Direct Cuts Support
```

**Follow-up actions:**
- Check crash reports in App Store Connect / Play Console
- If multiple users report same crash, escalate to engineering immediately

---

### MACRO-G02: Feature Request

**When to use:** User suggesting a new feature

**Template:**
```
Hi [NAME],

Thank you for the suggestion! I love hearing ideas from our users.

Your idea: [SUMMARIZE THEIR REQUEST]

I've logged this in our feature request tracker. While I can't promise when or if it'll be implemented, I can tell you:
- Our team reviews all suggestions
- Popular requests often get prioritized
- Some great features came from user suggestions

Is there anything else about the current app I can help you with in the meantime?

Best,
[YOUR NAME]
Direct Cuts Support
```

**Follow-up actions:**
- Log in feature request tracking (spreadsheet/notion/etc.)
- If multiple requests for same feature, note volume

---

### MACRO-G03: Bug Report Acknowledgment

**When to use:** User reporting a non-critical bug

**Template:**
```
Hi [NAME],

Thank you for reporting this! Bug reports help us improve Direct Cuts for everyone.

I've documented the issue:
- What happened: [THEIR DESCRIPTION]
- Where in the app: [SCREEN/FEATURE]
- Device: [IF PROVIDED]

Our development team will investigate. While I can't give an exact timeline for fixes, we prioritize based on how many users are affected and severity.

Is there a workaround I can suggest in the meantime? [SUGGEST IF APPLICABLE]

Thanks for helping us improve!

Best,
[YOUR NAME]
Direct Cuts Support
```

**Follow-up actions:**
- Log bug in tracking system
- If user-blocking, escalate to engineering

---

## Escalation Responses

### MACRO-E01: Legal Threat Response

**When to use:** Customer or barber threatens legal action

**Template:**
```
Hi [NAME],

Thank you for reaching out. I understand you're frustrated with this situation.

I've noted your concerns and escalated this to the appropriate team for review. Given the nature of your message, any further communication regarding potential legal matters should be directed to:

Direct Cuts LLC
Legal Department
[ADDRESS OR legal@direct-cuts.com]

In the meantime, I'm happy to continue working on resolving the underlying issue through our standard support process if you'd like.

Best,
[YOUR NAME]
Direct Cuts Support
```

**Follow-up actions:**
- DO NOT admit fault or liability
- Document everything
- Alert lawyer/legal counsel
- Continue trying to resolve underlying issue

---

### MACRO-E02: Social Media Complaint Response

**When to use:** Responding to public complaint on social media

**Template:**
```
Hi [NAME], I'm sorry to hear about your experience. We take all feedback seriously and want to make this right. I've sent you a DM so we can look into this and get it resolved for you. - [YOUR NAME], Direct Cuts Support
```

**Follow-up actions:**
- Move to private channel immediately
- Resolve quickly - public complaints escalate fast
- Once resolved, ask if they'd update their post

---

### MACRO-E03: Escalating to Engineering

**When to use:** Technical issue beyond support scope

**Template:**
```
Hi [NAME],

Thank you for the detailed report. This appears to be a technical issue that needs our engineering team to investigate.

I've escalated this with all the details you provided. Here's what happens next:
- Our engineers will review within [24-48 hours]
- If they need more information, I'll reach out
- Once fixed, I'll update you

In the meantime, is there a workaround I can help you with? [SUGGEST IF POSSIBLE]

I'll be in touch as soon as I have an update.

Best,
[YOUR NAME]
Direct Cuts Support
```

**Follow-up actions:**
- Create detailed engineering ticket
- Include: steps to reproduce, device info, screenshots, user ID
- Follow up within promised timeframe

---

### MACRO-E04: Apology + Compensation Offer

**When to use:** When we messed up and need to make it right

**Template:**
```
Hi [NAME],

I want to sincerely apologize for [SPECIFIC ISSUE]. This is not the experience we want anyone to have with Direct Cuts, and I take full responsibility for getting this resolved.

Here's what I've done to make this right:
1. [ACTION TAKEN - refund/fix/etc.]
2. [ADDITIONAL ACTION IF APPLICABLE]
3. Added $[AMOUNT] credit to your account for future use

I know this doesn't undo the frustration, but I hope it shows we value you and want to earn back your trust.

Is there anything else I can do for you?

Best,
[YOUR NAME]
Direct Cuts Support
```

**Follow-up actions:**
- Ensure all promised actions are completed
- Document for future pattern analysis

---

## Quick Reference: Which Macro to Use

| Situation | Macro ID |
|-----------|----------|
| Booking confirmation missing | MACRO-C01 |
| How to cancel | MACRO-C02 |
| How to reschedule | MACRO-C03 |
| No barbers nearby | MACRO-C04 |
| Charged but no booking | MACRO-C05 |
| Double charged | MACRO-C06 |
| General refund request | MACRO-C07 |
| Barber no-show | MACRO-C08 |
| Barber running late | MACRO-C09 |
| Bad haircut complaint | MACRO-C10 |
| Approving quality refund | MACRO-C11 |
| Login problems | MACRO-C12 |
| Stripe setup help (barber) | MACRO-B01 |
| Missing payment (barber) | MACRO-B02 |
| Payout questions (barber) | MACRO-B03 |
| Customer no-show (barber) | MACRO-B04 |
| Verification failed - first | MACRO-B05 |
| Verification failed - multiple | MACRO-B06 |
| Verification - final rejection | MACRO-B07 |
| Review dispute (barber) | MACRO-B08 |
| App crashing | MACRO-G01 |
| Feature request | MACRO-G02 |
| Bug report | MACRO-G03 |
| Legal threat | MACRO-E01 |
| Social media complaint | MACRO-E02 |
| Engineering escalation | MACRO-E03 |
| Major apology needed | MACRO-E04 |

---

*Keep this document updated as new common issues emerge. If you find yourself writing the same response 3+ times, create a new macro.*
