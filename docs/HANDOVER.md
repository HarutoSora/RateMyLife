# Handover — 2026-08-25

Covers the ads/monetization work and the rating bug fix from this session. For the full feature-by-feature history, see `docs/FEATURE_STATUS.md` — this file is a narrower "what changed, what's pending, what to check" summary for whoever picks this up next.

## What shipped this session

### 1. Ads (Google AdMob via `google_mobile_ads`)

First ad SDK in the app, and the first dependency with its own data-collection story (device advertising ID) in an otherwise zero-PII app — this was flagged explicitly to the user and a disclosure was added rather than assumed.

- **Banner ads** — `lib/presentation/widgets/ad_widgets.dart` (`BannerAdWidget`). Self-contained: loads on mount, collapses to nothing if it fails/hasn't loaded, disposes on unmount. Shown at the bottom of Home and interleaved every 5 cards in the Discover feed.
- **Rewarded video** — `AdRepository`/`MobileAdsRepository` in `lib/data/repositories/repositories.dart`, driven by `AppController.watchRewardedAd()`. Grants **300 coins** on completion (`XpReason.adWatched` in `lib/domain/services/reward_service.dart` — went 25 → 100 → 300 across the session per explicit user requests). No-ops silently on a failed/skipped ad.
- **Interstitial ads** — same repository, `showInterstitialAd()`. Fires on the **30th "action"**, where an action is anything that reaches `AppController._checkAchievements()` (the shared checkpoint every XP-granting flow already passes through: ratings, battle/choice votes, shares, etc.). Counter is session-only (`_actionCount`, not persisted).
- **Get Coins screen** — `lib/presentation/screens/get_coins_screen.dart`, reachable via a "Get Coins" pill next to the coin balance on Home. Redesigned to match a user-supplied neon mockup: gradient "BUY COINS" title, glowing hero badge, a featured "Watch Ad — +300 Coins / FREE" row, and 5 purchase tiers (500/$0.99, 1,200/$1.99, 2,500/$3.99 "Best Value", 6,000/$7.99 "Mega Pack", 15,000/$14.99 "Ultimate Pack").
  - **The 5 purchase tiers are NOT wired to real payments.** Tapping any of them shows a "coming soon" snackbar. Real purchases need Google Play Billing (`in_app_purchase` package, not added) with actual product IDs configured in Play Console — that setup doesn't exist yet and needs to happen outside this codebase first.
- **Privacy disclosure** — a new "Data & Ads" section in `PrivacySettingsScreen` (in `lib/presentation/screens/screens.dart`), a plain info card (not a toggle) explaining ads use a device advertising ID.

**Ad unit IDs** live in `lib/core/ads/ad_config.dart`:
```
rewardedAdUnitId:      ca-app-pub-9503065477167980/8483528580
interstitialAdUnitId:  ca-app-pub-9503065477167980/6187899707
bannerAdUnitId:        ca-app-pub-3940256099942544/6300978111  ← Google's TEST id, not the real one
```
**Action needed later:** the real banner ID (`ca-app-pub-9503065477167980/6128827983`) is commented out in `ad_config.dart`. It was swapped for Google's test ID because the real one returns AdMob error 3 ("no fill") — expected for a brand-new, not-yet-reviewed AdMob app. Swap it back once real banners start serving (verify via `adb logcat | grep Ads` — look for `Ad failed to load : 3` vs successful fills). The user explicitly chose to keep the test ID active for now rather than have the fix reverted; revisit this deliberately, not automatically.

**Android build fix required for `google_mobile_ads`:** it transitively pulls a very old `androidx.work:work-runtime:2.7.0` that crashes this project's much newer AndroidX/Kotlin stack under R8 minification (`NoSuchMethodException: WorkDatabase_Impl.<init>` on every app start). Fixed with two changes, both needed together:
- `android/app/build.gradle.kts` — forces `androidx.work:work-runtime:2.10.0` via `resolutionStrategy`.
- `android/app/proguard-rules.pro` — keeps Room-generated `RoomDatabase` subclass constructors (R8 was stripping the reflection-only no-arg constructor).

If `google_mobile_ads` is ever upgraded again, re-check whether this pin is still needed.

### 2. Rating bug: "permission-denied" + "too slow to move" on the Discover heart button

User-reported. Root causes turned out to be two separate things, both fixed:

