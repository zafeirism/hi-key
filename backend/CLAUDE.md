# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Product context and the **Speed Is the Product** principle live in the root `CLAUDE.md` — read it first. It applies most strongly here: every step on the `/api/generate` critical path must justify itself against time-to-image.

## Project Overview

`backend/` is the hi-key API: a Next.js 16 (App Router) project with route handlers only — no pages or UI. Deployed on Vercel at `https://app.hi-key.ai`. The iOS app (`ios/hi/APIClient.swift`) calls it with Bearer token auth (Supabase JWT) and auto-retries on 401. The other projects in the monorepo are `../ios/` (the only API client) and `../website/`.

## Commands

- `npm run dev` — Start dev server
- `npm run build` — Production build
- `npm run lint` — ESLint
- `npm run test` — Vitest in watch mode
- `npm run test:run` — Vitest single run
- `npx vitest run path/to/file` — Run a single test file
- `npm run types:generate` — Regenerate Supabase types from remote schema

## Architecture

### Request Flow

1. **`/api/generate`** — Main endpoint. Authenticated mobile client sends a prompt. The route:
   - Creates 4 generation records in Supabase (3 immediate + 1 background)
   - Rejects blocklisted prompts synchronously (`lib/moderation/blocklist.ts`), then debits the reserved credits
   - Runs prompt analysis in parallel: `hasStyle()` + `proofread()` + OpenAI moderation (a flagged prompt marks the rows `blocked`, refunds, and returns 403)
   - Dispatches 3 image generations to Replicate immediately
   - Sends the 4th to **`/api/worker`** via QStash for background processing
   - Returns pre-signed R2 URLs to the client

2. **`/api/worker`** — QStash-triggered background worker. Receives a generation ID, upsamples the prompt (more creative rewrite via OpenAI) and dispatches to Replicate.

3. **`/api/webhooks/replicate`** — Replicate calls this when image generation completes. Downloads the image, uploads to R2, updates generation status to `ready` in Supabase.

4. **`/api/autocomplete`** — Returns prompt autocomplete suggestions via OpenAI.

5. **`/api/warmup`** — Unauthenticated; the keyboard calls it on open, before it has refreshed its token. Warms up all endpoints and external connections (Supabase, QStash, Replicate webhook). Internal calls use `WARMUP_TOKEN`, which `withAuth` answers with a no-op 200 without running the handler. The fan-out is throttled per instance (once per 60s).

6. **`/api/referral`** — `POST` creates the user's immutable referral code from a name (`NAME-XXXXXX`, Crockford Base32 suffix). Idempotent: returns the existing code on subsequent calls.

7. **`/api/referral/redeem`** — `POST` during onboarding. Validates a code, atomically marks the redeemer's `referred_by`, and grants 500 mills (50 credits) to both sides. One-shot per redeemer (409 on retry with a different code). See `../private/backend-purchases.md` for the redeem flow.

8. **`/api/me/claim-code`** — `POST` with `{ code }`. Applies a waitlist claim code: marks the waitlist row as claimed, sets `user_profiles.double_credits = true` (all future sub renewals and pack purchases grant 2x), and tops up the current sub balance by one full tier so the remainder of the active cycle is effectively doubled. One-shot per user (409 `already_doubled` on retry with a different code).

9. **`/api/cron/cleanup`** — QStash-scheduled (every 15 min). Finds `generations` rows older than 30 minutes that still have a `user_prompt`, deletes the corresponding R2 image objects in a single batch, and NULLs `user_prompt` + `improved_prompt`. Bounded at 500 rows per run; the next run picks up any remainder. Privacy posture: prompts and images are retained for under one hour, then permanently removed. Cloudflare R2 also has a 1-day lifecycle rule on `users/*` as a belt-and-braces safety net.

### Key Modules

