# Product Roadmap

Organized by what validates the product first, then what improves retention, then monetization/scale. Keep MVP small — everything in this file should be checked against `docs/FEATURE_STATUS.md` for actual status before assuming it's done.

## MVP

Only what is necessary to validate the core loop: *Create Life -> Get Score -> Publish -> People Discover -> People Rate -> Receive Rating -> Compare -> Share -> More People Join.*

- Onboarding + anonymous profile creation — **implemented**
- Life Score calculation with an understandable breakdown — **implemented**
- Photo upload/management with delete — **implemented**
- Publish profile to discovery, with privacy controls — **implemented**
- Rate other profiles (1-10, one per user, no self-rating) — **implemented**
- Receive and view community rating vs. own Life Score — **implemented**
- Basic share of results (even clipboard-level) — **implemented**, needs a real share sheet (see V1)
- Block/report — **implemented**

The MVP loop is functionally complete on-device. What's missing to call it launch-ready is polish (see `product-review`/`flutter-ui` skills) and a real backend so ratings/discovery work across multiple real users instead of one device with mock data.

## V1 — improve retention

- Native share sheet (`share_plus` or platform channel) instead of clipboard-only sharing, so sharing actually reaches other apps/people.
- Score history visualization (line chart of `ScoreHistoryPoint` over time) so users have a reason to check back and watch their score move.
- Push/local notifications: "someone rated you," "your score changed," "new profiles to rate" — currently not implemented at all.
- Backend-backed accounts and real multi-user ratings, replacing local-only + mock-seeded discovery.
- Discovery filtering/sorting (by country, age range, recency) so the feed doesn't feel repetitive once there are many profiles.
- Widget-level test coverage for the rating flow and privacy rendering, to protect retention-critical flows from regressions.

## V2 — improve monetization and scale

- Premium analytics: deeper score breakdown, percentile comparisons, historical trend detail beyond what the free tier shows.
- Profile boosts: temporary increased visibility in discovery (must not let paying users bypass privacy/blocking rules).
- Advanced comparisons: compare score against specific demographics/cohorts (age range, country, career field).
- What-if simulations: "what would my score be if I saved X more / changed jobs / moved."
- Non-intrusive ads in discovery/leaderboard, sized and placed so they never block the core loop (never gate rating or being rated behind an ad or paywall).
- Pagination/cursor-based discovery and leaderboard once a real backend can hold large profile counts.
- Server-side moderation and rating-integrity enforcement (current block/report/one-rating rules are client-enforced only).

## Future

Ideas worth keeping in mind but not committing to:

- Group/friend-circle comparisons (opt-in, still respecting anonymity defaults).
- Score "achievements" (the `Achievement` model already exists in `models.dart` but isn't wired into any screen yet — worth deciding whether to build this out or remove the unused model).
- Localization beyond the current benchmark countries.
- Data export in a richer format than clipboard JSON (already have a starting point via "Export My Data").
