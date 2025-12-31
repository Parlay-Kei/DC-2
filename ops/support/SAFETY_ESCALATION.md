# Safety Escalation Procedures

**Version:** 1.0.0
**Last Updated:** 2025-12-31

---

## Overview

Safety is paramount. This document covers:
1. Identifying safety concerns
2. Immediate response actions
3. Account suspension procedures
4. Law enforcement coordination (when necessary)
5. Documentation requirements

**Core Principle:** When safety is at risk, act first, ask questions later. We can always reinstate an account; we cannot undo harm.

---

## Safety Concern Categories

### TIER 1 - Immediate Threat (Act Within 15 Minutes)

| Trigger | Examples |
|---------|----------|
| Physical violence threatened or occurring | "He hit me," "I'm going to hurt them," "I have a weapon" |
| Sexual assault/harassment reported | Any form of unwanted sexual contact or behavior |
| Kidnapping/false imprisonment | User can't leave, held against will |
| Robbery/theft in progress | Service used to facilitate crime |
| Medical emergency | User having medical crisis during service |
| Active stalking | Using platform to track/follow someone |

**Response:** Drop everything. This is your only priority.

### TIER 2 - Serious Concern (Act Within 1 Hour)

| Trigger | Examples |
|---------|----------|
| Harassment (non-violent) | Repeated unwanted contact, intimidation |
| Threatening behavior | Veiled threats, aggressive language |
| Discrimination | Racial slurs, service denial based on protected class |
| Inappropriate requests | Solicitation for illegal/inappropriate services |
| Identity fraud/impersonation | Using fake identity to access service |
| Property damage | Damage to home/shop during service |

**Response:** Respond immediately, investigate thoroughly.

### TIER 3 - Concerning Behavior (Act Within 24 Hours)

| Trigger | Examples |
|---------|----------|
| Boundary violations | Requesting personal info, off-platform contact |
| Minor harassment | Single uncomfortable comment |
| Review manipulation with threats | "Fix this or I'll find you" |
| Suspicious patterns | Unusual booking behavior suggesting bad intent |

**Response:** Document, warn, monitor.

---

## Tier 1 Response Protocol

### Step 1: Immediate Triage (0-5 Minutes)

**If user is in immediate danger:**

```
If someone is in danger RIGHT NOW, call 911.

Are you safe at the moment? If not, please:
1. Call 911 immediately
2. Get to a safe location
3. I'm here and will help however I can

Please let me know you're okay.
```

**Get essential information:**
- What happened?
- Where are they now?
- Are they safe?
- Is the other party still present?
- Do they need emergency services?

### Step 2: Secure the Situation (5-15 Minutes)

**If other party is a barber:**
1. Immediately suspend barber account
2. Block their access to app
3. Remove any active bookings
4. Do NOT notify them of suspension yet (safety first)

**If other party is a customer:**
1. Immediately suspend customer account
2. Alert barber if they have upcoming appointment
3. Provide barber with safe cancellation

**In Supabase:**
```sql
-- Emergency account suspension
UPDATE profiles
SET status = 'suspended',
    suspension_reason = 'safety_investigation',
    suspended_at = NOW()
WHERE id = 'user-uuid';
```

### Step 3: Document Everything (Ongoing)

Create incident report with:
- [ ] Timestamp of report
- [ ] Reporter's contact info
- [ ] Accused party's info
- [ ] What was reported (verbatim if possible)
- [ ] Evidence (screenshots, messages)
- [ ] Actions taken
- [ ] Responding staff member

### Step 4: Support the Reporter

**Empathy first:**
```
I'm so sorry this happened to you. Your safety is our top priority.

Here's what I've done:
- [Account suspended/blocked]
- [Bookings cancelled]
- [Refund processed if applicable]

You will not see this person on Direct Cuts again.

Do you need any additional support? I can provide:
- Confirmation documentation for police report
- Screenshot of messages/evidence
- Contact information for local victim services

Please take care of yourself. I'm here if you need anything.
```

### Step 5: Law Enforcement Coordination

**When to recommend police involvement:**
- Any physical violence
- Sexual assault of any kind
- Robbery/theft
- Credible threats of violence
- Stalking

**Our role:**
- Encourage victim to file report
- Provide documentation if requested
- Comply with valid legal requests
- Do NOT contact police without victim's consent (unless imminent danger)

**If police request information:**
1. Require valid legal process (subpoena, warrant)
2. Verify legitimacy of request
3. Provide only what's legally required
4. Document what was shared
5. Notify user if legally permitted

