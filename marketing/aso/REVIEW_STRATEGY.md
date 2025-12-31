# Direct Cuts - Review Strategy

## Overview

Reviews are critical for App Store Optimization, affecting both rankings and conversion rates. This document outlines a comprehensive strategy for generating, managing, and leveraging reviews for Direct Cuts.

**Goals:**
1. Achieve 4.5+ star average rating
2. Generate consistent review velocity (10+ reviews/week at scale)
3. Maintain high response rate to reviews (100% for negative, 50%+ for positive)
4. Convert feedback into product improvements

---

## Part 1: Review Generation Strategy

### When to Prompt for Reviews

The key to successful review prompts is timing. Ask at moments of delight, not frustration.

#### Optimal Trigger Points (Customers):

| Trigger | Why It Works | Implementation |
|---------|--------------|----------------|
| After 1st successful booking | Early positive experience | 24h after appointment completed |
| After completing 3rd booking | Proven value, repeat user | Immediately after 3rd confirmation |
| After receiving 5-star rating from barber | Reciprocity effect | Within the app session |
| After using "favorite barber" feature | High engagement signal | Next app open |
| After mobile barber appointment | Unique value delivered | Same day, evening |

#### Optimal Trigger Points (Barbers):

| Trigger | Why It Works | Implementation |
|---------|--------------|----------------|
| After 5th completed booking | Platform has delivered value | After 5th payment received |
| After reaching $500 earnings | Financial success milestone | Within earnings dashboard |
| After receiving 3 consecutive 5-star reviews | Confidence high | Next app session |
| After 30 days active on platform | Commitment established | Push notification |

#### When NOT to Prompt:

| Scenario | Risk |
|----------|------|
| After app crash or bug | Negative review likely |
| After payment issue | User frustrated |
| After booking cancellation | Negative association |
| During first app session | No value delivered yet |
| After customer complaint | Obviously wrong timing |
| More than once per 90 days | Prompt fatigue, policy violation |

---

### In-App Review Flow Design

#### iOS Implementation (SKStoreReviewController)

Apple limits review prompts to 3 per year per user. Use wisely.

```
Review Prompt Flow:

1. TRIGGER EVENT occurs (e.g., 3rd booking completed)
   |
2. CHECK: Has user been prompted in last 120 days?
   |-- YES --> Do not prompt
   |-- NO --> Continue
   |
3. CHECK: Has user had any negative experience in last 7 days?
   |-- YES --> Do not prompt
   |-- NO --> Continue
   |
4. CHECK: User engagement score > threshold?
   |-- NO --> Do not prompt
   |-- YES --> Continue
   |
5. DELAY: Wait 2 seconds after positive action
   |
6. SHOW: Native iOS review prompt
   |
7. LOG: Prompt shown (for 90-day tracking)
```

#### Android Implementation (In-App Review API)

Google's in-app review flow is quota-limited. Cannot be tested reliably.

```
Review Prompt Flow:

1. TRIGGER EVENT occurs
   |
2. CHECK: Engagement criteria met?
   |-- NO --> Do not prompt
   |-- YES --> Continue
   |
3. REQUEST: ReviewManager.requestReviewFlow()
   |
4. LAUNCH: ReviewManager.launchReviewFlow()
   |
5. Note: Cannot confirm if user left review (by design)
```

#### Pre-Prompt Soft Ask (Recommended)

Before triggering the system prompt, use a soft ask to filter sentiment:

```
+----------------------------------------+
|                                        |
|  How's your Direct Cuts experience?    |
|                                        |
|  [Amazing!]        [Could be better]   |
|                                        |
+----------------------------------------+

If "Amazing!" --> Trigger system review prompt
If "Could be better" --> Open feedback form (not store)
```

**Benefits:**
- Filters negative sentiment before it reaches the store
- Captures feedback for improvement
- Higher quality reviews reach the store
- Not against store policies (soft ask is custom UI)

---

### Post-Appointment Review Request

Beyond the in-app prompt, request reviews through other channels:

#### Email Flow (Customers):

**Timing:** 24 hours after appointment completed

**Subject Lines to Test:**
- "How was your cut with [Barber Name]?"
- "[Name], got a minute to share your experience?"
- "Your feedback helps barbers like [Barber Name]"

**Email Template:**

