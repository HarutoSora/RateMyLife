# Development Plan

Based on direct inspection of the repository on 2026-08-23. Update this document as the project changes — it should reflect actual state, not aspiration.

## 1. Current project status

Rate My Life is a working, local-only Flutter MVP. It runs end-to-end: onboarding -> profile creation -> Life Score calculation -> a tab shell with home, discovery, rating, leaderboard, and "me" screens -> photo management -> privacy settings. There is no backend; everything persists to `shared_preferences` and the local filesystem.

`flutter analyze`: 0 errors, 0 lint-level issues. `flutter test`: 18/18 passing across 4 test files (see section 8).

## 2. What is already implemented

- **Onboarding** (`OnboardingScreen`) and a first-run flag (`SettingsRepository.hasSeenOnboarding`).
- **Profile creation** (`ProfileWizardScreen`) covering demographics, career, finances, lifestyle, and bio.
- **Life Score** (`LifeScoreService`): weighted score across financial, career, education, independence, social, lifestyle, and wellbeing, with country benchmarks for 8 countries plus a global fallback, per-category explanations, and score history tracking (`ScoreHistoryPoint`).
- **Public profile screen** (`PublicProfileScreen`) with a photo viewer (`PhotoViewerScreen`).
- **Community rating** (`RatingService`, `RateFeedScreen`): 1-10 overall rating, self-rating blocked, one rating per rater per profile (upsert), removable, aggregated into `RatingSummary`.
- **Discovery feed** (`DiscoverScreen`) and **leaderboard** (`LeaderboardScreen`), both privacy- and block-aware via `ProfileService.isVisibleInDiscover`/`isVisibleInLeaderboard`.
- **Photo management** (`PhotoManagerScreen`, `PhotoService`): add, delete, set profile photo, reorder; photos are copied into app documents storage.
- **Privacy controls** (`PrivacySettingsScreen`, `ProfilePrivacy`): visibility (public/private), per-field show/hide (age, country, income, savings, career, photos), discover/leaderboard opt-out, allow-ratings toggle.
- **Blocking and reporting** (`ModerationService`, `AppController.blockProfile`/`reportProfile`): blocking hides a profile from discover/leaderboard/rate feeds; reporting also blocks.
- **Data export/reset**: "Export My Data" copies profile JSON to clipboard; `AppController.resetApp` clears all local storage.
- **Sharing**: `ShareProfileCard` + clipboard copy of a text summary (score + community rating). No native share sheet integration yet.
- **Mock community data** (`mock_profiles.dart`) seeds discovery/leaderboard so the app isn't empty on first run.
- **Design system** (`lib/core/theme/`): `AppTheme` (dark Material 3 `ThemeData`), plus newly extracted `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius` tokens.

## 3. What is incomplete

- **Backend/API**: none. All data is device-local; there is no cross-device sync, no real multi-user rating (ratings from "other users" are mock-seeded, not from real accounts).
- **Native share sheet**: sharing is clipboard-only; no `share_plus` (or platform channel) integration to hand off to other apps.
- **Notifications**: not implemented (no local or push notification package, no in-app notification center).
- **Score history UI depth**: `ScoreHistoryPoint`s are recorded, but confirm the history chart/visualization on `ScoreScreen` is complete rather than just a list — worth a UI-skill pass before calling it "polished."
- **Monetization**: no ads, premium tier, or boost mechanism — none expected at MVP stage.
- **Real rating identity/anti-abuse**: with only local persistence and no accounts, there's no protection against a single device generating multiple "raters." This is acceptable for an MVP demo but is a hard blocker for a real multi-user launch.
- **Widget/UI test coverage**: all current tests are service-level (`test/*.dart`); there are no widget tests exercising screens directly.

## 4. Current technical debt

