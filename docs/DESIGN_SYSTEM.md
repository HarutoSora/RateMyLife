# Design System — Neon Arcade

Reference for the visual identity introduced 2026-08-23, based on the provided brand logo (`assets/branding/logo.png`) and mockup. Update this file whenever a token changes — it should describe what `lib/core/theme/` actually contains, not an aspiration.

## Color (`lib/core/theme/app_colors.dart`)

| Token | Hex | Use |
|---|---|---|
| `background` | `#0A0620` | Scaffold background |
| `backgroundGlow` | `#1B1044` | Center of `heroGlow` radial gradient |
| `surfaceSolid` | `#171233` | Cards |
| `surfaceHigh` | `#201A48` | Inputs, chips, icon tiles |
| `border` | `#352A63` | Card/input borders |
| `textPrimary` | `#F5F3FF` | Headings, primary text |
| `textMuted` | `#A79FC4` | Secondary text |
| `purple` / `purpleDeep` | `#9B4DFF` / `#6C2BD9` | Primary brand accent, `purpleGradient` |
| `gold` / `goldDeep` | `#FFC530` / `#FF9F1C` | Score numbers, primary CTA gradient |
| `pink` / `pinkLight` | `#FF3D9A` / `#FF6FB3` | "Rate" actions, `pinkGradient` |
| `blue` / `blueLight` | `#3E8EFF` / `#5EC8FF` | "Discover" actions, `blueGradient` |
| `success` | `#35D07F` | Semantic positive (unrelated to brand accent — don't reuse as decoration) |
| `danger` | `#FF4D6A` | Semantic error |

Gradients (`goldGradient`, `purpleGradient`, `pinkGradient`, `blueGradient`) run top-left to bottom-right. `heroGlow` is a radial background gradient (`backgroundGlow` → `background`) for hero screens (Splash, Onboarding, Score).

## Type (`lib/core/theme/app_typography.dart`)

- **Display — Baloo 2** (via `google_fonts`): `AppTypography.hero` (56px/800, big numbers + wordmark), `title` (22px/700, screen titles), `heading` (18px/700, card titles).
- **Body/UI — Nunito**: `body` (15px/600), `bodyMuted` (14px/600, muted), `caption` (12px/700, uppercase-friendly labels), `button` (15px/800, all-caps CTA label), `eyebrow` (12.5px/800, wide letter-spacing).

Both fonts are fetched via `google_fonts` at runtime (cached by the package after first load). If text renders in a fallback font, the device had no network on first load — this is expected/known, not a code defect.

## Radius (`lib/core/theme/app_radius.dart`)

`sm` 12, `md` 18 (default card radius), `lg` 26, `pill` 100 (buttons, badges, chips).

## Brand components (`lib/presentation/widgets/brand_widgets.dart`)

- **`AppLogo`** — the app icon (`assets/branding/logo.png`), sized via `size`, with `cacheWidth`/`cacheHeight` set to avoid decoding the full 1254px source at small display sizes.
- **`GradientButton`** — full-width pill CTA. Pick one of the four gradients above based on the action's category (purple = primary/neutral flow, pink = social/rate, blue = discover/explore, gold = achievement/leaderboard/share). Has a disabled (50% opacity, no glow) state via `onPressed: null`.
- **`ScoreBadge`** — hexagonal, gold-bordered, purple-filled badge with a trophy topper, animated count-up score, and a tier ribbon (`lifeScoreTier()`: Starter <40, Building <60, Rising <75, Elite <90, Legendary ≥90).

## Where it's applied vs. not yet

Applied with bespoke layout: Splash, Onboarding (all 4 pages via the shared token/button/background changes, page 1 also gets the full logo), Home (quick-action buttons), Score screen (hero badge).

Re-themed automatically (new colors/fonts/radii flow through `AppTheme`/`AppColors`) but not yet given a bespoke layout pass matching the mockup's card compositions: Discover, Leaderboard, Public Profile, Photo Manager, Privacy Settings, Profile Wizard, Me screen. Do these with the `flutter-ui` skill, screen by screen, rather than all at once.

Not implemented: the floating circular "+" button docked in the bottom nav shown in the reference mockup. The current `AppShell` still uses a plain themed `BottomNavigationBar`; adding the docked FAB requires switching to `BottomAppBar` + `Scaffold.floatingActionButton` with `centerDocked` location, which is a larger, riskier structural change — do it as its own scoped task.
