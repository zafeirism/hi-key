# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Marketing website for **hi-key** at `https://hi-key.ai` — part of the hi-key monorepo (see the root `CLAUDE.md` for product context). Users open the keyboard in any app (iMessage, WhatsApp, Instagram, etc.), describe a scene, and receive 4 AI-generated images within seconds that can be copied anywhere. The site's job: **"confirm this is the app that made that image → download it."**

**App positioning:** A creative utility keyboard — not a design tool, not a creative studio. One action, one delight. Works invisibly inside other apps.

## Commands

Run from `website/`:

- `npm run dev` — Start dev server
- `npm run build` — Production build (fully static)
- `npm run lint` — ESLint

## Product Context

### Core Value Proposition

"Generate AI images instantly from your keyboard in any app"

### Key Benefits

- **Instant** — 4 images in seconds, fast enough to send in the moment
- **Everywhere** — works in iMessage, WhatsApp, Instagram, any text input
- **Simple** — describe what you want, copy the result
- **Privacy-first** — no accounts; prompts and images are deleted from our servers in less than an hour

### Pricing on the site

Keep pricing abstract in site copy ("packs and subscriptions start under a dollar", "free trial") — exact prices and credit counts live in the App Store listing and change independently of the site. Pricing rationale and unit economics are in `../private/pricing-and-unit-economics.md` (git-ignored, may be absent); never put margins or business strategy in site copy or committed docs.

### Brand Personality

- Instant, friendly, quietly powerful, casual confidence
- Not tool-heavy, not AI-forward. It's a creative reflex
- Solo creator energy: made by one person, for fun, and it shows
- The product doesn't take itself too seriously, but it works seriously well

**Voice characteristics:**

- Lowercase by default. Capital letters feel corporate; lowercase feels like texting a friend.
- Short sentences. Periods over commas when you want weight. "It applies to every purchase. Forever." hits harder than a long clause.
- Confident without exclaiming. Avoid "!" in product copy. Let the statement land on its own.
- Concrete over abstract. "Buy 100 credits, get 200" beats "double your value."
- Honest over polished. "hi-key is fun to have, not a commitment" beats "the ultimate creative companion."
- Playful but not goofy. Wit is welcome, silliness is not.

**hi-key sounds like:**

- "Your keyboard just learned to draw."
- "It's like sending a GIF, but personal and unique."
- "hi-key is fun to have, not a commitment."
- "Early members get 2× credits. Forever."
- "Your keyboard is about to get a lot more fun."
- "made with fun by zaf" (footer)

**hi-key does NOT sound like:**

- "Unleash your creativity with AI-powered image generation!" (too corporate, too loud)
- "The ultimate AI image tool for professionals" (too tool-heavy, too serious)
- "Powered by state-of-the-art diffusion models" (too technical, nobody cares)
- "Create stunning, breathtaking visuals in seconds!" (too hyperbolic, too many adjectives)
- "We're revolutionizing the way you communicate" (too startup-speak)
- "Start your creative journey today!" (too generic, too CTA-heavy)

**Pronouns:**

- Product copy uses "we" (convention, not deception). "We'll let you know" reads naturally even from a solo creator.
- Personal sign-offs use "I/me". The footer says "made with fun by zaf", emails are signed "— zaf", and "follow me on X" is natural next to a personal signature.
- Never mix them awkwardly. Don't say "I built hi-key and we value your privacy" in the same breath.

## Design System

### Philosophy

Dark-first, image-forward, accent-sparse. Color is earned, not ambient.

### Color Palette

**Surfaces:** `#0F1115` (root bg), `#171A20` (primary surface), `#1E222B` (secondary surface), `#2A2F3A` (divider)
**Text:** `#E6E8EC` (primary), `#9AA1AD` (secondary), `#6E7482` (tertiary)
**Icons:** `#C7CBD4`
**Accents:** `#E4FF97` (lime — primary), `#B48CFF` (purple — secondary, AI moments)
**Status:** `#FF6B6B` (error), `#FFB86B` (warning), `#6EA8FF` (info)

### Typography

- Primary: system sans-serif (SF Pro equivalent on web — Inter or similar)
- Use weight over color for hierarchy; avoid heavy bold
- Scale: Hero (28-32px), Title (22-24px), Headline (17-20px), Body (16px), Caption (14px), Micro (12px)

### Visual Language

- Soft rounded rectangles (10-14px radius)
- No gradients in backgrounds
- No skeuomorphism, no hard geometry
- Image-forward hierarchy, low UI noise
- Fast, elastic motion (150-250ms transitions)
- Fixed dark mode — the site should always be dark

### Design Inspirations

Borrow from: Apple Music (calm surfaces), Pinterest (image-first hierarchy), Arc (confident dark mode), Notion (restraint).
Avoid: Midjourney, Figma, Adobe — anything tool-heavy.

## Copywriting Reference

### Style Rules