- `lib/data/models/models.dart` (818 lines), `lib/presentation/screens/screens.dart` (1486 lines), and `lib/presentation/widgets/widgets.dart` (590 lines) are barrel-style files holding many unrelated classes each. This violates the project's own "no giant files" rule and will only get harder to navigate as features are added. Recommend splitting by feature (e.g. `screens/onboarding/`, `screens/discover/`, `screens/profile/`) the next time any of these files needs a non-trivial change — not as a standalone refactor.
- `AppController` (`lib/presentation/state/app_state.dart`, 336 lines) is a single `ChangeNotifier` holding all app state. Fine at current scope; if state keeps growing, consider splitting into narrower providers (e.g. separate rating/moderation state) so unrelated UI doesn't rebuild on every change.
- `tools/flutter/` is a full vendored Flutter SDK checkout sitting inside the repo. It was previously being picked up by `flutter analyze` (two real errors from its own test suite) until excluded in `analysis_options.yaml` as part of this setup. Confirm whether this checkout needs to live inside the repo at all, or whether it belongs outside the project tree / in `.gitignore` — it substantially inflates repo size and isn't part of the app.
- `.flutter_scaffold/` is a stale, unused default `flutter create` scaffold (its own `pubspec.yaml`, `lib/main.dart`, etc.) left over from initial project setup. It's excluded from analysis now; consider deleting it once confirmed unneeded, to avoid confusion about which project is "real."
- Two Flutter-API-version issues were fixed as part of this setup (previously blocking `flutter analyze`): `CardTheme` → `CardThemeData` in `ThemeData.cardTheme`, and a missing `cupertino.dart` import for `CupertinoPageTransitionsBuilder`.
- All 23 pre-existing lints/warnings from the initial setup pass have been cleared (`prefer_const_constructors`/`prefer_const_declarations` throughout `mock_profiles.dart`/`screens.dart`, `unnecessary_string_interpolations` in `screens.dart`, `withOpacity` → `withValues` in `widgets.dart`, `onReorder` → `onReorderItem` in the photo manager's `ReorderableListView.builder`, and the unused `oldScore` local in `ProfileService.recalculate`). `flutter analyze` is clean (0 issues). One note on the `onReorderItem` migration: it delivers an already-removal-adjusted `newIndex`, but `PhotoService.reorder` (and its test) expect the older, pre-adjustment index — the screen now converts back (`newIndex > oldIndex ? newIndex + 1 : newIndex`) rather than changing the service's contract, so behavior is unchanged.

## 5. MVP feature list

See `docs/FEATURE_STATUS.md` for the authoritative, per-feature status table.

## 6. Recommended implementation order

Given what exists, the highest-leverage next steps (see `docs/PRODUCT_ROADMAP.md` for the full roadmap) are:

1. Polish the score/comparison screen and rating flow (`flutter-ui` + `product-review` pass) since this is the core loop's emotional payoff moment.
2. Add native sharing (`share_plus`) so the viral loop has a real share sheet instead of clipboard-only.
3. Add widget tests for the rating flow and privacy-sensitive rendering (a private field must never render on a public screen) before any backend work begins.
4. When ready to move off local-only persistence, implement `Remote*Repository` classes against the existing abstract repository interfaces — the architecture is already shaped for this.

## 7. Testing status

18/18 tests passing across `test/life_score_service_test.dart`, `test/photo_service_test.dart`, `test/profile_service_test.dart`, `test/rating_service_test.dart`. All are service-level unit tests; no widget tests exist yet.

## 8. Performance concerns

No profiling has been run. Structurally worth watching once real user volume exists: `AppController` is one `ChangeNotifier` for all state (broad rebuild surface), photo picking downsamples to 1800px width (reasonable, but grid/thumbnail rendering should be checked against `flutter-performance` guidance as photo volume grows), and `discoverProfiles`/`leaderboardProfiles` currently materialize the full profile list with no pagination — fine for mock data, needs revisiting once a real backend can return large result sets.

## 9. Future backend integration requirements

- Real accounts/auth (to make "one rating per user" and self-rating prevention meaningful beyond a single device).
- A ratings/reports/blocks store that can enforce uniqueness and moderation server-side (current enforcement is client-side only, appropriate for local MVP, not sufficient once multiple devices are involved).
- Photo storage/CDN (currently local filesystem paths baked into `ProfilePhoto.path`; a remote implementation needs to swap this for uploaded URLs without changing the model's public shape where possible).
- Pagination/cursor support for discovery and leaderboard once profile counts grow past what's reasonable to load client-side.