- **`lib/auth/jwt.ts`** — `withAuth()` HOF for JWT-authenticated routes. Verifies Supabase JWTs via JWKS. `WARMUP_TOKEN` short-circuits to a no-op 200 — never add tokens that reach a handler without a verified user.
- **`lib/ai/image-generator.ts`** — Dispatches predictions to Replicate with retry logic.
- **`lib/ai/image-models.ts`** — `ImageModelsEnum` and `IMAGE_MODEL_SETUPS` define every Replicate model configuration (GPT Image, Nano Banana, FLUX variants) with its per-image cost in mills. Which models `/api/generate` and `/api/worker` use is chosen in those routes.
- **`lib/moderation/`** — `checkBlocklist()` (synchronous, first line) and `moderateWithOpenAI()` (fail-open, runs in parallel with the rest of prompt analysis).
- **`lib/ai/prompt-upsampler.ts`** — OpenAI-powered creative prompt rewriting for the background generation.
- **`lib/ai/proofread.ts`** / **`lib/ai/detectPromptStyle.ts`** — Prompt preprocessing (grammar fix, style detection).
- **`lib/storage/r2.ts`** — Cloudflare R2 operations via AWS S3 SDK. Images stored at `users/{userId}/images/{generationId}.{ext}`. `deleteImages(keys)` batch-deletes up to 1000 keys per call.
- **`lib/cleanup/cleanup.ts`** — `cleanupOldGenerations()` for the privacy retention cron. NULLs prompt fields and deletes R2 objects for rows past the retention cutoff.
- **`lib/qstash/backgroundScheduler.ts`** — QStash client for dispatching background work.
- **`lib/supabase/`** — Supabase admin client and generated types. Run `npm run types:generate` after schema changes.
- **`lib/credits/`** — Credits system. `catalog.ts` maps RC product IDs to mill amounts; `balance.ts` wraps the `debit_credits`/`grant_credits`/`reset_sub_credits` RPCs and exposes `InsufficientCreditsError`; `webhook.ts` routes RC events to balance mutations. Mills are the internal unit (1 credit = 10 mills); `toDisplayCredits()` converts for client responses.
- **`lib/referrals/`** — Referral system. `code.ts` has `sanitizeName` and Crockford Base32 suffix generation; `service.ts` wraps the `redeem_referral` RPC and exposes `InvalidNameError`, `InvalidCodeError`, `CodeNotFoundError`, `SelfReferralError`, `AlreadyRedeemedError`. Referral fields live on `user_profiles` alongside credit balances.
- **`lib/waitlist/`** — Waitlist claim codes. `code.ts` generates/validates `HI-XXXXXXXX` (8-char Crockford Base32) codes; `service.ts` wraps the `claim_waitlist_code` RPC and exposes `InvalidCodeError`, `CodeNotFoundError`, `AlreadyClaimedError`, `AlreadyDoubledError`. Applying a code sets `user_profiles.double_credits = true` (persists forever) and adds one tier's worth of sub credits for immediate impact.

### External Services

- **Replicate** — Image generation (GPT Image, Nano Banana, FLUX — see `lib/ai/image-models.ts`)
- **Supabase** — Database (generations, waitlist tables) + auth (JWT verification via JWKS)
- **Cloudflare R2** — Image storage (S3-compatible), signed URLs valid 7 days
- **Upstash QStash** — Background job queue (worker endpoint verification via signature)
- **OpenAI** — Prompt processing (autocomplete, proofreading, upsampling)
- **RevenueCat** — Subscription & purchase source of truth. The iOS app calls `Purchases.logIn(supabaseUserId)` after auth, and RC posts events to `/api/webhooks/revenuecat` (auth via `Bearer $REVENUECAT_WEBHOOK_TOKEN`). Idempotent on `event.id`.

## Code Conventions

- Path alias: `@/*` maps to project root
- Prettier: single quotes, semicolons, 100 char print width, trailing commas (es5)
- TypeScript strict mode with `noUncheckedIndexedAccess`
- React Compiler enabled (`reactCompiler: true` in next.config.ts)
- ESLint: `no-explicit-any` is off, `no-console` warns (except warn/error), unused vars warn with `_` prefix exception
- Tests use Vitest with jsdom environment; integration tests use `*.integration.test.ts` naming and load `.env.local`
- Tests co-located with source in `__tests__/` directories
- Generation status lifecycle: `initializing` → `generating` → `ready` | `error`

## Supabase Projects & Migrations

Two Supabase projects exist — **always verify which one is linked before running `db push`**.