- **Slowness**: `_quickRate` (Discover's heart/love button, `lib/presentation/screens/screens.dart`) used to `await` the full Firestore round-trip (rating + profile-summary transaction) before dismissing the card. "Pass" (X) never touched the network and was instant, so Like felt broken by comparison. Made optimistic — the card dismisses and the confirmation snackbar shows immediately; the save still happens, just not gating the UI.
- **permission-denied**: user confirmed after the fact it was from rapid double-tapping the same card. Two near-simultaneous `submitRating` calls for the same profile raced against the same Firestore rating document. Fixed at the root in `AppController.submitRating` (`lib/presentation/state/app_state.dart`) with an in-flight guard (`_submittingRatings` set) — a second call for a profile already being submitted is a no-op — plus a UI-level early-return in `_quickRate` for a same-frame double-tap on an already-dismissed card. Covered by a new test: `'a double-tap only submits one rating for the same profile'` in `test/xp_progression_integration_test.dart`.

**Side effect of the investigation**: `RemoteRatingRepository` (`lib/data/repositories/repositories.dart`) had **zero test coverage** before this — unlike every other Remote repository in the app. Added `test/remote_rating_repository_test.dart` (6 tests: create, edit, remove, cross-user isolation, and the "rating a mock/seed profile with no real Firestore doc" case that was the leading theory during investigation). All pass; the repository's logic was already correct.

### 3. `commentsAllowed()` rules bug — fixed and deployed

`firestore.rules`'s `commentsAllowed()` helper did the unsafe `.privacy.allowComments == true` dot-access instead of the safe `.get('allowComments', true)` pattern already used by `messagesAllowed()`/`callsAllowed()` right next to it. Any profile created before the `allowComments` field existed would have comments silently denied server-side. Fixed to match the existing safe pattern and deployed via `firebase deploy --only firestore:rules --project rate-my-life-2c381` — compiled and released successfully.

### 4. All success/confirmation toasts removed app-wide

User-requested. Every non-error `toast` assignment (comment posted/updated/deleted, vote counted, rating removed, report submitted, frame unlocked, coins earned, profile hidden, "Vote recorded!"/"Choice recorded!"/reward summaries, etc.) was deleted from `AppController` — actions still happen and still save, they just no longer show a snackbar. Error toasts (permission denied, insufficient coins, validation exceptions) were deliberately kept. Two now-fully-unused private helpers (`_composeRewardToast`, `_ratingToast`) were deleted as dead code; `updateProfile`'s `message` parameter was removed and its ~7 call sites updated.

### 5. Nuke / Cure mini-game (new feature)

User-requested "for fun" PvP mechanic — full details in `docs/FEATURE_STATUS.md`'s "Nuke / Cure mini-game" row (architecture, anonymity model, why damage is a separate overlay rather than a raw-field change, why the mock-profile local mixing is recomputed fresh instead of incrementally merged). Summary: pay 5,000 coins to deal 5 damage to a random Life Score category on someone else's profile (`NukeScreen`, reachable from Home's Play grid); pay 1,000 coins on a cure potion to heal 3 points off your own damage. Anonymous to the target by default, same as ratings. Discover shows a "☢ N survived" badge per profile.

**Security-rules tradeoff flagged, not silently accepted**: the new non-owner `profiles/{uid}` update allowance for `nukeDamage`/`nukesSurvived`/`score` doesn't validate the actual delta server-side (same posture as the pre-existing `ratingSummary`/`photoVoteCounts` carve-outs) — but `score` is more consequential than those two if that trust were ever abused by a malicious client. Not fixed now (would need Cloud Functions to validate, out of scope for this pass) — worth revisiting if this app ever has real adversarial users.

### 6. Permission prompts disabled for this project (user request)

`.claude/settings.local.json` now sets `permissions.defaultMode: "bypassPermissions"` — no tool-use confirmation prompts fire in this project anymore, including destructive ones. Explicit standing approval from the user, given because this project is currently being used as a sandbox ("just playing around, not a real project"). Revisit if that framing ever changes.

### 7. Nuke feature follow-ups: orange accent, glow buttons, damage on Discover/breakdown, and a layout bug fix

Follow-on requests after the initial Nuke ship: swapped the feature's accent from `neonRed` to a dedicated `AppColors.nukeOrange` (`#FA7308`); gave the NUKE/CURE buttons a two-layer neon glow (`_GlowWrap` in `nuke_screen.dart`); added a "☢️ N nuked" fact to Discover cards (alongside job/location/education/car) and a matching red-progress-bar line in `PublicProfileScreen`'s Score Breakdown for whichever attribute took damage (`AppController.nukeDamageFor`, new). Found and fixed a real layout bug while adding the breakdown marker: the ☢️ icon appended after the damaged row's value text stole width from that row's label column (`Expanded`), shifting the whole progress bar left and making it look wider than an undamaged row at the same value — fixed by reserving a fixed-width slot for the marker in every row, not just damaged ones.

### 8a. Discover action bar: rating number instead of a plain star, and made bigger

The middle button in Discover's Pass/★/Like row (between the X and the heart) now shows the profile's numeric life rating (e.g. "3.5") instead of a plain star icon — falls back to the star only when a profile has no ratings yet. Also sized up to 68px (was 46px, smaller than Pass/Like's 58px) so it reads as the primary element in that row, not an afterthought. `_ActionButton` gained an optional `label` override for this (same pattern as the `emoji` override added earlier for `_ExploreTile`/`_CardFact`/`NeonIconBadge`).

### 8b. Nuke status banner on Home + Me

New `NukeStatusBanner` (`nuke_screen.dart`) — a pulsing, glowing card showing "N nukes survived" plus a per-attribute "BUY HEAL (1,000)" button for anything currently damaged, placed on both `HomeScreen` and `MeScreen`. Deliberately eye-catching (looping `AnimationController` driving the border/shadow glow, 1.3s reverse-repeat) since the point is nudging a cure-potion purchase, not just reporting a stat — same reasoning as `WatchAdPill`/`GetCoinsScreen`'s existing monetization surfaces. Renders nothing when there's no damage and nothing to report. Reuses `_GlowWrap` from the Nuke screen for the heal button's own glow.

### 9. Messaging bug: conversation screen didn't scroll to the latest message

User-reported: opening a conversation (or receiving a new message while one was open) left the view wherever `ListView` happened to lay out by default, not at the newest message — required scrolling down manually every time. Root cause: `ConversationScreen`'s `ListView` had no `ScrollController` at all. Fixed with a controller that jumps (not animates — a long thread shouldn't visibly scroll through every message on open) to `maxScrollExtent` whenever the thread length changes, re-checked one frame later too (the mark-as-read side effect's own `notifyListeners()` lands a frame after the new message's, which can nudge layout just enough that a single jump falls slightly short). 2 new widget tests in `test/conversation_live_read_test.dart`. Discovered along the way: that test file's existing `RepositoryBundle` setups only ever faked `profileRepository`/`messageRepository`, leaving `AppController._load()` to hang forever on the first *real* `LocalSettingsRepository` call in this specific `testWidgets`/FakeAsync environment — the pre-existing test in that file never noticed because its assertion is trivially true either way (0 unread messages, whether or not `_load()` ever actually finished). Not fixed for that pre-existing test (out of scope for this bug report), but the two new tests fully fake every repository `_load()` touches, matching the pattern `xp_progression_integration_test.dart`/`public_profile_privacy_test.dart` already use.

### 10. Play Store readiness: release signing, privacy policy, real in-app purchases

User asked what's needed to publish and whether the app meets Play Store requirements — audit turned up several real blockers, three of which got fixed this session:

- **Release signing.** `android/app/build.gradle.kts` was signing release builds with the **debug** keystore — an automatic Play Console rejection. Generated a real upload key (`android/app/upload-keystore.jks`, alias `upload`, 10,000-day validity) via `keytool`, wired it through `android/key.properties` (git-ignored, never committed), and updated `build.gradle.kts` to use it when present, falling back to debug signing when it's not (so a fresh checkout without the keystore still builds). **Verified via `apksigner verify --print-certs`** that the release APK is now actually signed with the new key, not debug. A copy of the keystore + `key.properties` was placed at `Desktop\RateMyLife-Keystore-Backup\` on request — **this is still only a second copy on the same machine**; told the user explicitly to move a copy somewhere that survives losing this machine (losing the keystore forever blocks future updates to this app under the same identity, unrecoverable by Google).
- **Privacy policy.** Play Console requires one; the app had none. Drafted and published one as an Artifact: **https://claude.ai/code/artifact/dae52703-ebd1-42ed-a38b-56800018afa0** — covers what's actually collected (anonymous auth, profile fields, photos, ratings/messages, the AdMob advertising ID), sharing, the app's anonymity/safety guarantees, user controls, deletion, and contact (used the user's own email as the contact address). **User must click Share on the artifact before submitting the URL to Play Console** — it's private by default.
- **Real Google Play Billing**, replacing the "coming soon" snackbar on the 5 coin packages. Added `in_app_purchase` (^3.2.1). New `PurchaseRepository`/`InAppPurchaseRepository` (`lib/data/repositories/repositories.dart`) — one real implementation, no Local/Remote split, same reasoning as `AdRepository`. Product IDs are **placeholders** in `lib/core/purchases/purchase_config.dart` (`coins_500` … `coins_15000`) since there's no Play Console listing yet to pull real ones from — they must either be used verbatim when creating the real products, or this file updated to match whatever IDs actually get created. `AppController._load()` now queries `purchasesAvailable`/`purchaseProducts` and subscribes to the purchase stream (`_handlePurchaseUpdates`) so a purchase that completes while the app wasn't watching (killed mid-flow) still gets caught and granted on next launch — same reasoning as the messages/calls subscriptions. `purchaseCoins(productId)` starts the flow; a purchased/restored event grants `PurchaseConfig.coinsForProduct[productId]` via `XpReason.coinsPurchased` (coins-only, new) and calls `completePurchase` (required or the store auto-refunds after a few days as "undelivered"). `GetCoinsScreen` now shows the real localized store price once a product exists, falling back to the static preview price until then. **Not implemented**: server-side purchase/receipt verification (Google Play Developer API) — the client trusts the store's own purchase status, same trust posture as this app's existing patterns elsewhere, but worth flagging since real money is involved this time, not just an aggregate stat. 6 new tests in `xp_progression_integration_test.dart` covering purchased/restored/canceled/error statuses and the not-yet-available case.

  **Regression, same class as the nuke/settings ones above**: `_load()` now unconditionally calls `purchaseRepository.isAvailable()` too, and the real `InAppPurchaseRepository` breaks in a `test()`/`testWidgets()` environment same as the other real repos. Added `_FakePurchaseRepository` to `xp_progression_integration_test.dart`, `battle_integration_test.dart`, `comment_integration_test.dart`, and `public_profile_privacy_test.dart` — the same 4 files that needed the nuke-repository fix earlier, confirming this really is "every test file that constructs `RepositoryBundle` needs every real repo it doesn't care about faked," not something specific to nuke or purchases.

**Still open** (see `docs/HANDOVER.md`'s earlier Google Play readiness answer, unchanged): AdMob consent flow (UMP SDK) for GDPR/UK/CCPA, a Play Console developer account, the actual AdMob review status, and a content-rating decision given the app rates people's looks/income/lifestyle.

## Verification status

- `flutter analyze`: clean, 0 issues.
- `flutter test`: 404 passing (0 failing) — up from 365; new coverage is `nuke_service_test.dart`, `remote_nuke_repository_test.dart`, `life_score_service_test.dart` additions, three new integration groups in `xp_progression_integration_test.dart` (nuke, cure, coin purchases), and two new widget tests in `test/conversation_live_read_test.dart`.
- Release APK builds successfully (`flutter build apk --release`), is now signed with the real upload key (verified via `apksigner`), and has been installed on `emulator-5554` — launched cleanly with no crashes in logcat after every change this session, including the in-app-purchase wiring. Verified live earlier in the session: banner rendering (test ad), rewarded ad completion + coin grant, Get Coins screen layout, the rating double-tap fix. **Not yet manually verified live**: the Nuke screen's UI/UX, the conversation auto-scroll fix, and the real purchase flow (untestable without a Play Console listing) — see "What to check" below.
- **Not verified**: real (non-test) banner/interstitial fill — blocked on AdMob app review, not a code issue. iOS is not configured for ads (Android-first, consistent with the rest of the app).

## Files touched this session

```
android/app/build.gradle.kts          — androidx.work version pin
android/app/proguard-rules.pro        — Room keep rule
android/app/src/main/AndroidManifest.xml — AdMob App ID meta-data
firestore.rules                       — commentsAllowed() fix; nukeDamage/nukesSurvived/score
                                         non-owner update allowance; new nukeEvents collection
lib/core/ads/ad_config.dart           — NEW: ad unit IDs
lib/data/models/models.dart           — XpReason.adWatched/nukeUsed/curePotionUsed,
                                         NEW: NukeEvent, UserProfile.nukeDamage/nukesSurvived
lib/data/repositories/repositories.dart — AdRepository/MobileAdsRepository,
                                         NEW: NukeRepository/LocalNukeRepository/RemoteNukeRepository
lib/domain/scoring/life_score_service.dart — NEW: applyDelta/applyDamage
lib/domain/services/reward_service.dart — adWatched coin reward (300)
lib/domain/services/profile_service.dart — recalculate reapplies nukeDamage; applyNukeDamage passthrough
lib/domain/services/nuke_service.dart — NEW: NukeService, NukeValidationException
lib/main.dart                         — MobileAds.instance.initialize()
lib/presentation/screens/get_coins_screen.dart — NEW: Get Coins screen
lib/presentation/screens/nuke_screen.dart — NEW: Nuke screen (target picker, cure panel, history)
lib/presentation/screens/screens.dart — Get Coins pill, Discover banner interleave,
                                         Home banner + pill, quick-rate optimistic fix,
                                         Privacy Settings disclosure, Home Nuke tile,
                                         Discover card "N survived" badge, all success
                                         toasts removed
lib/presentation/state/app_state.dart — watchRewardedAd, interstitial counter,
                                         submitRating double-submit guard, nukeProfile/
                                         cureDamage/displayScoreFor/nukesSurvivedFor,
                                         all success toasts removed, _composeRewardToast/
                                         _ratingToast deleted, updateProfile's message
                                         param removed
lib/presentation/widgets/ad_widgets.dart — NEW: BannerAdWidget, WatchAdPill
pubspec.yaml / pubspec.lock           — google_mobile_ads ^9.1.0
.claude/settings.local.json           — bypassPermissions mode
test/remote_rating_repository_test.dart — NEW: 6 tests, previously zero coverage
test/remote_nuke_repository_test.dart — NEW: 5 tests
test/nuke_service_test.dart           — NEW: unit tests for NukeService
test/life_score_service_test.dart     — NEW: applyDelta/applyDamage tests
test/xp_progression_integration_test.dart — ad + rating + nuke + cure integration tests,
                                             _FakeAdRepository/_FakeRatingRepository/
                                             _FakeNukeRepository exposed as fields
test/battle_integration_test.dart, test/comment_integration_test.dart,
test/public_profile_privacy_test.dart — _FakeNukeRepository added (AppController._load()
                                         now touches nukeRepository unconditionally)
test/progression_service_test.dart    — adWatched/nukeUsed/curePotionUsed excluded from
                                         fixed-XP-reward check
test/reward_service_test.dart         — nukeUsed/curePotionUsed excluded from fixed-coin-reward check
lib/core/theme/app_colors.dart        — NEW: nukeOrange/nukeOrangeDeep/nukeOrangeGradient
lib/presentation/widgets/brand_widgets.dart — NeonIconBadge gained an optional `emoji` override
lib/presentation/state/app_state.dart — (see above) also: nukeDamageFor (new)
lib/presentation/screens/screens.dart — (see above) also: nukeOrange swap, _ExploreTile/_CardFact
                                         gained optional `emoji`, Discover "N nuked" fact,
                                         PublicProfileScreen nuke-survived line + red breakdown
                                         line + breakdown row-alignment fix, ConversationScreen
                                         auto-scroll-to-bottom fix
lib/presentation/screens/nuke_screen.dart — (see above) also: _GlowWrap, nukeOrange swap
test/conversation_live_read_test.dart — NEW: 2 widget tests for the auto-scroll fix, plus a
                                         full fake-repository set (see write-up above)
docs/FEATURE_STATUS.md                — Ads row added, push-notification row updated,
                                         Nuke / Cure mini-game row added, IAP row added
android/app/build.gradle.kts          — (see above) also: real release signingConfig,
                                         falling back to debug when key.properties is absent
android/key.properties                — NEW, git-ignored: keystore alias/passwords/path
android/app/upload-keystore.jks       — NEW, git-ignored: real upload signing key
lib/core/purchases/purchase_config.dart — NEW: placeholder product IDs, coinsForProduct map
lib/data/models/models.dart           — (see above) also: XpReason.coinsPurchased
lib/data/repositories/repositories.dart — (see above) also: PurchaseRepository/
                                         InAppPurchaseRepository, RepositoryBundle wiring
lib/presentation/state/app_state.dart — (see above) also: purchasesAvailable/purchaseProducts,
                                         purchaseCoins, _handlePurchaseUpdates, purchase-stream
                                         subscription in _load()/dispose()
lib/presentation/screens/get_coins_screen.dart — real purchaseCoins wiring, storePrice display
                                         falling back to previewPrice
pubspec.yaml / pubspec.lock           — in_app_purchase ^3.2.1
test/xp_progression_integration_test.dart — (see above) also: _FakePurchaseRepository,
                                         6 purchase tests (purchased/restored/canceled/error/
                                         unavailable/product-missing)
test/battle_integration_test.dart, test/comment_integration_test.dart,
test/public_profile_privacy_test.dart — (see above) also: _FakePurchaseRepository added
test/conversation_live_read_test.dart — (see above) also: _FakePurchaseRepository in its
                                         full fake-repository set
```

## What to check (not driven by an emulator this session)

Nuke feature:
1. Home → Play grid → Nuke tile opens `NukeScreen` and renders without overflow; buttons show a visible neon-orange glow.
2. Picking a target shows the confirm dialog with correct cost/damage text; confirming deducts coins and the target's profile (if a mock/seed profile) reflects damage next time you view it.
3. "Your Damage" panel appears once you've been nuked (simulate by nuking yourself isn't possible — self-nuke is blocked by design — so this needs a second real account, or manually seeding `nukeDamage` for a manual check) and the Cure button spends coins and reduces damage.
4. Discover cards show the "☢ N nuked" fact (alongside job/location/education/car) and the "☢ N survived" badge only once a profile has actually been nuked at least once.
5. `PublicProfileScreen`'s Score Breakdown renders the damaged category's bar in red, aligned identically to every other row (the layout bug from earlier this session is fixed, but worth a visual re-check).
6. Insufficient-coins and self-nuke/blocked-target cases show an error snackbar and don't deduct coins.

Messaging:
7. Open a conversation with many messages — it should land on the newest message immediately, no manual scrolling needed.
8. With a conversation open, have another device/account send a new message — the view should scroll down to it automatically.

Play Billing / release readiness:
9. Real purchase flow can't be tested end-to-end until the 5 products exist in Play Console under the exact IDs in `lib/core/purchases/purchase_config.dart` (`coins_500`, `coins_1200`, `coins_2500`, `coins_6000`, `coins_15000`) and the signed release APK is uploaded to at least an internal-testing track — `InAppPurchase.instance.isAvailable()` and `queryProductDetails` both depend on a real Play Store listing, not just a signed build.
10. Once products exist, confirm on a real device/test track: each package purchases, grants the right coin amount, `GetCoinsScreen` shows the real localized store price instead of the preview price, and a purchase completed while the app was killed still gets granted/completed on next launch.
11. Before submitting to Play Console, click Share on the privacy policy artifact (https://claude.ai/code/artifact/dae52703-ebd1-42ed-a38b-56800018afa0) so the URL is reachable, and move the keystore backup off this machine (the Desktop copy is not enough — losing both copies blocks all future updates to this app under the same identity).

## Suggested next steps

1. Create the 5 real coin products in Play Console (or decide on different IDs and update `purchase_config.dart` to match), then run through item 10 above on a test track.
2. Swap `AdConfig.bannerAdUnitId` back to the real ID once AdMob review completes and it starts filling.
3. Consider whether the interstitial's 30-action cadence and reward values (300 coins/watch) feel right once real usage data exists — both were user-specified up front, not tuned against data.
4. Add the AdMob UMP consent flow (GDPR/UK/CCPA) before any EU/UK traffic — still open from the Play Store readiness audit.
5. Decide on a content rating given the app rates people's looks/income/lifestyle, and set up the actual Play Console developer account if not already done.
4. Manually click-test the Nuke screen and the messaging auto-scroll fix on the emulator per "What to check" above.
5. Decide whether the nuke attack cost (5,000)/damage (5) and cure cost (1,000)/heal (3) feel balanced once there's real usage — these were taken directly from the user's request, not tuned.
