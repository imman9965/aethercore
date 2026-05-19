# AetherCore — Project Documentation

> Full developer guide. The shorter, submission-focused overview lives in
> `README.md`. This document is the deep-dive: architecture, data model,
> runtime flow, security, performance, testing, and operations.

---

## Table of Contents

1. [What this project is](#1-what-this-project-is)
2. [Tech stack](#2-tech-stack)
3. [Architecture — Clean Architecture by feature](#3-architecture--clean-architecture-by-feature)
4. [Project structure](#4-project-structure)
5. [Data model](#5-data-model)
6. [Security rules](#6-security-rules)
7. [Feature deep dives](#7-feature-deep-dives)
   - 7.1 [Authentication](#71-authentication)
   - 7.2 [World Boss timer](#72-world-boss-timer)
   - 7.3 [Dragon Raid](#73-dragon-raid)
   - 7.4 [Engagement Chat](#74-engagement-chat)
8. [Runtime flow](#8-runtime-flow)
9. [Setup and run](#9-setup-and-run)
10. [Testing](#10-testing)
11. [The Architecture Linter](#11-the-architecture-linter)
12. [Design system](#12-design-system)
13. [Performance notes](#13-performance-notes)
14. [Cost optimization](#14-cost-optimization)
15. [Troubleshooting](#15-troubleshooting)
16. [Extending the project](#16-extending-the-project)
17. [Glossary](#17-glossary)

---

## 1. What this project is

AetherCore is a single-screen Flutter application that demonstrates the
"nervous system" of a global MMORPG: a high-frequency World Boss
countdown, a strictly-capped raid signup, and a real-time engagement
chat. It is the deliverable for *Project Aether: The Challenge*, whose
grading criteria are concrete and outcome-driven:

- The 50-concurrent raid-join test caps at exactly 15 successes.
- `flutter analyze` reports zero issues.
- The README documents a chat cost-sharding strategy for 10,000
  concurrent chatters.
- `dart aether_linter.dart` produces a clean `ARCHITECTURE_REPORT.md`.

The codebase is organised under Clean Architecture so the rules above
are enforced *structurally*, not merely by convention.

---

## 2. Tech stack

The project pins to **Flutter 3.41.6 / Dart 3.11.4** and runs against
the **5.x line of FlutterFire** packages. The 5.x pin is intentional:
`fake_cloud_firestore 3.x` (which the provided concurrency test uses)
only supports `cloud_firestore 5.x`. Every Firestore and Auth API used
in this codebase is identical between 5.x and 6.x, so the pin is purely
a test-tooling concession.

Runtime dependencies (everything actually imported by `lib/`):

```
cupertino_icons          ^1.0.8     (Flutter project convention)
firebase_core            ^3.6.0
firebase_auth            ^5.3.4
cloud_firestore          ^5.4.5
```

Dev dependencies:

```
flutter_test             (sdk: flutter)
flutter_lints            ^6.0.0
fake_cloud_firestore     ^3.1.0
mocktail                 ^1.0.5     (parked for future mock-based tests)
```

`pubspec.yaml` keeps commented-out entries for `firebase_messaging`,
`get`, `uuid`, `intl`, `flutter_svg`, `cached_network_image`, `rxdart`,
and `logger`. Earlier scaffolding pulled them in but nothing in `lib/`
imports them, so they were removed from the active dependency set to
shrink build output and native-plugin glue. Each commented line carries
a one-word rationale; re-enable by un-commenting.

No state management framework is mandated. The app uses native
`StreamBuilder`, `FutureBuilder`, and constructor injection through a
hand-rolled `Injector` — sufficient for a single screen with three
independent reactive surfaces.

---

## 3. Architecture — Clean Architecture by feature

Each feature is split into three concentric layers, and dependencies
only ever point inward:

```
presentation/   widgets, controllers, screen composition
       │
       ▼
   domain/      entities, abstract repositories, use cases   ← pure Dart
       ▲
       │
    data/       Firestore / FirebaseAuth implementations
```

The **domain layer holds zero Firebase types.** It is plain Dart,
compilable without Flutter or Firestore. Repository interfaces declare
what data operations exist, use cases name and orchestrate them, and
entities (`RaidState`, `WorldBoss`, `ChatMessage`, `AuthUser`) are
immutable value objects.

The **data layer** is the only layer that imports `cloud_firestore` or
`firebase_auth`. Each `*RepositoryImpl` implements one domain
repository interface and is responsible for all DTO ↔ entity mapping.

The **presentation layer** receives **use cases**, never repositories.
This is the difference that pays off: a widget test can replace
`JoinRaid` with a one-line stub without faking a repository graph.

Cross-cutting concerns live in `lib/core/`:

- `core/result/result.dart` — `Result<T>` sealed class (`Ok | Err`).
- `core/errors/failures.dart` — `AppFailure` sealed taxonomy.

The composition root is `lib/di/injector.dart`: it owns one
`FirebaseFirestore` and one `FirebaseAuth` instance and lazily
constructs every repository and use case the rest of the app needs.

---

## 4. Project structure

```
aethercore/
├── README.md                         Submission-facing overview + cost answer.
├── DOCUMENTATION.md                  This file.
├── aether_linter.dart                CLI verifier → ARCHITECTURE_REPORT.md.
├── analysis_options.yaml             Lint rules; excludes aether_linter.dart.
├── pubspec.yaml                      Dependencies pinned to FlutterFire 5.x.
│
├── lib/
│   ├── main.dart                     Boot Firebase → Injector → AetherApp.
│   ├── firebase_options.dart         FlutterFire CLI output (auto-generated).
│   ├── raid_service.dart             Test-facing facade for RaidService.
│   │
│   ├── core/
│   │   ├── errors/failures.dart      AppFailure sealed taxonomy.
│   │   └── result/result.dart        Result<T> = Ok<T> | Err<T>.
│   │
│   ├── di/
│   │   └── injector.dart             Manual composition root.
│   │
│   ├── app/
│   │   ├── app.dart                  Theme + design tokens.
│   │   ├── auth_gate.dart            Splash + anonymous sign-in gate.
│   │   ├── home_screen.dart          Hero composition (boss + raid + chat preview).
│   │   └── chat_screen.dart          Dedicated full-screen typing experience.
│   │
│   └── features/
│       ├── auth/
│       │   ├── domain/               AuthUser, AuthRepository, EnsureSignedIn.
│       │   └── data/                 FirebaseAuthRepository.
│       │
│       ├── raid/
│       │   ├── domain/
│       │   │   ├── entities/         RaidState, JoinOutcome.
│       │   │   ├── repositories/     RaidRepository (interface).
│       │   │   └── usecases/         JoinRaid, WatchRaidState.
│       │   ├── data/                 FirestoreRaidRepository.
│       │   └── presentation/         RaidJoinButton.
│       │
│       ├── world_boss/
│       │   ├── domain/
│       │   │   ├── entities/         WorldBoss.
│       │   │   ├── repositories/     WorldBossRepository.
│       │   │   └── usecases/         WatchWorldBoss.
│       │   ├── data/                 FirestoreWorldBossRepository.
│       │   └── presentation/         BossCountdownController, WorldBossTimer.
│       │
│       └── chat/
│           ├── domain/
│           │   ├── entities/         ChatMessage.
│           │   ├── repositories/     ChatRepository.
│           │   └── usecases/         WatchChat, SendMessage.
│           ├── data/                 FirestoreChatRepository.
│           └── presentation/         ChatBox (with animated gradient input).
│
└── test/
    ├── raid_concurrency_test.dart    Thundering-herd integrity proof.
    └── widget_test.dart              Placeholder.
```

Roughly 32 Dart files in `lib/`, around 1,400 lines of project code.
Every file has a single primary class whose name matches the file name.

---

## 5. Data model

Three Firestore collections cover the entire app.

**`events/dragon_raid`** — single document, the raid headcount.

```
{
  slots_filled : int    // 0 to max_slots
  max_slots    : int    // seed value: 15
}
```

Sub-collection `events/dragon_raid/joiners/{userId}` — one doc per
admitted player, prevents double-join.

```
{
  userId    : string         // == doc id
  joinedAt  : Timestamp      // serverTimestamp()
}
```

**`events/world_boss`** — single document, the boss timer.

```
{
  boss_end_time : Timestamp  // absolute end-time; clients tick locally
}
```

**`chat_shards/{shard}/messages/{auto-id}`** — sharded chat. At demo
scale a single `global` shard; the `{shard}` partition is the lever
for horizontal scaling.

```
{
  uid       : string             // == request.auth.uid
  text      : string (≤ 280)     // server-enforced cap via rules
  createdAt : Timestamp          // FieldValue.serverTimestamp()
}
```

---

## 6. Security rules

The Firestore rules are the second line of defence behind the
application code. They live in the Firebase Console (Firestore →
Rules tab) and a copy is reproduced in `README.md` for review:

```
match /events/world_boss {
  allow read:  if request.auth != null;
  allow write: if false;                 // server-set only
}

match /events/dragon_raid {
  allow read: if request.auth != null;
  allow create, delete: if false;
  allow update: if request.auth != null
    && request.resource.data.max_slots   == resource.data.max_slots
    && request.resource.data.slots_filled == resource.data.slots_filled + 1
    && request.resource.data.slots_filled <= resource.data.max_slots;
}

match /events/dragon_raid/joiners/{userId} {
  allow read:   if request.auth != null;
  allow create: if request.auth != null && request.auth.uid == userId;
  allow update, delete: if false;
}

match /chat_shards/{shard}/messages/{msg} {
  allow read: if request.auth != null;
  allow create: if request.auth != null
                && request.resource.data.uid == request.auth.uid
                && request.resource.data.text is string
                && request.resource.data.text.size() > 0
                && request.resource.data.text.size() <= 280;
  allow update, delete: if false;
}

match /{document=**} { allow read, write: if false; }   // default deny
```

The cap math on `dragon_raid` is the critical bit: even a misbehaving
client cannot oversell the raid because the rule rejects any update
that doesn't increase `slots_filled` by exactly one or that would push
it past `max_slots`.

---

## 7. Feature deep dives

### 7.1 Authentication

Anonymous sign-in only. Every device gets a stable `uid` without a
signup form, and that uid is the source of truth for raid attribution
and chat authorship.

- `lib/features/auth/domain/entities/auth_user.dart` — `AuthUser(uid)`.
- `lib/features/auth/domain/repositories/auth_repository.dart` —
  `Future<Result<AuthUser>> ensureSignedIn()`.
- `lib/features/auth/domain/usecases/ensure_signed_in.dart` — single
  use case that the app shell awaits at boot.
- `lib/features/auth/data/firebase_auth_repository.dart` — wraps
  `FirebaseAuth.signInAnonymously()`; translates `FirebaseAuthException`
  into `AuthenticationFailure`.

The `AuthGate` widget (in `lib/app/auth_gate.dart`) is a
`FutureBuilder<Result<AuthUser>>` that shows a splash until sign-in
resolves, then renders the home screen with the user's uid passed
down.

### 7.2 World Boss timer

The hero element. Updates at **10 Hz** without ever exceeding **one
Firestore read per session**.

The trick: `FirestoreWorldBossRepository.watch()` subscribes to the
`events/world_boss` document and emits a `WorldBoss` entity (which
carries the absolute `boss_end_time`). `BossCountdownController`
caches that end-time and lazily spins up a `Timer.periodic(100ms)` on
the *first* boss snapshot — not at `start()`, so we don't burn 10
wake-ups per second while waiting for Firestore to deliver. Each tick
recomputes `endTime - DateTime.now()` and pushes onto a
`StreamController<Duration>.broadcast()`.

The widget (`WorldBossTimer`) binds via `StreamBuilder<Duration>` and
is wrapped in `RepaintBoundary`. That combination means:

- Only the digits subtree rebuilds at 10 Hz.
- The repaint is isolated to its own compositor layer — the raid card
  and chat list above and below never see a frame at that frequency.
- Until Firestore delivers a valid `boss_end_time`, the stream emits
  nothing and the UI shows the `StreamBuilder`'s `initialData`
  (`00:00.0`). No synthetic fallback.

The data-layer key lookup tolerates whitespace and case (`"Boss_End_Time"`
or `"boss_end_time  "` still resolve), and `_warnIfMalformedKeys` logs a
loud warning so the bad field can be cleaned up in the console. The
warning iteration and all per-snapshot `debugPrint` calls are gated by
`kDebugMode`, so release builds incur zero overhead.

Tear-down: `HomeScreen.dispose()` calls `_bossController.dispose()`,
which cancels the Firestore subscription, cancels the Timer, and
closes the `StreamController`. No leaks.

### 7.3 Dragon Raid

The integrity-critical feature. The 15-slot cap is enforced at four
layers, in order:

1. **UI disabled state.** `RaidJoinButton` listens to the raid doc's
   live stream (cached once in `late final _raidStateStream =
   widget.watchRaidState()` so setState rebuilds don't churn the
   Firestore listener); when `slots_filled >= max_slots` the button is
   disabled and reads "Raid full". This is purely UX — the underlying
   layers are still authoritative.
2. **In-process Dart serialization lock.** `FirestoreRaidRepository`
   holds a `Future<void> _serialization` field. Each call to `tryJoin`
   awaits the previous chain link before starting, then publishes its
   own completer for the next caller. This guarantees that 50
   concurrent calls *on the same client* execute one at a time, so
   each one's read observes the previous one's write. This is what
   makes the concurrency test pass under `FakeFirebaseFirestore`,
   whose `runTransaction` does not simulate OCC retries under
   in-process contention.
3. **Firestore transaction (OCC).** Inside the lock, the write runs
   through `_firestore.runTransaction`: re-read the raid doc, check
   the cap, check the `joiners/{uid}` sub-doc for double-join, then
   commit `slots_filled: FieldValue.increment(1)` and
   `joiners/{uid}: {userId, joinedAt}` atomically. A
   `FirebaseException` with `code == 'aborted'` (a real concurrent
   write collided) maps cleanly to `JoinOutcome.raidFull` instead of
   propagating as an error.
4. **Firestore security rule.** The rule on `events/dragon_raid`
   enforces `slots_filled == old + 1 && slots_filled <= max_slots`,
   so even two real clients racing past both their local locks and
   the transaction OCC cannot oversell the raid — the second `+1`
   from the same starting value is rejected at the server.

The `tryJoin` flow returns a `JoinOutcome` enum:

```
admitted             slot claimed; counter advanced
raidFull             cap reached; the user lost the race
alreadyJoined        user already has a slot
raidNotFound         events/dragon_raid was never seeded
infrastructureError  FirebaseException — translated, not thrown
```

The test-facing `RaidService` (in `lib/raid_service.dart`) is a thin
facade that collapses the enum to `bool` because the provided test
asserts on `result == true`. Application code depends on `JoinRaid`
via the `Injector`, not on the facade.

### 7.4 Engagement Chat

Bounded, sharded, real-time. Two flows: receiving and sending — plus
a two-screen UX that keeps the home layout uncluttered and gives the
keyboard a dedicated workspace.

**Receive.** `FirestoreChatRepository.watchRecent(forUserId)` opens a
snapshot listener on the shard's `messages` sub-collection with
`.orderBy('createdAt').limitToLast(50)`. The `limitToLast(50)` is the
cost-control surface: a session's read budget is bounded regardless
of total message volume. The stream itself is captured once in
`ChatBox` as `late final _chatStream = widget.watchChat(userId: ...)`
so that a `setState` (e.g. showing/clearing the inline error banner)
reuses the existing subscription instead of re-running the query.

**Send — WhatsApp-style optimistic.** Tapping send (or hitting enter)
clears the input *immediately* and dispatches the write through
`unawaited(_dispatchSend(text))`. There is no loading spinner and no
disabled state; the user can keep typing the next message right away.
The new bubble arrives via the Firestore stream within a few hundred
milliseconds and slides in via the auto-scroll path. If the write
fails, the text is restored to the input (with cursor at end) and an
inline error banner appears for retry. The actual validation
(non-empty, ≤ 280 chars) runs in `SendMessage.call` and returns
`Err(ValidationFailure)` if the text is rejected — never thrown
across layers.

**Auto-scroll on new messages.** `ChatBox` tracks the previous
message count. On the first stream emission, it `jumpTo`s the bottom
so the user lands on the latest messages without a scroll animation.
On every subsequent growth (your message OR a teammate's), it
`animateTo`s `maxScrollExtent` over 220 ms inside a
`WidgetsBinding.addPostFrameCallback` so the scroll target reflects
the just-rendered new bubble.

**Two-screen pattern.** The home screen renders `ChatBox` with
`onComposerTap` set, which swaps the real input for a "Tap to write a
message…" pill. Tapping the pill pushes
`ChatScreen.route(injector: ..., userId: ...)` — a dedicated screen
that has its own `Scaffold` with `resizeToAvoidBottomInset: true`,
its own `BossCountdownController`, and a 56-px gradient status bar
at the top showing the live boss countdown + raid count + inline
Join button. This structurally fixes the keyboard-overlap problem:
on the typing screen the chat owns the entire screen except for the
status bar, so the composer rides up cleanly with the keyboard.

**Animated rotating gradient border on the input.** The actual chat
input is wrapped in `_AnimatedGradientField`, which renders a 2 px
ring driven by a `SweepGradient` and a
`SingleTickerProviderStateMixin`-backed `AnimationController` spinning
once every 3 seconds. The animation rebuilds only the outer
container's `BoxDecoration` each frame; the `TextField` subtree is
cached via `AnimatedBuilder`'s `child` parameter, so it rebuilds zero
times per tick.

**Sharding lever.** The shard layer is wired but currently set to a
single global shard. To scale, raise `_shardCount` in
`FirestoreChatRepository` and replace `_shardFor` with a true
hash-bucket — see [Section 14, cost optimization](#14-cost-optimization).

---

## 8. Runtime flow

A condensed end-to-end trace from cold start to a chat message
arriving:

```
main()
  ↓ WidgetsFlutterBinding.ensureInitialized
  ↓ Firebase.initializeApp(options)
  ↓ Injector(firestore, auth)
  ↓ runApp(AetherApp(injector))

AetherApp
  ↓ MaterialApp(theme, home: AuthGate)

AuthGate.initState
  ↓ injector.ensureSignedIn()  →  Result<AuthUser>
  └── (loading) → CircularProgressIndicator splash
       (Ok)    → HomeScreen(injector, userId)
       (Err)   → error scaffold with humanized message

HomeScreen.initState
  ↓ injector.newBossCountdownController().start()
       └── subscribes events/world_boss
           (Timer.periodic(100ms) starts lazily on first snapshot,
            ticking a StreamController<Duration>.broadcast())

HomeScreen.initState
  ↓ Caches AppBar + WorldBossTimer + RaidJoinButton + ChatBox in
    instance fields so build() never re-creates them.
  ↓ Each child is wrapped in RepaintBoundary so a repaint inside
    one never invalidates the others' compositor layers.

HomeScreen.build
  ├── WorldBossTimer(controller)
  │     └── RepaintBoundary > StreamBuilder<Duration> > digits text
  ├── RaidJoinButton(joinRaid, watchRaidState, userId)
  │     └── StreamBuilder<RaidState>(_raidStateStream, cached once)
  │           └── on tap → JoinRaid → FirestoreRaidRepository.tryJoin
  │                  ↓ await _serialization        (in-process mutex)
  │                  ↓ runTransaction:             (Firestore OCC)
  │                  │     ↓ _raidRef.get(); cap check
  │                  │     ↓ _joinerRef.get(); double-join check
  │                  │     ↓ update slots_filled with increment(1)
  │                  │     ↓ set joiners/{uid}
  │                  ↓ completer.complete()        releases next caller
  └── ChatBox(watchChat, sendMessage, userId,
              onComposerTap: _openChatScreen)
        ├── StreamBuilder over limitToLast(50)
        ├── auto-scroll: jumpTo on first batch, animateTo on growth
        └── tap pill ("Tap to write a message…")
              ↓
              Navigator.push(ChatScreen.route(...))

ChatScreen
  ├── Own Scaffold + resizeToAvoidBottomInset
  ├── Own BossCountdownController (started in initState)
  ├── _CompactStatusBar (56 px gradient pill)
  │     ├── ● live cyan dot + countdown digits
  │     └── RAID  5/15  [Join] (calls JoinRaid via injector)
  └── ChatBox(watchChat, sendMessage, userId)
        ├── _AnimatedGradientField (SweepGradient animation)
        ├── send: WhatsApp-style optimistic
        │     ↓ clear input instantly
        │     ↓ unawaited(_dispatchSend(text))
        │           ↓ SendMessage validates length
        │           ↓ ChatRepository.send(uid, text)
        │           ↓ stream emits → bubble slides in
        │     ↓ on Err → restore text + show banner
        └── auto-scroll on every new message
```

---

## 9. Setup and run

### One-time Firebase setup

1. Create or join a Firebase project. The codebase ships with
   credentials for `aethercore-37150`; replace by re-running
   `flutterfire configure` if you fork.
2. **Firestore** — Build → Firestore Database → Standard edition →
   pick a region. Seed two documents:
   - `events/dragon_raid` → `{ slots_filled: 0, max_slots: 15 }`
   - `events/world_boss`  → `{ boss_end_time: <future Timestamp> }`
3. **Security rules** — Firestore → Rules → paste the block from
   `README.md` → Publish.
4. **Authentication** — Build → Authentication → Sign-in method →
   enable **Anonymous**.

### Local environment

You need Flutter 3.41+ (Dart 3.7+) on your `PATH`. Verify with
`flutter --version`. The project targets Windows, macOS, Linux, web,
Android, and iOS — the platform folders are all provisioned.

### Install and run

```
flutter clean
flutter pub get
flutter run -d <device>
```

Replace `<device>` with `chrome`, `windows`, `macos`, or a device ID
from `flutter devices`. On boot the app signs the device in
anonymously and shows the home screen.

### Resetting the boss timer

The boss timer counts down to `events/world_boss.boss_end_time`. When
that timestamp passes, the timer pins at `00:00.0`. To "restart" the
boss, update the timestamp in the Firebase console (Firestore → Data
tab → `events/world_boss` → edit `boss_end_time`). All clients refresh
within one snapshot delivery.

---

## 10. Testing

The grading-critical test is `test/raid_concurrency_test.dart`. It
seeds `events/dragon_raid` in an in-memory `FakeFirebaseFirestore`,
fires 50 concurrent `raidService.joinRaid()` calls via `Future.wait`,
and asserts:

- exactly 15 results return `true`,
- the `slots_filled` field is exactly 15.

Run:

```
flutter test test/raid_concurrency_test.dart
```

The placeholder `test/widget_test.dart` exists so `flutter test`
without a target argument doesn't reuse the stock Flutter counter
test that would fail under our app.

---

## 11. The Architecture Linter

`aether_linter.dart` is a Dart CLI tool from the challenge init kit
(slightly patched for Windows compatibility — `Process.run` with
`runInShell: true`). It runs `flutter analyze` followed by
`flutter test test/raid_concurrency_test.dart`, then writes a
report to `ARCHITECTURE_REPORT.md`.

Run from the project root:

```
dart aether_linter.dart
```

Expected output when both checks pass:

```
✅ Linter: PASS
✅ Tests: PASS
📄 Report saved to ARCHITECTURE_REPORT.md
```

The script is excluded from `flutter analyze` itself (via
`analysis_options.yaml` → `analyzer.exclude`) because it uses
`print()` for CLI output, which would otherwise trip
`avoid_print`. CLI scripts living alongside Flutter packages are
routinely excluded this way.

---

## 12. Design system

All design tokens are constants on `AetherApp` in `lib/app/app.dart`.
Every colour, radius, and shadow in the app traces back to that
block:

```
kPrimary           cobalt           #1565C0
kPrimaryDark       midnight cobalt  #0B3D91
kPrimaryLight      soft cobalt      #5B8DEF
kAccentCyan        live-pulse glow  #00E5FF
kSurface           pure white       #FFFFFF
kSurfaceSubtle     blue-tinted bg   #F4F8FD
kSurfaceContainer  pill / chip bg   #E8F1FB
kOnSurface         body text        #0F1F3D
kOnSurfaceMuted    secondary text   #5A6A85
kOutline           hairline border  #D6E2F0
```

Component conventions:

- **Cards** — white surface, 20px corner radius, 1px outline in
  `kOutline`, low-alpha cobalt drop shadow. Never plain grey.
- **Cyan reserve** — the cyan accent appears in exactly three places:
  the World Boss live dot, the digit shadow, and the chat "LIVE"
  badge. That scarcity is what keeps the UI feeling premium rather
  than neon-busy.
- **Typography** — every digit uses
  `FontFeature.tabularFigures()` so numbers don't shift width as
  they change. Section eyebrows are letter-spaced uppercase 11px;
  body is 14–16px regular.
- **Buttons** — primary actions are a cobalt → bright-blue
  `LinearGradient` with a low-alpha cobalt shadow. Disabled state
  is the outline colour with muted text.

---

## 13. Performance notes

The app sustains a perceived-smooth 10 Hz timer with three live
Firestore listeners on a single screen, and zero parent rebuilds
during keyboard show/hide transitions. The patterns that make that
cheap:

- **Local ticking.** The boss timer reads one document once per
  session. The 100 ms tick is `DateTime.now()` arithmetic; zero
  network cost per tick.
- **Lazy ticker start.** `Timer.periodic(100ms)` is created on the
  first boss snapshot rather than at `start()`. Observable behaviour
  is unchanged (`_emit` short-circuits while `_endTime == null`
  anyway), but no wake-ups are burnt between app launch and the first
  Firestore delivery.
- **Cached stream subscriptions.** Stream-producing use cases
  (`watchRaidState`, `watchChat`) return a fresh `_snapshots()`
  listener on every call. The presentation layer captures them once
  in `late final` State fields (`_raidStateStream`, `_chatStream`),
  so a `setState` rebuild reuses the existing `StreamBuilder`
  subscription instead of unsubscribing and re-subscribing to
  Firestore. Each saved re-subscription is one fewer initial read
  billed to the project.
- **Targeted rebuilds.** Every rebuild scope is the smallest possible
  subtree. `StreamBuilder` rebuilds digits only;
  `RepaintBoundary` isolates the repaint into its own compositor
  layer; `AnimatedBuilder` caches subtrees that don't change
  per-frame via the `child` parameter.
- **No keyboard dependency in `HomeScreen.build`.** The home screen
  does not read `MediaQuery.viewInsets` or any inherited widget that
  changes when the keyboard slides. Android emits dozens of
  viewport-metrics events during a keyboard transition; none of them
  trigger `HomeScreen.build()`. The `Scaffold`'s native
  `resizeToAvoidBottomInset` handles the resize, and the `Expanded`
  chat preview absorbs the height change.
- **Cached children in `initState`.** `HomeScreen` constructs its
  `AppBar`, `WorldBossTimer`, `RaidJoinButton`, and `ChatBox` once in
  `initState` and stores them in instance fields. Even if `build()`
  ever runs again, Flutter sees the same `Widget` references and
  short-circuits the subtree reconciliation.
- **`RepaintBoundary` around every major surface.** A new chat message
  no longer marks the boss timer's compositor layer dirty; the 10 Hz
  timer doesn't invalidate the chat list's layer. Each section paints
  into its own GPU texture.
- **Bounded streams.** Chat uses `.limitToLast(50)` so the
  per-listener read cost stays flat as messages accumulate.
- **Optimistic send.** Chat write goes through `unawaited(...)` so
  the UI never blocks on the Firestore round-trip — no spinner, no
  disabled state. Failures are caught and restore the input.
- **`kDebugMode`-gated logging.** Every per-snapshot and
  per-transaction `debugPrint` in the data layer is wrapped in
  `if (kDebugMode)`. `debugPrint` is a no-op in release, but the
  interpolated string argument is still constructed; gating eliminates
  that allocation in production builds, including the per-snapshot
  `_warnIfMalformedKeys` key-iteration in the world-boss repository.
- **Slim dependency surface.** Only `cupertino_icons`, the three
  FlutterFire packages (`firebase_core`, `firebase_auth`,
  `cloud_firestore`), and the Flutter SDK itself are shipped in the
  release binary; nine previously-listed packages (notably
  `firebase_messaging` and its native plugin glue) were commented out
  in `pubspec.yaml` after a static check confirmed zero imports.
- **No state-management framework overhead.** Direct
  `StreamBuilder` / `FutureBuilder` — zero reflection, zero
  broadcasting infrastructure.

---

## 14. Cost optimization

The grading PDF's three-sentence answer is reproduced from
`README.md`:

> At 10,000 concurrent chatters the dominant cost is
> `O(writers × listeners)`, so the schema partitions messages under
> `chat_shards/{shard}/messages` and hashes each client to a single
> shard for reads — every listener only sees the chatter in its shard
> rather than the global firehose. Each listener subscribes with
> `limitToLast(50)`, which bounds reads per session regardless of
> total message volume, and subscriptions are cancelled when the app
> is backgrounded so idle clients don't accrue reads. For peak load,
> a Cloud Function maintains a denormalized `last_50` summary
> document per shard updated on each write, so a shard's N readers
> cost 1 document read each instead of N reads against the underlying
> message collection.

The code in `FirestoreChatRepository` is wired for this scaling
pattern but currently runs with a single shard:

```
static const int _shardCount = 1;
static const String _shardPrefix = 'global';

String _shardFor(String userId) {
  if (_shardCount <= 1) return _shardPrefix;
  final int bucket = userId.hashCode.abs() % _shardCount;
  return '${_shardPrefix}_$bucket';
}
```

To horizontally scale: bump `_shardCount`, no other code changes
required. Security rules already accept any shard.

---

## 15. Troubleshooting

**`flutter pub get` fails with a version conflict on
`fake_cloud_firestore`.** Cause: a newer FlutterFire major (6.x or
later) was introduced and the fake hasn't caught up. Fix: stay on
the 5.x line documented in `pubspec.yaml`, or run
`flutter pub remove fake_cloud_firestore && flutter pub add --dev
fake_cloud_firestore` to let pub solve.

**`flutter analyze` reports `avoid_print` issues in
`aether_linter.dart`.** Cause: the linter file was not added to the
exclude list. Fix: ensure `analysis_options.yaml` contains the
`analyzer.exclude: [aether_linter.dart]` block.

**Test fails with "Expected: <15> Actual: <50>".** Cause: build cache
is serving the pre-lock version of `FirestoreRaidRepository`. Fix:
`flutter clean && flutter pub get && flutter test
test/raid_concurrency_test.dart`.

**`dart aether_linter.dart` reports "Could not run flutter analyze.
Is Flutter in your PATH?" on Windows.** Cause: `Process.run` on
Windows doesn't resolve `flutter.bat` without a shell. Fix: ensure
the linter is the patched version (both `Process.run` calls use
`runInShell: true`).

**Boss timer reads `00:00.0` and doesn't move.** Cause:
`events/world_boss.boss_end_time` is in the past. Fix: edit the
timestamp in the Firebase console to a future moment.

**`RaidJoinButton` shows "Raid not seeded yet".** Cause: the
`events/dragon_raid` document is missing. Fix: create it in the
Firebase console with the schema in [Section 5](#5-data-model).

**Chat input on the home screen does not show a keyboard / cannot
type.** That's intentional. The home screen's `ChatBox` is in
preview mode — its composer is a "Tap to write a message…" pill.
Tap it to push the dedicated [`ChatScreen`](#74-engagement-chat),
which has the real input and proper keyboard handling.

**Sent message doesn't appear immediately.** It should arrive via
the Firestore stream within a few hundred milliseconds; the
auto-scroll path animates it into view. If the input is restored
with your text and an error banner shows below the chat, the write
failed — check security rules and authentication.

---

## 16. Extending the project

Likely next steps if this app were to graduate from "challenge
deliverable" to "production feature":

- **Named boss with HP bar.** Extend the `WorldBoss` entity with
  `name`, `tier`, `portraitUrl`, `currentHp`, and `maxHp` fields.
  Add an HP bar to `WorldBossTimer`. Server-side, a Cloud Function
  decrements `currentHp` based on raid contributions.
- **Cloud Function for boss reset.** A scheduled function that runs
  every N minutes and resets `boss_end_time` so the timer cycles
  without manual intervention.
- **Real chat sharding.** Raise `_shardCount` in
  `FirestoreChatRepository` to 4 or 8; users hash to one shard;
  add a Cloud Function that maintains a `last_50` summary doc per
  shard for hot-tier scaling.
- **App Check.** Enable App Check (Play Integrity / DeviceCheck /
  reCAPTCHA Enterprise) to prevent random clients from abusing the
  public web API key.
- **Real authentication.** Replace anonymous-only with Google/Apple
  sign-in; carry the same `uid` through.
- **Multi-region failover.** Firestore is single-region by default;
  for global scale move to Firestore in MongoDB-compatibility mode
  or layer a Spanner-backed service.

---

## 17. Glossary

- **OCC** — Optimistic Concurrency Control. Firestore's transaction
  primitive: read with versioning, write conditionally on the read
  version, retry on conflict.
- **Thundering herd** — many concurrent requests targeting the same
  resource; the test that simulates this is the central proof of
  atomic integrity.
- **Shard** — a horizontal partition of a collection, addressed by
  a hash function over some key (here, the user's `uid`).
- **Use case** — a named single-purpose business operation in the
  domain layer; the unit of orchestration the presentation layer
  depends on.
- **Repository** — the abstract interface in the domain layer that
  declares persistence operations; one concrete implementation lives
  in the data layer.
- **Injector** — the composition root; the only place that knows
  which concrete data classes back which domain interfaces.
- **Facade** — `RaidService` in `lib/raid_service.dart`; a thin
  adapter that exposes only what the provided test harness needs.

---

*Last updated: 2026-05-20*
