# MOD-008: Image Moderation - Decision Document

> Status: **PENDING DECISION**
> Priority: BASSE (V2+)

---

## Purpose

Automatic image moderation detects inappropriate content (nudity, violence, hate symbols) **before** publication to:

1. **Protect users** from harmful content
2. **DSA Compliance** - EU requires platforms to moderate illegal content
3. **Reduce manual moderation** workload
4. **Maintain app store compliance** (Apple/Google policies)

---

## When to Implement

- Before public launch (mandatory for DSA)
- When user-generated images become significant
- Can be deferred if images are limited to profile photos only

---

## Available Solutions

### Option 1: Google Cloud Vision API

| Aspect | Details |
|--------|---------|
| **Service** | SafeSearch Detection |
| **Detects** | Adult, Violence, Racy, Medical, Spoof |
| **Pricing** | 1000 free/month, then $1.50/1000 |
| **Latency** | ~500ms |
| **Pros** | Well-documented, reliable, free tier |
| **Cons** | Requires GCP account, API key management |

```
POST https://vision.googleapis.com/v1/images:annotate
```

### Option 2: AWS Rekognition

| Aspect | Details |
|--------|---------|
| **Service** | Content Moderation |
| **Detects** | Explicit, Suggestive, Violence, Drugs |
| **Pricing** | $0.001/image |
| **Latency** | ~300ms |
| **Pros** | Fast, detailed categories |
| **Cons** | AWS account required, no free tier |

### Option 3: Azure Content Moderator

| Aspect | Details |
|--------|---------|
| **Service** | Image Moderation |
| **Detects** | Adult, Racy, Gory |
| **Pricing** | 5000 free/month, then $1/1000 |
| **Latency** | ~400ms |
| **Pros** | Good free tier, Microsoft ecosystem |
| **Cons** | Less granular than alternatives |

### Option 4: OpenAI GPT-4 Vision

| Aspect | Details |
|--------|---------|
| **Service** | Multi-modal analysis |
| **Detects** | Custom criteria (prompt-based) |
| **Pricing** | ~$0.01/image |
| **Latency** | ~2s |
| **Pros** | Flexible, can explain decisions |
| **Cons** | Slower, more expensive, overkill for basic moderation |

### Option 5: Self-hosted (NSFW.js / NudeNet)

| Aspect | Details |
|--------|---------|
| **Service** | Open-source models |
| **Detects** | Nudity, NSFW content |
| **Pricing** | Free (hosting costs only) |
| **Latency** | Depends on hardware |
| **Pros** | No API costs, full control, privacy |
| **Cons** | Requires ML infrastructure, less accurate |

---

## Recommendation

**Google Cloud Vision** for MVP:
- Free tier covers initial usage
- Simple integration
- Proven reliability

Consider **self-hosted** for scale (>100k images/month).

---

## Implementation Location

| Approach | Pros | Cons |
|----------|------|------|
| **Appwrite Function** | API key secure, centralized | Extra function to maintain |
| **Flutter client** | Simpler architecture | API key exposed in app |
| **Appwrite Storage hook** | Automatic on upload | Less control over flow |

**Recommended:** Appwrite Function triggered before storage upload.

---

## Decision Required

- [ ] Choose AI provider
- [ ] Define moderation thresholds (LIKELY vs VERY_LIKELY)
- [ ] Decide on rejection UX (block vs warn)
- [ ] Budget allocation

---

*Document created: 2026-01-22*
*Decision deadline: Before public launch*
