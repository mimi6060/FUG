# MOD-009: Monetisation Ethique - Decision Document

> Status: **PENDING DECISION**
> Priority: BASSE (V2+)

---

## What is "Monetisation Ethique"?

**Ethical monetization** means generating revenue while:

1. **Respecting user privacy** - No selling data, no invasive tracking
2. **Being transparent** - Clear about what users pay for
3. **Avoiding manipulation** - No dark patterns, no pay-to-win
4. **RGPD compliant** - Legal under EU regulations
5. **Adding real value** - Premium features genuinely useful, not artificial limits

---

## Why Not Traditional Models?

### Advertising (Rejected)

| Problem | Explanation |
|---------|-------------|
| RGPD complexity | Targeted ads require consent, tracking infrastructure |
| User experience | Ads interrupt social interactions |
| Brand alignment | Alcohol-adjacent app + ads = liability risk |
| Revenue | Low CPM for social apps (~$1-3) |

### Freemium with Paywalls (Rejected)

| Problem | Explanation |
|---------|-------------|
| Frustration | Blocking core features annoys users |
| Churn | Users leave instead of paying |
| Social imbalance | Paying users have unfair advantage |

---

## Proposed Model: FUG Premium

### Pricing

| Plan | Price | Discount |
|------|-------|----------|
| Monthly | 4.99 EUR | - |
| Annual | 39.99 EUR | 33% off |

### Features Comparison

| Feature | Free | Premium |
|---------|------|---------|
| Create events | 3/month | Unlimited |
| Join events | Unlimited | Unlimited |
| See profile visitors | No | Yes |
| Exclusive badges | No | Yes |
| Priority support | No | Yes |
| Advanced statistics | Basic | Detailed |
| Boost event visibility | No | 1/week |
| Ad-free experience | No | Yes |

### Key Principle

**Core social features remain free.** Premium adds convenience and visibility, not unfair advantages.

---

## Alternative Revenue Streams

### Partner Bars/Venues (V3)

- Venues pay for "Partner" badge
- Special offers for FUG users
- Clearly labeled as sponsored
- No manipulation of event rankings

### Sponsored Badges (V3+)

- Brands sponsor achievement badges
- Example: "Craft Beer Explorer" by local brewery
- Must align with app values
- No alcohol brand direct sponsorship

---

## What We Will NEVER Do

| Practice | Why Not |
|----------|---------|
| Sell user data | Illegal (RGPD), unethical |
| Behavioral advertising | Privacy violation, complex compliance |
| Pay-to-win mechanics | Destroys community trust |
| Dark patterns | Against app store guidelines, unethical |
| Hidden fees | Breaks user trust |
| Artificial scarcity | Manipulative, frustrating |

---

## Implementation Requirements

### Technical

- RevenueCat or similar for subscription management
- App Store / Play Store in-app purchases
- Appwrite user attribute for premium status
- Feature flags for premium features

### Legal

- Clear terms of service
- Cancellation policy (easy to cancel)
- Refund policy
- Price display compliance (EU)

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Free to Premium conversion | 2-5% |
| Premium retention (12 months) | 60% |
| Average revenue per user | 0.50 EUR/month |
| Premium satisfaction | 4.5/5 stars |

---

## Decision Required

- [ ] Confirm pricing strategy
- [ ] Define premium feature set
- [ ] Choose subscription provider (RevenueCat, Qonversion, etc.)
- [ ] Legal review of terms
- [ ] Timeline for V2 launch

---

## Timeline

| Phase | Features | Version |
|-------|----------|---------|
| 1 | Basic Premium subscription | V2 |
| 2 | Partner venues program | V3 |
| 3 | Sponsored badges | V3+ |

---

*Document created: 2026-01-22*
*Decision deadline: Before V2 planning*