- **No em-dashes (—)** in any user-facing copy. Use commas, periods, colons, or restructure the sentence instead. E.g. "iMessage, WhatsApp, Instagram DMs" not "iMessage — WhatsApp — Instagram DMs". Use "like" before lists to avoid needing a dash: "any app with a text input, like iMessage, WhatsApp..."
- **No exclamation marks** in product copy or headings. Reserve them only for success states ("You're in!") where excitement is earned.
- **Sentence case** for headings and CTAs, not Title Case. "Ready to try it?" not "Ready To Try It?"
- **Avoid superlatives and hype words.** No "stunning", "revolutionary", "ultimate", "unleash", "game-changing", "breathtaking." Let the product speak.
- **Prefer specifics over abstractions.** "4 images in seconds" over "lightning-fast generation." "Buy 100, get 200" over "double your credits."
- **Period for emphasis.** A short sentence followed by a period hits harder than a comma-joined clause. "It applies to every purchase. Forever." not "It applies to every purchase, forever."
- **Platform mentions:** Don't lead with "iOS" unless the context requires disambiguation. The product is for iPhone users, but the copy should lead with what it does, not what it runs on. Mention iPhone/iOS naturally when it fits (e.g. "any app you use on iPhone").

### Taglines (from onboarding)

- "Picture this: instant AI images wherever you type"
- "It's a keyboard and it works in any app"
- "Describe a scene and get a few images instantly"
- "Images fast enough to send in the moment"

### Privacy Messaging

Keep any privacy claim consistent with the privacy policy ("deleted from our servers in less than an hour").

- "We value your privacy"
- "Your prompts are processed securely and not stored after generation"
- "We never send passwords, messages, or other content"

### Paywall Copy

- "Keep your creativity flowing"
- "Never run out of credits"
- "No commitment, cancel anytime"

### FAQ sync rule

FAQ content lives in two places that must stay in sync:

1. The page component (user-facing accordion)
2. The `jsonLdFaq` object in `layout.tsx` (structured data for search engines)

When updating FAQ copy, always update both locations in the same change.

### FAQ Copy Patterns

- Answer in the user's language, not marketing-speak. If someone asks "Can I try hi-key for free?" don't dodge it.
- Use the FAQ as a place to be direct and human. It's the one section where personality can come through most naturally.
- Compare to competitors by name when it helps (e.g. "Nano Banana", "ChatGPT") but frame it respectfully: "they're great, but..." not "unlike our inferior competitors."
- The last FAQ can break format for personality. "I don't like spam, accounts, or subscriptions. Is hi-key for me?" works as a question because it voices real objections.

### Reserved FAQ drafts (not yet live)

**"Why use hi-key if I already have Nano Banana or ChatGPT?"** — previously on the landing page, temporarily removed pending confirmation that multi-model integration (users choosing between Nano Banana, ChatGPT-class models, and others inside hi-key) is engineering-feasible for launch. When that's confirmed, add this entry back to both `faq.tsx` and `jsonLdFaq` in `layout.tsx`:

> These are great tools. And inside hi-key, you can actually use them, alongside a lot of other models. The difference is the experience. Opening a separate app and waiting up to a minute for a single image doesn't work mid-conversation. hi-key lives inside the app you already have open, no switching, no waiting. You can generate 4 images in seconds using fast models, so you pick one and keep going. When you want something more polished, switch models right from the keyboard. It's like sending a GIF, but personal and unique.

### Email Copy

- Emails are signed "— zaf" (personal, not brand).
- Keep emails short: one key message, one secondary note, sign-off. No walls of text.
- "Follow me on X" (not "follow us") because it sits next to a personal signature.
- Reinforcing offers in email is fine but keep it to one line, not a feature table.

## Implementation

`IMPLEMENTATION.md` is the original technical plan (stack rationale, page structure, SEO and AI-discoverability strategy — llms.txt, GEO, performance targets). Parts of it predate launch; the code is the source of truth.

### Current Stack

- Next.js 16 (App Router, fully static — no API routes) + Tailwind CSS v4 + shadcn/ui
- Fonts: Inter (body via `next/font`), Nunito (headings via `font-heading` class)
- OG image: static PNG at `public/og-image.png` (1200×630), referenced in layout.tsx metadata
- SEO: JSON-LD (MobileApplication, WebSite, FAQPage), sitemap.ts, robots.txt, llms.txt
- Animations: CSS `fade-up` class + Intersection Observer (`FadeUp` component), Lottie for feature cards, lazy-loaded MP4s
- App Store: `APP_STORE_URL` in `src/components/app-store-badge.tsx`; app id `6762464437` also in `layout.tsx` (Smart App Banner) and `public/llms.txt`

### Legal pages

`src/app/privacy/page.tsx` and `src/app/terms/page.tsx` are linked from the app and App Store listing. Claims there (e.g. "prompts and images deleted in less than an hour", the list of processors) must match what `../backend/` actually does — check `../backend/lib/cleanup/` and the backend's external services before editing either side.

### Waitlist (retired)

Before launch the site collected waitlist emails (Supabase `waitlist` table, Upstash rate limiting, Resend confirmation email). Signups closed at launch and the route was removed; waitlist members redeem their claim codes in the app (see `../backend/CLAUDE.md`).

### Open ideas

- Social proof section — App Store rating, review count, press mentions (when available)
- `aggregateRating` in the MobileApplication JSON-LD once reviews exist
- A/B test ideas: `EXPERIMENTS.md`

## Related Projects

- **iOS app:** `../ios/` — see `../ios/CLAUDE.md` and `../ios/hi/mood-board.md` for deeper design context. Design tokens here mirror `../ios/hi/Theme/HiTheme.swift`.
- **Backend:** `../backend/` — `https://app.hi-key.ai` (Next.js / TypeScript). Stack: Supabase (auth/db), Cloudflare R2 (images), OpenAI (prompt analysis), Replicate (image generation), RevenueCat (payments).