**Information We Can Provide (With Legal Process):**
- Account information
- Booking history
- Communication records
- Payment records (through Stripe)
- Device/IP information (if logged)

---

## Tier 2 Response Protocol

### Step 1: Immediate Response (Within 1 Hour)

**Acknowledge and gather information:**
```
Hi [NAME],

Thank you for reporting this. I'm taking your concern seriously.

To help me investigate properly, could you please:
1. Describe what happened in detail
2. Share any screenshots of concerning messages
3. Let me know if you feel safe right now

I'm looking into this immediately.

Best,
[YOUR NAME]
```

### Step 2: Investigate

**Review:**
- All in-app messages between parties
- Booking history
- Previous complaints about accused party
- Account history/patterns

**Reach out to accused (if appropriate):**
```
Hi [NAME],

We received a report about your interaction with another user on [DATE].

Before we take any action, I'd like to hear your side.
Could you tell me what happened during your appointment with [NAME]?

Please respond within 24 hours.

Best,
[YOUR NAME]
```

### Step 3: Take Action

**Based on severity and evidence:**

| Finding | Action |
|---------|--------|
| Clear violation, evidence strong | Suspend account, refund victim if applicable |
| Violation but first offense | Warning, documented, probation |
| Unclear, conflicting accounts | Warning to both, increased monitoring |
| False report likely | No action on accused, note on reporter |

### Step 4: Communicate Decisions

**To reporter:**
```
Hi [NAME],

I've completed my investigation into your report.

What I found: [Brief summary]

Action taken: [What you did]

This person [will/will not] be able to contact you on Direct Cuts.

I know this was difficult to report, and I appreciate you helping
keep our community safe.

Best,
[YOUR NAME]
```

**To accused (if action taken):**
```
Hi [NAME],

Following our investigation into a report about your behavior on [DATE],
we've taken the following action: [ACTION]

Reason: [Specific behavior that violated terms]

[If warning:] Future violations will result in account suspension.

[If suspension:] You may appeal this decision by replying to this email
with any additional information within 7 days.

Our community standards: [LINK]

Best,
[YOUR NAME]
```

---

## Tier 3 Response Protocol

### Standard Process

1. **Document the concern** - Add note to user's profile
2. **Send warning if warranted** - Clear, professional warning
3. **Monitor account** - Flag for review if future issues
4. **No immediate suspension** - Unless escalates

### Warning Template

```
Hi [NAME],

We noticed some behavior in your recent interaction that we
want to address:

[Specific behavior]

This type of behavior isn't consistent with our community standards.
We want Direct Cuts to be a comfortable experience for everyone.

Please be mindful of this going forward. If you have questions
about our community standards, I'm happy to clarify.

Best,
[YOUR NAME]
```

---

## Account Suspension Process

### Temporary Suspension

**When:** Investigation needed, precautionary measure

**Duration:** Until investigation complete (target: 24-72 hours)

**Process:**
1. Update account status to "suspended" in Supabase
2. Cancel any active/upcoming bookings
3. Send suspension notification
4. Investigate
5. Reinstate or escalate to permanent

**Notification:**
```
Subject: Direct Cuts Account Temporarily Suspended

Hi [NAME],

Your Direct Cuts account has been temporarily suspended while
we investigate a concern.

This is a precautionary measure and does not indicate a final decision.

We'll be in touch within 48 hours with an update.

If you have information relevant to this matter, please reply
to this email.

Best,
Direct Cuts Support
```

### Permanent Suspension

**When:**
- Serious violation confirmed
- Pattern of violations
- Safety risk to community
- Fraud confirmed

**Process:**
1. Update account status to "banned"
2. Add to platform blocklist (email, phone, device if possible)
3. Refund any unused credits
4. Handle any pending payouts (barbers)
5. Send permanent suspension notification

**Notification:**
```
Subject: Direct Cuts Account Permanently Suspended

Hi [NAME],

Your Direct Cuts account has been permanently suspended.

Reason: [Brief, factual reason]

This decision was made following [investigation/review of conduct/
terms of service violation].

Any bookings have been cancelled. [If applicable: Pending payouts
will be processed within 5 business days.]

You may appeal this decision within 14 days by responding to this email.
Appeals must include new information not previously considered.

Thank you,
Direct Cuts Support
```

### Appeal Process

**Timeline:** 14 days to appeal

**Requirements:**
- New information not previously available
- Genuine accountability (not just "sorry I got caught")
- Clear plan for different behavior

**Review:**
- Take 24-48 hours to consider (no rush)
- Look for genuine change indicators
- Check if safety risk remains
- Final decision is final

---