```
Subject: How was your cut with Marcus?

Hi [First Name],

Hope you're loving your fresh cut!

If Marcus did a great job, would you take 30 seconds to leave a review?
It helps him get discovered by more customers.

[Leave a Review Button - deep link to app store]

Thanks for being part of Direct Cuts.

- The Direct Cuts Team

P.S. Had an issue? Reply to this email and we'll make it right.
```

#### Push Notification (Alternative):

**Timing:** Same day, 6-8 PM (evening review time)

```
Title: Fresh cut looking good?
Body: Take 30 seconds to review your barber. Your feedback matters!
[Opens app with review prompt]
```

---

### Barber-Prompted Reviews

Empower barbers to encourage reviews (carefully):

#### In-App Feature: "Request Review"

After completing an appointment, barbers can send a polite review request:

```
+----------------------------------------+
| Request Review from [Customer]?        |
|                                        |
| A message will be sent after their     |
| appointment asking for feedback.       |
|                                        |
| [Send Request]    [Skip]               |
+----------------------------------------+
```

**Message Sent to Customer:**
```
[Barber Name] hopes you enjoyed your appointment!

If you have a moment, leaving a review helps independent
barbers grow their business on Direct Cuts.

[Leave Review]
```

**Guardrails:**
- Barbers can only request once per customer per 90 days
- Cannot request if customer rated below 4 stars in-app
- Rate limit: 5 requests per day per barber

---

## Part 2: Review Response Strategy

### Response Framework

Responding to reviews shows engagement and can influence future customers.

#### Response Priority:

| Review Type | Response Priority | Target Response Time |
|-------------|-------------------|---------------------|
| 1-star | CRITICAL | Within 4 hours |
| 2-star | HIGH | Within 24 hours |
| 3-star | MEDIUM | Within 48 hours |
| 4-star (with feedback) | MEDIUM | Within 72 hours |
| 5-star (with comment) | LOW | Within 1 week |
| 5-star (no comment) | OPTIONAL | When time permits |

---

### Response Templates

#### 5-Star Reviews (Positive)

**Template 1: Simple Gratitude**
```
Thank you for the 5 stars, [Name]! We're glad Direct Cuts helped you find a great barber. See you at your next booking!
```

**Template 2: Highlight Feature**
```
Thanks for the review, [Name]! Glad you loved the [mobile barber/booking experience/etc.]. We're always working to make finding your perfect barber even easier.
```

**Template 3: Encourage Sharing**
```
[Name], thank you! Reviews like yours help verified barbers on our platform get discovered. We appreciate you being part of the Direct Cuts community.
```

---

#### 4-Star Reviews

**Template 1: Appreciate + Invite Feedback**
```
Thanks for the 4 stars, [Name]! We'd love to know what would make Direct Cuts a 5-star experience for you. Feel free to reach out at support@directcuts.com with any suggestions.
```

**Template 2: Acknowledge Specific Feedback**
```
Hi [Name], thanks for the review! We hear you on [specific feedback mentioned]. Our team is working on improvements in this area. Thanks for helping us get better!
```

---

#### 3-Star Reviews

**Template 1: Acknowledge + Offer Support**
```
Hi [Name], thanks for your honest feedback. We're sorry Direct Cuts didn't fully meet your expectations. We'd love to understand more - please reach out to support@directcuts.com and we'll make it right.
```

**Template 2: Address Specific Issue**
```
Thanks for the feedback, [Name]. We're sorry about [specific issue]. This isn't the experience we aim for. Please contact us at support@directcuts.com so we can resolve this for you.
```

---

#### 2-Star Reviews

**Template 1: Apologize + Escalate**
```
Hi [Name], we're sorry to hear about your experience. This isn't acceptable and we want to fix it. Please email support@directcuts.com with details and we'll personally look into this.
```

**Template 2: Take Ownership**
```
[Name], thank you for letting us know. We clearly fell short and want to make it right. Our support team will reach out, or please contact support@directcuts.com directly.
```

---

#### 1-Star Reviews

**Template 1: Urgent Response**
```
[Name], we're truly sorry. This is not the experience we want anyone to have with Direct Cuts. Please contact us immediately at support@directcuts.com - we will personally ensure this is resolved.
```

**Template 2: Specific Issue Response**
```
Hi [Name], we sincerely apologize for [specific issue]. This is unacceptable and we're taking immediate action. Please reach out to support@directcuts.com so we can make this right and ensure it doesn't happen again.
```

**Template 3: Barber-Related Complaint**
```
[Name], we're sorry your experience with [Barber] didn't meet expectations. All barbers on Direct Cuts are identity verified, but we take service quality seriously. Please contact support@directcuts.com - we want to resolve this.
```