| Environment | Project Ref | Usage |
|-------------|-------------|-------|
| **Dev** | `rtmrehcevyoqafyscpaj` (hi-key-dev) | Day-to-day development and testing |
| **Prod** | `lsssxrudfajjfidqbngl` (hi-key-production) | Production database |

- `npm run types:generate` is hardcoded to the **dev** project in `package.json`
- `npx supabase db push` targets whichever project is **linked** — check with `npx supabase projects list` (the `●` marker)
- The `2>/dev/null` in the `types:generate` script suppresses CLI version warnings that would otherwise pollute the generated types file

### Migration Workflow

Run all Supabase CLI commands from `backend/` (the `supabase/` folder lives here).

1. Create migration SQL in `supabase/migrations/<timestamp>_<name>.sql`
2. Link to dev: `npx supabase link --project-ref rtmrehcevyoqafyscpaj`
3. Push to dev: `npx supabase db push`
4. Regenerate types: `npm run types:generate`
5. Develop and test against dev
6. When ready for prod: `npx supabase link --project-ref lsssxrudfajjfidqbngl` then `npx supabase db push`
7. Switch back to dev: `npx supabase link --project-ref rtmrehcevyoqafyscpaj`

## Privacy / Retention

Prompts and images are retained for under one hour. The `/api/cron/cleanup` endpoint, scheduled in QStash to run every 15 minutes, NULLs `user_prompt` and `improved_prompt` and deletes the R2 image for any `generations` row older than 30 minutes. Rows are kept (not hard-deleted) so non-PII columns (model, cost, status, durations) remain available for ops/analytics. The keyboard's 20-minute "open keyboard, restore last batch" feature is the binding constraint on the lower end — anything tighter than ~25 min would risk pulling images while a user might still expect them.

**TODO (post-launch, when traction warrants it):** before NULLing `user_prompt` and deleting the R2 object, write a SHA-256 hash of the prompt + a SHA-256 hash of the image bytes (and `user_id`, `created_at`) into a small `abuse_audit` table. Hashes are not PII and let us trace a leaked image back to a user without retaining content. Premature today — revisit when hi-key starts seeing real volume.

## Credits & Purchases

The full spec — credits, RevenueCat events, the debit/refund flow, upgrade/downgrade handling, trials, referrals, and known future work (e.g. `TRANSFER` events) — is in **`../private/backend-purchases.md`** (git-ignored; see root `CLAUDE.md`). Read it before touching `lib/credits/*`, `lib/referrals/*`, the RC webhook, or `/api/generate` debit logic. If it's absent, the source of truth is `lib/credits/catalog.ts`, `lib/credits/webhook.ts` and the RPCs in `supabase/migrations/`.

## Referrals

Each user mints one immutable code of the form `NAME-XXXXXX` (6-char Crockford Base32 suffix) via `POST /api/referral`. A new user redeems via `POST /api/referral/redeem` during onboarding; both sides get 50 non-expiring credits (500 mills on `extra_credits_mills`). The atomic work happens inside the `redeem_referral` Supabase RPC — see `../private/backend-purchases.md` (Referrals) and `supabase/migrations/20260423120000_add_referrals.sql` for the ledger + locking details. `user_profiles.referral_code` is covered by a partial unique index (`WHERE referral_code IS NOT NULL`) which is both the uniqueness gate and the code → user lookup path.

## Waitlist

Before launch, the website collected waitlist emails; each waitlist member got a unique claim code in the launch email that, applied in-app, grants double credits forever on every subscription renewal and pack purchase. Signups are closed (the website's signup route was removed after launch), but claim codes are still redeemable via `/api/me/claim-code`.

Table `waitlist` — migrations: `20260306000000_add_waitlist_table.sql` (base) + `20260424000000_add_waitlist_claim.sql` (claim columns)
- `id` UUID PK, `email` TEXT NOT NULL (unique index), `referral_source` TEXT nullable, `created_at` TIMESTAMPTZ
- `claim_code` TEXT (partial unique index), `claimed_at` TIMESTAMPTZ nullable, `claimed_by_user_id` TEXT nullable
- RLS enabled, no policies — only accessible via service role key (same pattern as `generations`)
- Helper types in `lib/supabase/helpers.ts`: `WaitlistEntry`, `WaitlistInsert`
