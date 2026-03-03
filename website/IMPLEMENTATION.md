# Implementation Plan

Detailed technical decisions, page structure, and SEO/discoverability strategy for the hi-key marketing website.

## Tech Stack

| Layer      | Choice                         | Rationale                                                                                              |
| ---------- | ------------------------------ | ------------------------------------------------------------------------------------------------------ |
| Framework  | Next.js 15 (App Router)        | Backend is already Next.js on Vercel — one framework, one deployment pipeline, shared knowledge        |
| Rendering  | Static (default in App Router) | No dynamic data on the landing page; static = fastest possible load                                    |
| Styling    | Tailwind CSS v4                | First-class dark mode, total design control, CSS variables for brand tokens                            |
| Components | shadcn/ui                      | Accessible primitives (nav, dialogs, accordions) we fully own and restyle — not for marketing sections |
| Hosting    | Vercel                         | Already hosting the backend; first-party Next.js optimizations (image, font, analytics)                |
| Images     | `next/image`                   | Automatic WebP/AVIF, lazy loading, priority flag for hero                                              |
| Fonts      | `next/font` (Inter or similar) | Self-hosted, zero layout shift, no external requests                                                   |
| Theme      | Forced dark mode               | `class="dark"` on `<html>`, no toggle — matches the app's fixed dark mode                              |

### Why Next.js over Astro

Astro ships zero JS by default and is ~40% faster for pure static content. However:

- The backend is already Next.js on Vercel — operational simplicity wins
- App Router pages are static by default when there's no dynamic data
- Vercel has first-party optimizations exclusively for Next.js (`next/image`, `next/font`, Speed Insights)
- For a single landing page, the performance difference is negligible

### shadcn/ui Usage

Use for: navigation menu, mobile sheet/drawer, accordion (FAQ), dialogs, toast notifications.
Do NOT use for: hero section, feature cards, pricing table, testimonials — these are custom Tailwind markup to match hi-key's brand exactly.

## Page Structure

Single-page landing. The site's job: **"confirm this is the app that made that image → download it."**

### Section 1: Hero

- Benefit-driven headline (e.g., "AI images, right from your keyboard")
- 1-2 sentence subtitle explaining the concept
- App Store badge (primary CTA)
- Short demo animation showing the keyboard generating images
- Apple Smart App Banner auto-shows in Safari on iOS

### Section 2: Social Proof (add later when we have it)

- App Store rating (stars + review count)
- Download count
- Press mentions / "Featured by Apple" badges
- _Can be minimal or omitted at launch, expanded post-traction_

### Section 3: How It Works

- 3-step visual walkthrough — critical because the concept is novel:
  1. Enable the keyboard
  2. Type what you want to see
  3. Get 4 images, copy and send
- Each step: icon/illustration + short label + one-line description

### Section 4: Feature Highlights

2-3 key features with visuals:

- **Works in any app** — logos of iMessage, WhatsApp, Instagram, etc.
- **4 images in seconds** — speed/instant gratification
- **Privacy-first** — prompts never stored, no personal data collected

### Section 5: Pricing (optional, add later)

- Simple tier comparison table
- Free tier emphasized to reduce friction
- Link to App Store for subscription management

### Section 6: Download CTA (repeated)

- App Store badge + phone mockup
- Reinforcing headline
- Sticky mobile CTA bar that stays visible while scrolling

### Section 7: FAQ

Serves dual purpose: answers real user questions + provides structured content for AI search engines (Google AI Overviews, ChatGPT, Perplexity). Include `FAQPage` JSON-LD schema.

**Q: What is hi-key?**
A: hi-key is an iOS keyboard that generates AI images from text prompts. You type a description of what you want to see, and hi-key creates 4 images in seconds — right inside any app you're already using.

**Q: How does hi-key work?**
A: Enable hi-key as a keyboard on your iPhone, switch to it in any app with a text field, type a description (e.g., "a cat wearing sunglasses on a beach"), and get 4 AI-generated images instantly. Tap any image to copy it to your clipboard.

**Q: Which apps does hi-key work in?**
A: hi-key works in any app that has a text input — iMessage, WhatsApp, Instagram DMs, Telegram, Slack, Notes, email, and more. It's a system keyboard, so it's available everywhere you type.

**Q: Is hi-key free?**
A: Yes, hi-key is free to download and comes with 5 credits to start. Each credit generates 4 images. Subscription plans start at $4.99/month for more credits, and one-time credit packs are available from $2.99.

**Q: Is hi-key safe? Can it read my messages?**
A: hi-key only processes the prompts you type in the hi-key prompt bar. It never reads, stores, or sends your messages, passwords, or any other content. Prompts are processed securely and not stored after image generation.

**Q: What does the hi-key watermark mean?**
A: Images generated on the free and lower-tier plans include a small "hi-key" watermark. If you received an image with this watermark, someone used hi-key to create it. The Super plan ($12.99/month) removes watermarks.

**Q: How do I get more credits?**
A: You can subscribe to a monthly plan (Starter, Plus, or Super) for recurring credits, buy one-time credit packs, or invite friends with your referral code — you both get 5 bonus credits.

### Section 8: Footer

- Links: Privacy Policy, Terms of Service, Support/Contact
- Social media links
- Copyright notice

## SEO & Meta Tags

### Page Metadata (via Next.js `metadata` export)