---

### Response Best Practices

**DO:**
- Respond within stated timeframes
- Personalize with reviewer's name
- Acknowledge specific feedback
- Take ownership of issues
- Provide contact for resolution
- Keep responses concise
- Thank users for feedback (even negative)

**DON'T:**
- Use identical template responses repeatedly
- Get defensive or argumentative
- Make excuses
- Blame the barber or customer
- Share private details publicly
- Promise features you can't deliver
- Ignore legitimate complaints

---

### Handling Specific Situations

#### Complaint About a Barber:

```
Response:
Hi [Name], we're sorry your appointment didn't meet expectations. While all
Direct Cuts barbers are identity verified, we take service quality seriously.
We've noted your feedback and will follow up with the barber. Please contact
support@directcuts.com for a resolution.

Internal Action:
1. Flag barber profile for review
2. Reach out to customer privately
3. If pattern emerges, consider barber removal
4. Document for quality tracking
```

#### Complaint About App Bugs:

```
Response:
Thanks for reporting this, [Name]. We're sorry for the technical issue. Our
team has been notified and is working on a fix. Please update to the latest
version when available. Email support@directcuts.com if issues persist.

Internal Action:
1. Log bug report
2. Verify with engineering
3. Prioritize if widespread
4. Update reviewer when fixed
```

#### Fake or Spam Review:

```
Action:
1. Report to App Store / Google Play
2. Do NOT respond publicly
3. Document for records
4. Monitor for patterns
```

#### Review Mentions Competitor Positively:

```
Response:
Thanks for the feedback, [Name]. We're always working to improve Direct Cuts.
If there's a specific feature you'd like to see, we'd love to hear about it
at feedback@directcuts.com.

Note: Never mention competitors by name in responses.
```

---

## Part 3: Review Monitoring & Analysis

### Monitoring Setup

#### Daily Monitoring:
- Check all new reviews
- Prioritize negative reviews for response
- Log common themes

#### Weekly Analysis:
- Review volume trend
- Average rating trend
- Common feedback themes
- Competitor review comparison

#### Monthly Report:
- Rating changes
- Review velocity
- Sentiment analysis
- Feature requests from reviews
- Response rate metrics

---

### Review Monitoring Tools

| Tool | Purpose | Cost |
|------|---------|------|
| AppFollow | Review aggregation, alerts | $$$ |
| App Annie | Market intelligence | $$$$ |
| Appbot | Sentiment analysis | $$ |
| ReviewBot | Slack integration | $ |
| Manual (App Store Connect/Play Console) | Free but time-intensive | Free |

### Recommended Setup:

1. **Slack Integration:** All reviews posted to #reviews channel
2. **Email Alerts:** 1-2 star reviews trigger immediate email
3. **Weekly Digest:** Summary of all reviews sent to team
4. **Dashboard:** Real-time rating and review count

---

### Sentiment Analysis Framework

Track review themes over time:

| Theme | Examples | Action Owner |
|-------|----------|--------------|
| App Performance | Crashes, slow loading | Engineering |
| Booking Flow | Confusing, too many steps | Product |
| Barber Quality | Bad haircut, unprofessional | Operations |
| Pricing | Too expensive, hidden fees | Business |
| Customer Support | Slow response, unhelpful | Support |
| Feature Requests | Want feature X | Product |
| Mobile Barber | Love/hate mobile service | Product |

### Monthly Theme Report Template:

```
Review Theme Report - [Month Year]

Total Reviews: XX
Average Rating: X.X
Response Rate: XX%

Top Positive Themes:
1. Mobile barber convenience (XX mentions)
2. Easy booking (XX mentions)
3. Quality barbers (XX mentions)

Top Negative Themes:
1. [Issue] (XX mentions) - Owner: [Team]
2. [Issue] (XX mentions) - Owner: [Team]
3. [Issue] (XX mentions) - Owner: [Team]

Feature Requests:
1. [Feature] (XX mentions)
2. [Feature] (XX mentions)

Action Items:
- [Action 1]
- [Action 2]
```

---

## Part 4: Review Velocity & Rating Goals

### Launch Phase (Months 1-3)

**Goal:** Establish baseline, reach 100 reviews

| Metric | Target |
|--------|--------|
| Total Reviews | 100+ |
| Average Rating | 4.3+ |
| Review Velocity | 10/week |
| Response Rate | 100% (all reviews) |

