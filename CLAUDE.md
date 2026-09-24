# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Product Context

**hi-key** is an iOS app with a custom keyboard extension that generates AI images from text prompts. Users open the keyboard in any app (iMessage, WhatsApp, etc.), describe a scene, and receive 4 AI-generated images within seconds.

Weekly subscriptions (Starter/Plus/Super) + consumable credit packs, sold through RevenueCat. 1 credit = 1¢ of underlying AI cost. Live on the App Store since 2026-05-13.

## Core Principle: Speed Is the Product

Delivering images as fast as possible is hi-key's key value proposition. Every step on the `/api/generate` critical path — and every client-side step between "tap generate" and "see images" — must be justified against this:

- Is the added overhead worth it?
- Does the **majority** of requests benefit, or only a minority?
- Can the work run in parallel with existing tasks instead of serially?
- For the rare/edge case, is it acceptable to pay extra cost (extra DB writes, refunds, undo work) **after** the fact rather than gating the happy path?

Default to optimizing for the 99% common case. Edge cases (errors, blocked prompts, refunds) can be slower and more complex if it keeps the hot path fast. Always start from this principle, then build from there.

## Monorepo Layout

| Path | Project | Deployed as | Details |
|---|---|---|---|
| `backend/` | Next.js 16 headless API (route handlers only) | Vercel → `https://app.hi-key.ai` | `backend/CLAUDE.md` |
| `ios/` | Xcode project: `hi` app + `hi-keyboard` extension | App Store (Xcode Cloud) | `ios/CLAUDE.md` |
| `website/` | Next.js 16 static marketing site | Vercel → `https://hi-key.ai` | `website/CLAUDE.md` |
| `private/` | **Git-ignored** business docs (may be absent) | — | `private/README.md` |

The three projects share no code and have independent toolchains — run `npm` commands from inside `backend/` or `website/`, and Xcode/`xcodebuild` from `ios/`. The history of the three former repos (`hi-key-web`, `hi-key-app`, `hi-key-website`) was merged in with `git filter-repo`, so `git log -- <path>` works across the move.

## Cross-Project Contracts

- **HTTP API** — `backend/app/api/**/route.ts` ↔ `ios/hi/APIClient.swift` (request/response models live alongside `APIClient`). Changing a request or response shape means changing both sides in the same change; the App Store build in users' hands must keep working, so prefer additive changes.
- **Auth** — the app signs users in anonymously with Supabase; the keyboard shares the session via the `group.ai.hi-key` App Group. The backend verifies the Supabase JWT via JWKS (`backend/lib/auth/jwt.ts`).
- **Brand/design tokens** — the same palette lives in `ios/hi/Theme/HiTheme.swift` and the website's Tailwind theme. `ios/hi/mood-board.md` is the design source of truth for both.
- **Legal pages** — the privacy policy and terms at `website/src/app/{privacy,terms}` must match what the backend actually does (e.g. prompt/image retention in `backend/lib/cleanup/`) and what the app links to.

## Private Docs

`private/` is git-ignored and holds business context that isn't published: pricing rationale and unit economics, the full credits/RevenueCat spec, App Store submission notes. See `private/README.md` for the index. Read the relevant file before touching credits, purchases, pricing, or App Store metadata. It may not exist (e.g. a fresh clone) — if so, work from the code.

## This Repo Is Public

The GitHub repo is public. Before committing:

- **Never commit secrets.** Server keys live in each project's `.env.local` (git-ignored) and in Vercel env vars. Add new variables to the project's `.env.example` with an empty value.
- **Client-side keys are fine** — the Supabase URL + publishable key, RevenueCat `appl_` key, PostHog `phc_` key and Sentry DSN ship in the app binary anyway. Security comes from the server: Supabase RLS (enabled on every table with no policies — only the backend's service-role key can read/write), EXECUTE on RPCs revoked from `anon`/`authenticated`, signed webhooks, QStash signature verification.
- **No auth bypasses.** Don't add hardcoded tokens that skip JWT verification or credit logic. The only special token is `WARMUP_TOKEN`, which returns a no-op 200 and never reaches a handler.
- **Business-sensitive writing** (margins, pricing strategy, country/ARPU decisions, user data) goes in `private/`, not in committed docs, code comments or commit messages.
- Scan before pushing: `gitleaks git .` (history) and `gitleaks dir .` (working tree, includes ignored files — expect hits in `.env.local`/`.next`, which are ignored).

## Deployment

- **Vercel** — two projects connected to this repo, Root Directory `backend` and `website` respectively. This isn't an npm-workspaces monorepo, so Vercel's automatic "skip unaffected projects" doesn't apply; each project instead has a custom **Ignored Build Step** (runs inside the root directory, exit 0 = skip): `[ -n "$VERCEL_GIT_PREVIOUS_SHA" ] && git diff --quiet "$VERCEL_GIT_PREVIOUS_SHA" HEAD -- .`
- **Xcode Cloud** — builds `ios/hi.xcodeproj`; `ios/ci_scripts/ci_post_clone.sh` (must stay next to the `.xcodeproj`) stamps the build number.
- **Supabase** — migrations in `backend/supabase/migrations/`; run the Supabase CLI from `backend/`. Dev vs prod workflow in `backend/CLAUDE.md`.
- **QStash** — schedules `backend`'s `/api/cron/cleanup` every 15 minutes and delivers `/api/worker` jobs.
