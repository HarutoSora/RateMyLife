<div align="center">

<img src="assets/branding/logo.png" width="140" alt="Rate My Life logo" />

# ✨ RATE MY LIFE ✨

### Game · Social · You

*Build an anonymous life. Get a score. Let the world rate it.*

[![Flutter](https://img.shields.io/badge/Flutter-3.47-9B4DFF?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13-3E8EFF?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth%20%7C%20Storage-FFC530?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20first-39FF88?style=for-the-badge&logo=android&logoColor=white)](#)

</div>

<br/>

> ⚠️ **Important:** the Life Score is entertainment and social comparison — it is **never** presented as a measurement of anyone's human worth. That rule is non-negotiable in this codebase.

---

## 🕹️ What is this?

**Rate My Life** turns "how's your life going?" into a social game. Create an anonymous profile, tell it about your career, finances, lifestyle and habits, and a transparent algorithm turns that into a **Life Score**. Then the community rates you too — and the gap between the algorithm and what people actually think of you *is part of the game*.

The core loop:

```
Create Life → Get Score → Publish → People Discover → People Rate
      ↑                                                      │
      └──────────── Share ← Compare ← Receive Rating ────────┘
```

## 💜 Features

<table>
<tr>
<td width="50%" valign="top">

**🎯 Core Loop**
- Anonymous profile creation, no name/email ever collected
- Transparent, category-broken-down Life Score
- Tinder-style swipe rating (1–10, no self-rating)
- Real percentiles — age group, country, overall
- Discover, Leaderboard, "New & Rising", "Biggest Gaps"

**💬 Social**
- Direct messages & 1:1 audio calls
- Comments, reactions, best-photo voting
- Block / report on everything, always
- Life Battles — head-to-head profile duels
- "What Would You Choose?" — daily would-you-rather with **real** community results

</td>
<td width="50%" valign="top">

**🏆 Progression**
- XP, levels, ranks, daily streaks
- Daily challenges, achievements, coins
- Cosmetic profile frames
- Local daily-challenge reminder notifications

**🔒 Privacy by design**
- Anonymous ratings — not even the profile owner can see who rated them
- Income/savings hidden by default, opt-in only
- Every private field is a separate, server-rule-protected document
- Firestore security rules enforce every guarantee client-side code makes

</td>
</tr>
</table>

## 📱 Screenshots

<table>
<tr>
<td align="center" width="25%"><img src="docs/screenshots/home.png" width="200" alt="Home screen" /><br/><sub>Home</sub></td>
<td align="center" width="25%"><img src="docs/screenshots/discover.png" width="200" alt="Discover screen" /><br/><sub>Discover</sub></td>
<td align="center" width="25%"><img src="docs/screenshots/rate.png" width="200" alt="Rate screen" /><br/><sub>Rate</sub></td>
<td align="center" width="25%"><img src="docs/screenshots/messages.png" width="200" alt="Messages screen" /><br/><sub>Messages</sub></td>
</tr>
</table>

## 🧬 Tech stack

| Layer | Tech |
|---|---|
| App | Flutter 3.47 / Dart 3.13, Material 3, Riverpod |
| Backend | Firebase — Auth (anonymous), Firestore, Storage, Cloud Functions |
| Fonts | Baloo 2 (display) + Nunito (body), via `google_fonts` |
| Calls | WebRTC (`flutter_webrtc`), STUN-only signaling over Firestore |

Architecture is a straightforward `presentation → domain → data` split — pure calculation/rules services, `Local*`/`Remote*` repository pairs behind one interface, and a single `AppController` (`ChangeNotifier`) as the app's source of truth. No backend framework, no microservices — this is an MVP, built to stay readable.

## 🚀 Getting started

```bash
flutter pub get
flutterfire configure   # generates the Firebase config this repo intentionally excludes
flutter run
```

`android/app/google-services.json` and `lib/firebase_options.dart` aren't committed — they identify a specific Firebase project, so regenerate them for your own via [`flutterfire configure`](https://firebase.google.com/docs/flutter/setup).

To run the test suite:

```bash
flutter test
```

## 🌈 Design system

Dark-first "neon arcade" identity — deep purple/navy grounds, violet glow, gold/pink/blue gradient CTAs.

<p>
<img src="https://img.shields.io/badge/-9B4DFF?style=flat-square" width="60" height="24" alt="purple"/>
<img src="https://img.shields.io/badge/-FF3D9A?style=flat-square" width="60" height="24" alt="pink"/>
<img src="https://img.shields.io/badge/-FFC530?style=flat-square" width="60" height="24" alt="gold"/>
<img src="https://img.shields.io/badge/-3E8EFF?style=flat-square" width="60" height="24" alt="blue"/>
<img src="https://img.shields.io/badge/-39FF88?style=flat-square" width="60" height="24" alt="green"/>
</p>

Full token reference lives in `lib/core/theme/` and `docs/DESIGN_SYSTEM.md`.

---

<div align="center">
<sub>Built with Flutter 💜 and a healthy amount of neon.</sub>
</div>