**Tactics:**
- Aggressive (but compliant) review prompting
- Personal outreach to early users
- Barber-prompted reviews
- Email follow-ups

### Growth Phase (Months 4-12)

**Goal:** Build credibility, reach 1000 reviews

| Metric | Target |
|--------|--------|
| Total Reviews | 1000+ |
| Average Rating | 4.5+ |
| Review Velocity | 30/week |
| Response Rate | 100% negative, 50% positive |

**Tactics:**
- Optimize prompt timing based on data
- Incentive programs (carefully - no paid reviews)
- Community building
- Respond to all negative reviews within 24h

### Scale Phase (Year 2+)

**Goal:** Maintain and improve

| Metric | Target |
|--------|--------|
| Total Reviews | 5000+ |
| Average Rating | 4.6+ |
| Review Velocity | Sustainable |
| Response Rate | 100% negative, 25% positive |

**Tactics:**
- Automated response suggestions
- Review theme tracking
- Product improvements based on feedback
- Proactive issue resolution

---

## Part 5: Compliance & Best Practices

### Apple App Store Guidelines

**Allowed:**
- Using SKStoreReviewController (3x per year limit)
- Asking users to rate the app at appropriate times
- Responding to reviews in App Store Connect

**NOT Allowed:**
- Incentivizing reviews (discounts for reviews)
- Asking for specific star ratings
- Interrupting the user experience with prompts
- Using custom review prompt UI that mimics system UI
- Manipulating or purchasing reviews

### Google Play Guidelines

**Allowed:**
- Using In-App Review API
- Asking for feedback at appropriate times
- Responding to reviews in Play Console

**NOT Allowed:**
- Incentivizing reviews
- Review manipulation
- Fake reviews
- Review gating (only sending happy users to store)
- Purchasing reviews

### Legal Considerations

- Reviews must be genuine user experiences
- Cannot pay for reviews
- Cannot review your own app
- Cannot have employees leave reviews
- Must disclose any incentive (which invalidates the review)

---

## Part 6: Crisis Management

### Rating Drop Response Plan

If rating drops by 0.3+ stars in a week:

1. **Immediate Analysis**
   - Identify cause (bug? bad update? barber issue?)
   - Quantify scope of problem

2. **Response**
   - If bug: Hotfix priority, respond to all affected reviews
   - If barber issue: Investigate and resolve
   - If PR issue: Coordinate with communications

3. **Communication**
   - Respond to all negative reviews
   - Consider What's New update addressing issue
   - Email affected users if appropriate

4. **Prevention**
   - Post-mortem analysis
   - Process improvements
   - Monitoring enhancements

### Negative Review Surge

If 10+ negative reviews in 24 hours:

1. **All hands response** - Team reviews all complaints
2. **Pattern identification** - Find common thread
3. **Rapid response** - Reply to all within 4 hours
4. **Fix deployment** - If bug, emergency release
5. **Post-mortem** - Document and prevent recurrence

---

## Implementation Checklist

### Pre-Launch:
- [ ] Implement soft ask UI
- [ ] Integrate SKStoreReviewController (iOS)
- [ ] Integrate In-App Review API (Android)
- [ ] Set up trigger events
- [ ] Configure email review request flow
- [ ] Set up review monitoring tool
- [ ] Create Slack channel for reviews
- [ ] Train support team on response templates

### Launch:
- [ ] Enable review prompts
- [ ] Monitor daily
- [ ] Respond to all reviews
- [ ] Track baseline metrics

### Ongoing:
- [ ] Weekly review analysis
- [ ] Monthly theme report
- [ ] Quarterly strategy review
- [ ] Continuous template optimization
- [ ] A/B test prompt timing

---

## Appendix: Quick Reference

### Response Time SLAs

| Rating | Response Time |
|--------|---------------|
| 1 star | 4 hours |
| 2 stars | 24 hours |
| 3 stars | 48 hours |
| 4 stars | 72 hours |
| 5 stars | 1 week |

### Escalation Contacts

| Issue Type | Owner | Contact |
|------------|-------|---------|
| App bugs | Engineering Lead | [email] |
| Barber complaints | Operations | [email] |
| Payment issues | Finance | [email] |
| PR concerns | Communications | [email] |
| Legal issues | Legal | [email] |

### Key Metrics Dashboard

Track these metrics weekly:
1. Overall rating (iOS / Android)
2. Review count (total / new this week)
3. Response rate
4. Average response time
5. Sentiment trend
6. Top complaint themes
