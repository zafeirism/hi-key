<wizard-report>
# PostHog post-wizard report

The wizard has completed a deep integration of PostHog analytics into hi-key. The SDK is installed in both the main app (`hi`) and the keyboard extension (`hi-keyboard`) targets via Swift Package Manager, initialized at app launch, and wired to the Supabase user identity so all events are correlated to a stable user ID.

## Files changed

| File | Change |
|---|---|
| `hi.xcodeproj/project.pbxproj` | Added `posthog-ios` SPM package reference + two product dependencies (one per target) + two build file entries |
| `hi.xcodeproj/xcshareddata/xcschemes/hi.xcscheme` | Added `POSTHOG_PROJECT_TOKEN` and `POSTHOG_HOST` run environment variables |
| `hi.xcodeproj/xcshareddata/xcschemes/hi-keyboard.xcscheme` | Added `POSTHOG_PROJECT_TOKEN` and `POSTHOG_HOST` run environment variables |
| `hi/hiApp.swift` | Added `PostHogEnv` enum, PostHog initialization with lifecycle tracking, user identification after Supabase auth |
| `hi-keyboard/KeyboardViewController.swift` | Added PostHog initialization (no lifecycle events), user identification from Supabase session |
| `hi/Managers/PurchasesManager.swift` | Added `subscription_purchased`, `pack_purchased`, `purchase_cancelled`, `purchase_restored` events |
| `hi/Views/Onboarding/PaywallView.swift` | Added `paywall_viewed` event on appear |
| `hi/Managers/OnboardingManager.swift` | Added `onboarding_completed` event, `referral_code_redeemed` event |
| `hi/Managers/CreditsManager.swift` | Added `referral_code_created` event |
| `hi-keyboard/HiKeyboardViewModel.swift` | Added `image_generation_started`, `image_generation_completed`, `image_generation_failed`, `image_copied` events |

## Events instrumented

| Event | Description | File |
|---|---|---|
| `onboarding_completed` | User finishes the onboarding flow and lands on the home screen | `hi/Managers/OnboardingManager.swift` |
| `paywall_viewed` | User sees the paywall screen during onboarding or from settings | `hi/Views/Onboarding/PaywallView.swift` |
| `subscription_purchased` | User successfully purchases a weekly subscription (starter, plus, or super tier) | `hi/Managers/PurchasesManager.swift` |
| `pack_purchased` | User successfully purchases a one-time credit pack (mini or mega) | `hi/Managers/PurchasesManager.swift` |
| `purchase_cancelled` | User cancelled the App Store purchase sheet without completing | `hi/Managers/PurchasesManager.swift` |
| `purchase_restored` | User successfully restored previous purchases | `hi/Managers/PurchasesManager.swift` |
| `image_generation_started` | User taps Generate in the keyboard — API request sent | `hi-keyboard/HiKeyboardViewModel.swift` |
| `image_generation_completed` | Backend returned image URLs after a successful generation | `hi-keyboard/HiKeyboardViewModel.swift` |
| `image_generation_failed` | Generation API call threw an error | `hi-keyboard/HiKeyboardViewModel.swift` |
| `image_copied` | User copied a generated image to the clipboard (with watermark) | `hi-keyboard/HiKeyboardViewModel.swift` |
| `referral_code_created` | User generated their own shareable referral code | `hi/Managers/CreditsManager.swift` |
| `referral_code_redeemed` | User applied a friend's referral code and earned bonus credits | `hi/Managers/OnboardingManager.swift` |

## Next steps

We've built some insights and a dashboard for you to keep an eye on user behavior, based on the events we just instrumented:

- [Analytics basics dashboard](/dashboard/661245)
- [Paywall Conversion Funnel](/insights/I6neRM8j) — paywall_viewed → subscription_purchased conversion rate
- [Daily Image Generations](/insights/7YfRw6Nl) — started / completed / failed over time
- [Images Copied](/insights/83tuS1VL) — copy rate vs. total generations (engagement)
- [Revenue Events](/insights/VDWjJAY3) — subscription purchases, pack purchases, cancellations
- [Referral Funnel](/insights/YSJrPRXL) — code creation → redemption rate (viral loop)

### Agent skill

We've left an agent skill folder in your project. You can use this context for further agent development when using Claude Code. This will help ensure the model provides the most up-to-date approaches for integrating PostHog.

</wizard-report>
