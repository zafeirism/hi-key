#Mood board for the main app

The below affect only the main app, not the keyboard extension. The extension remains as neutral as possible because it lives in 3rd-party host apps and we don’t want to fight their branding.

# 1. Color palette

### Core principle

> Dark-first, image-forward, accent-sparse.
> Color is *earned*, not ambient.

We’ll define **roles**, not just hex codes — this prevents misuse later.

---

## 🎨 Color Roles & Tokens

### Base / Surfaces (≈60%)

These create calm and disappear behind content.

| Role                   | Color     | Usage rules                 |
| ---------------------- | --------- | --------------------------- |
| **Background / Root**  | `#0F1115` | App background, always      |
| **Primary Surface**    | `#171A20` | Cards, sheets, modals       |
| **Secondary Surface**  | `#1E222B` | Grouped items, nested cards |
| **Divider / Hairline** | `#2A2F3A` | Separators, outlines only   |

**Rules**

- No gradients here
- Never pure black
- Backgrounds must be visually "quiet"

---

### Text & Icons (≈30%)

Hierarchy comes from **weight + opacity**, not color variety.

| Role                    | Color     | Notes                  |
| ----------------------- | --------- | ---------------------- |
| **Primary Text**        | `#E6E8EC` | Titles, main copy      |
| **Secondary Text**      | `#9AA1AD` | Descriptions, hints    |
| **Tertiary / Disabled** | `#6E7482` | Disabled states only   |
| **Icon Default**        | `#C7CBD4` | Matches text hierarchy |

**Rules**

- Never use accent color for body text
- Max 3 text tones on one screen

---

### Accent / Magic (≈10%)

This is the *hi-key* personality.

| Role                 | Color     | Usage                          |
| -------------------- | --------- | ------------------------------ |
| **Primary Accent**   | `#E4FF97` | CTA highlights, success states |
| **Secondary Accent** | `#B48CFF` | Creative / AI moments          |

**Rules (important)**

- Accent never used as background for large surfaces
- Accent appears **after user action**
- Accent should feel like feedback, not decoration

> If you’re unsure whether to use green — don’t.

---

### Status Colors (muted, optional)

| Status  | Color     |
| ------- | --------- |
| Error   | `#FF6B6B` |
| Warning | `#FFB86B` |
| Info    | `#6EA8FF` |

Muted saturation. No neon.

---

# 2. Typography system (SF-based, friendly but serious)

**SF Pro** for most text, plus **SF Compact Rounded**, used *selectively*.

Why:

- Friendlier curves
- iOS-native
- Doesn’t scream “kids app” if weights are disciplined

---

## Font Stack

- **Primary:** SF Pro (default)
- **Selectively:** SF Compact Rounded (e.g. in H1 headers, onboarding etc.)

---

## Type Scale (iOS-friendly, no drama)

Sizes are indicative - always use relative system sizes to follow user’s system settings.

| Role               | Size  | Weight   | Usage                        |
| ------------------ | ----- | -------- | ---------------------------- |
| **Display / Hero** | 28–32 | Semibold | Onboarding hero, big moments |
| **Title**          | 22–24 | Semibold | Section headers              |
| **Headline**       | 17–20 | Medium   | Card titles                  |
| **Body**           | 16    | Regular  | Main copy                    |
| **Caption**        | 14    | Regular  | Helper text                  |
| **Micro**          | 12    | Medium   | Tags, pills                  |

**Rules**

- Human, readable, modern
- Weight > color for hierarchy
- Avoid bold unless necessary
- Use **Semibold sparingly**
- Let spacing do the work

---

# 3. What kind of app should hi-key *feel* like?

This is a critical question — and the answer is **what it is *not***.

### ❌ Not a game

- No levels
- No scores
- No dopamine overload

### ❌ Not a creative studio

- No canvases
- No timelines
- No toolbars

### ❌ Not a productivity app

- No dashboards
- No tables
- No “projects”

---

## ✅ What it *is*

> A creative utility with taste.

The closest mental bucket:

- "Search, but creative"
- "GIF picker energy"
- "One action → one delight"

**Remember:** All action happens at the keyboard extension.
The main app is for onboarding, customizing and purchasing credits.
It needs to build trust, be supportive to the keyboard and get out of the way.

---

## Apps worth borrowing from (strategically)

These are *directional*, not visual clones:

- **Apple Music**
  → Calm surfaces, strong content framing
- **Pinterest**
  → Image-first hierarchy, low UI noise
- **Notion** (for restraint, not visuals)
  → Neutral system that gets out of the way
- **Arc**
  → Brand-led UI, confident dark mode
- **Instagram** (camera & creation flows only)
  → Fast creation, minimal friction

What to *avoid copying*:

- Midjourney
- Figma
- Adobe apps
- Anything “tool-heavy”

---

# 4. Interaction & motion

**Motion feels:**

- Fast
- Elastic
- Responsive
- Short (150–250ms)

**Avoid:**

- Cinematic easing
- Long fades
- Particle explosions

Think:

> “Tap → instant acknowledgement → result”

---

# 5. Iconography & shapes

- Rounded rectangles
- Soft corners (10–14pt radius)
- Icons: outline or light fill, never heavy

No skeuomorphism. No hard geometry.

---

# 6. Brand traits

**Personality**

- Instant
- Friendly
- Quietly powerful
- Casual confidence

**Visual Language**

- Dark-first
- Image-forward
- Accent-sparse
- Calm surfaces, playful moments

**Typography**

- Human, readable, modern
- Weight > color for hierarchy

**UI Feel**

- Not a game
- Not a studio
- A creative reflex