```tsx
export const metadata: Metadata = {
  title: "hi-key — AI Images From Your Keyboard",
  description:
    "Generate AI images instantly from your keyboard in any app. Describe a scene, get 4 images in seconds. Works in iMessage, WhatsApp, Instagram, and more.",
  openGraph: {
    title: "hi-key — AI Images From Your Keyboard",
    description: "Generate AI images instantly from your keyboard in any app.",
    url: "https://hi-key.ai",
    siteName: "hi-key",
    images: [
      { url: "https://hi-key.ai/og-image.png", width: 1200, height: 630 },
    ],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "hi-key — AI Images From Your Keyboard",
    description: "Generate AI images instantly from your keyboard in any app.",
    images: ["https://hi-key.ai/og-image.png"],
  },
  itunes: {
    appId: "YOUR_APP_STORE_ID", // enables Apple Smart App Banner in Safari
  },
};
```

### JSON-LD Structured Data

Include in `layout.tsx` via `<script type="application/ld+json">`:

```json
[
  {
    "@context": "https://schema.org",
    "@type": "MobileApplication",
    "name": "hi-key",
    "description": "Generate AI images instantly from your keyboard in any app.",
    "operatingSystem": "iOS",
    "applicationCategory": "UtilitiesApplication",
    "offers": {
      "@type": "Offer",
      "price": "0",
      "priceCurrency": "USD"
    },
    "downloadUrl": "https://apps.apple.com/app/hi-key/idYOUR_APP_ID",
    "image": "https://hi-key.ai/app-icon.png",
    "author": {
      "@type": "Organization",
      "name": "hi-key",
      "url": "https://hi-key.ai"
    }
  },
  {
    "@context": "https://schema.org",
    "@type": "WebSite",
    "name": "hi-key",
    "url": "https://hi-key.ai"
  }
]
```

Add `aggregateRating` and `screenshot` fields once the app is live with reviews.

### Apple Smart App Banner

Handled via `metadata.itunes.appId` in Next.js — generates:

```html
<meta name="apple-itunes-app" content="app-id=YOUR_APP_ID" />
```

Shows a native Safari banner on iOS with the app icon, name, rating, and "View" / "Open" button. No customization needed — Apple controls the appearance.

## AI Discoverability

### llms.txt

Place at `public/llms.txt`:

```markdown
# hi-key

> AI image generation keyboard for iOS. Generate images from text prompts directly in any app — iMessage, WhatsApp, Instagram, and more.

## Pages

- [Home](https://hi-key.ai/): Landing page with app overview, features, and download links
- [Privacy Policy](https://hi-key.ai/privacy): Privacy policy
- [Terms of Service](https://hi-key.ai/terms): Terms of service
- [Support](https://hi-key.ai/support): Customer support

## App

- [App Store](https://apps.apple.com/app/hi-key/idYOUR_APP_ID): Download hi-key for iOS
```

~844K websites have adopted llms.txt. No major AI platform has officially confirmed reading it, but the cost is one file and it future-proofs the site.

### robots.txt

Place at `public/robots.txt`:

```
User-agent: *
Allow: /

User-agent: GPTBot
Allow: /

User-agent: ClaudeBot
Allow: /

User-agent: PerplexityBot
Allow: /

User-agent: Google-Extended
Allow: /

Sitemap: https://hi-key.ai/sitemap.xml
```

### Sitemap

Generate via `app/sitemap.ts`:

```tsx
export default function sitemap() {
  return [
    { url: "https://hi-key.ai", lastModified: new Date(), priority: 1.0 },
    {
      url: "https://hi-key.ai/privacy",
      lastModified: new Date(),
      priority: 0.3,
    },
    { url: "https://hi-key.ai/terms", lastModified: new Date(), priority: 0.3 },
  ];
}
```

### GEO (Generative Engine Optimization)

To maximize chances of appearing in AI-generated answers (ChatGPT, Perplexity, Google AI Overviews):

- **Semantic HTML**: Use proper `<h1>`, `<h2>`, `<p>`, `<ul>` — not divs-for-everything
- **Answer capsules**: Write clear, self-contained sentences that AI can excerpt (e.g., "hi-key is an iOS keyboard that generates AI images from text prompts in any app")
- **FAQ section**: Question-and-answer format with `FAQPage` JSON-LD schema — AI models love this
- **Structured data**: `MobileApplication` schema (above) helps AI understand what hi-key is
- **Fast, accessible, mobile-friendly**: Lighthouse score > 90, proper heading hierarchy, alt text on images

## Performance Targets

| Metric                          | Target  | How                                                                   |
| ------------------------------- | ------- | --------------------------------------------------------------------- |
| LCP (Largest Contentful Paint)  | < 1.5s  | Static rendering, `next/image` with `priority` on hero, preload fonts |
| INP (Interaction to Next Paint) | < 100ms | Minimal client JS, Server Components by default                       |
| CLS (Cumulative Layout Shift)   | 0       | `next/font`, explicit image dimensions, no dynamic content injection  |
| Lighthouse Performance          | > 95    | All of the above                                                      |

### Performance tactics

- Keep landing page components as Server Components — only add `'use client'` for interactive elements (mobile nav, video players)
- Use `loading="eager"` and `priority` on hero image
- Use `next/font` with `display: 'swap'` for zero layout shift from fonts
- Vercel Edge Network provides global CDN automatically