## Specific Scenario Playbooks

### Sexual Harassment

**Defined as:** Unwelcome sexual advances, requests for sexual favors, or other verbal/physical conduct of sexual nature.

**Examples:**
- Inappropriate comments about body
- Unwanted touching
- Requesting sexual services
- Sending explicit messages
- Creating uncomfortable sexual environment

**Response:**
1. Tier 1 or Tier 2 depending on severity
2. Suspend accused immediately (pending investigation)
3. Support victim
4. Provide resources if requested
5. Zero tolerance - confirmed cases = permanent ban

### Physical Safety During Mobile Appointments

**When barber reports feeling unsafe:**
```
Your safety is the priority. Please:
1. End the appointment if you feel unsafe
2. Leave the location immediately
3. Call 911 if you're in danger
4. Contact me when you're safe

I'll handle the customer and any refund issues.
You do NOT need to complete an appointment if you feel unsafe.
```

**When customer reports unsafe barber:**
Same protocol - safety first, questions later.

### Theft or Property Damage

**Customer claims barber stole something:**
1. Get detailed account (what, when, proof)
2. Suspend barber pending investigation
3. Recommend police report for theft
4. If confirmed, permanent ban + cooperate with law enforcement

**Barber claims damage to equipment:**
1. Get details and photos
2. Contact customer
3. Small claims court may be appropriate
4. We don't mediate property disputes but document

### Discrimination Reports

**Process:**
1. Document the claim
2. Review any evidence (messages)
3. Contact accused for their account
4. If discrimination confirmed: Permanent ban
5. If unclear: Warning and monitoring

**Response to victim:**
```
I'm sorry you experienced this. Discrimination has no place
on Direct Cuts.

I've reviewed the situation and [action taken].

This behavior violates our community standards and [consequences].

Thank you for reporting this - it helps us maintain the inclusive
community we're building.
```

---

## Documentation Requirements

### Incident Report Template

```
INCIDENT REPORT
===============
Report ID: INC-[DATE]-[NUMBER]
Date/Time Reported:
Responding Staff:

PARTIES INVOLVED
----------------
Reporter:
- Name:
- Account ID:
- User Type: [Customer/Barber]
- Contact:

Accused:
- Name:
- Account ID:
- User Type: [Customer/Barber]
- Contact:

INCIDENT DETAILS
----------------
Date/Time of Incident:
Location:
Booking ID (if applicable):

Description:
[Verbatim account from reporter]

Evidence:
- [ ] Screenshots attached
- [ ] Message history exported
- [ ] Photos attached
- [ ] Other:

TIER CLASSIFICATION
-------------------
[ ] Tier 1 - Immediate Threat
[ ] Tier 2 - Serious Concern
[ ] Tier 3 - Concerning Behavior

ACTIONS TAKEN
-------------
1.
2.
3.

OUTCOME
-------
Decision:
Date Closed:
Follow-up Required: [ ] Yes [ ] No

NOTES
-----

```

### Record Retention

| Record Type | Retention Period |
|-------------|------------------|
| Safety incident reports | 7 years |
| Account suspension records | 7 years |
| Communication during investigation | 7 years |
| General support tickets | 2 years |
| Law enforcement requests | Permanent |

---

## Emergency Contacts

### Internal

| Role | Contact | When |
|------|---------|------|
| Founder | [Your Phone] | Tier 1 incidents, any time |
| Legal Counsel | [Lawyer Contact] | Lawsuits, law enforcement, serious claims |

### External

| Service | Contact | When |
|---------|---------|------|
| Emergency Services | 911 | Immediate danger |
| Police Non-Emergency | [Local Number] | Reports, follow-up |
| National DV Hotline | 1-800-799-7233 | Domestic violence resources |
| RAINN | 1-800-656-4673 | Sexual assault resources |
| Stripe Support | Dashboard | Payment freezes, fraud |

---

## Quick Reference

### Tier 1 (Immediate Danger)
- Act in 15 minutes
- Suspend account first
- Support victim
- Document everything
- Consider law enforcement

### Tier 2 (Serious Concern)
- Act in 1 hour
- Investigate before suspending (usually)
- Get both sides
- Document and decide

### Tier 3 (Concerning)
- Act in 24 hours
- Warning usually sufficient
- Document and monitor
- Escalate if repeats

### Golden Rules
1. Safety first, always
2. When in doubt, suspend pending investigation
3. Support victims; don't interrogate them
4. Document everything in writing
5. Never promise confidentiality you can't keep

---

*This is the most important document in your support toolkit. When safety is at stake, everything else can wait.*
