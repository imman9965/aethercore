# AetherCore — Project Aether

A single-screen Flutter "nervous system" for a global MMORPG: a 100 ms World Boss
countdown, a 15-slot Geo-Raid signup, and a real-time engagement chat. Backed by
Cloud Firestore, gated on Anonymous Authentication, architected for atomic
integrity under a thundering herd.

## Architectural Outcomes

**Global Atomic Integrity.** `FirestoreRaidRepository.tryJoin` wraps a
read-then-write in `FirebaseFirestore.runTransaction`. Under 50-concurrent
contention, Firestore's optimistic concurrency control retries colliding
transactions until every reader sees a consistent `slots_filled`, so exactly
`max_slots` joins return `JoinOutcome.admitted` and the rest return one of
`raidFull`, `alreadyJoined`, `raidNotFound`, or `infrastructureError`. The
`JoinRaid` use case is the call site the UI depends on; `lib/raid_service.dart`
is a 30-line facade that collapses the outcome enum to a `bool` for the
provided test harness. `test/raid_concurrency_test.dart` proves the cap with
an in-memory fake — no Firebase project required to verify.

**100 ms Pulse Without 100 ms Reads.** `FirestoreWorldBossRepository` opens a
single snapshot listener on `events/world_boss` and emits the absolute
end-time. `BossCountdownController` caches that end-time and runs a local
`Timer.periodic(100ms)` that recomputes `remaining` from `DateTime.now()`,
pushing each value through a `ValueNotifier`. `WorldBossTimer` binds to that
notifier via `ValueListenableBuilder` wrapped in `RepaintBoundary`, so the
timer text is the only thing rebuilt at 10 Hz — the raid button and chat list
never see a frame at that frequency.

**Forced Lints, Forced Error Handling.** Code is strongly typed: `dynamic`
appears only at the Firestore boundary and is cast immediately. Every fallible
domain operation returns `Result<T>` (sealed `Ok | Err`) or a domain-specific
enum (`JoinOutcome`); call sites must handle both arms or the compiler refuses
the program. Exception handlers translate `FirebaseException` into a typed
`AppFailure` — there is no path through the code that silently swallows an
error. No `print`, no empty `catch`, no unawaited futures.

## Cost & Sharding — 10,000 Concurrent Chatters

> *If 10,000 players are chatting in the engagement box at once, how would you
> structure the Firebase queries to avoid a massive "Read" cost bill?*

At 10,000 concurrent chatters the dominant cost is `O(writers × listeners)`, so
the schema partitions messages under `chat_shards/{shard}/messages` and hashes
each client to a single shard for reads — every listener only sees the chatter
in its shard rather than the global firehose. Each listener subscribes with
`limitToLast(50)`, which bounds reads per session regardless of total message
volume, and subscriptions are cancelled when the app is backgrounded so idle
clients don't accrue reads. For peak load, a Cloud Function maintains a
denormalized `last_50` summary document per shard updated on each write, so a
shard's N readers cost 1 document read each instead of N reads against the
underlying message collection.

## Architecture — Clean Architecture by feature

The codebase follows Uncle Bob's Clean Architecture: a feature is split into
three concentric layers, and dependencies only ever point inward.

```
domain   (pure Dart — entities, repository interfaces, use cases)
  ▲
data     (Firestore / FirebaseAuth implementations of domain interfaces)
  ▲
presentation  (widgets + controllers — consume use cases, never repositories)
```

The domain layer holds zero Firebase types. Swapping Firestore for a different
backend would touch only `data/` and the `Injector`. UI tests can stub use
cases directly without spinning up Firebase.

```
lib/
├── main.dart                          Wires Firebase → Injector → AetherApp.
├── firebase_options.dart              FlutterFire CLI output.
├── raid_service.dart                  Thin facade preserving the test API.
├── core/
│   ├── errors/failures.dart           Sealed AppFailure taxonomy.
│   └── result/result.dart             Sealed Result<T> (Ok | Err).
├── di/
│   └── injector.dart                  Manual composition root.
├── app/
│   ├── app.dart                       MaterialApp + theme.
│   ├── auth_gate.dart                 Anonymous sign-in gate.
│   └── home_screen.dart               Single-screen composition.
└── features/
    ├── auth/
    │   ├── domain/                    AuthUser, AuthRepository, EnsureSignedIn.
    │   └── data/                      FirebaseAuthRepository.
    ├── raid/
    │   ├── domain/                    RaidState, JoinOutcome, RaidRepository,
    │   │                              JoinRaid, WatchRaidState.
    │   ├── data/                      FirestoreRaidRepository (transactional).
    │   └── presentation/              RaidJoinButton.
    ├── world_boss/
    │   ├── domain/                    WorldBoss, WorldBossRepository,
    │   │                              WatchWorldBoss.
    │   ├── data/                      FirestoreWorldBossRepository.
    │   └── presentation/              BossCountdownController (100ms ticker),
    │                                  WorldBossTimer.
    └── chat/
        ├── domain/                    ChatMessage, ChatRepository,
        │                              WatchChat, SendMessage.
        ├── data/                      FirestoreChatRepository (sharded).
        └── presentation/              ChatBox.

test/
├── raid_concurrency_test.dart         Thundering-herd integrity proof.
└── widget_test.dart                   Placeholder.

aether_linter.dart                     Outcome verifier → ARCHITECTURE_REPORT.md.
```

### Why `lib/raid_service.dart` is a facade

The provided concurrency test instantiates `RaidService(firestore: …)` directly.
Rather than fight that convention, `raid_service.dart` is a thin adapter that
internally constructs `FirestoreRaidRepository` and the `JoinRaid` use case,
exposing only the boolean `joinRaid` the test consumes. Application code
depends on `JoinRaid` via the `Injector`, never on the facade.

## Verification

From the project root:

```
flutter pub get
flutter analyze
flutter test test/raid_concurrency_test.dart
dart aether_linter.dart
```

The final command produces `ARCHITECTURE_REPORT.md`, which is the artefact
submitted alongside this repo.

## Firebase Console Setup

This repo expects:

1. **Cloud Firestore** (Standard edition) provisioned in any region.
2. Seed documents:
   - `events/dragon_raid` → `{ slots_filled: 0, max_slots: 15 }`
   - `events/world_boss` → `{ boss_end_time: <future Timestamp> }`
3. **Anonymous** sign-in provider enabled.
4. Security rules from `firestore.rules` (included in this README's "Security
   Rules" section below — paste into Firestore → Rules tab and publish).

### Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /events/world_boss {
      allow read:  if request.auth != null;
      allow write: if false;
    }

    match /events/dragon_raid {
      allow read: if request.auth != null;
      allow create, delete: if false;
      allow update: if request.auth != null
        && request.resource.data.max_slots == resource.data.max_slots
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

    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

The `dragon_raid` update rule is the second line of defence behind the
transaction: even a misbehaving client cannot oversell the raid because the
database itself refuses any update that does not increment `slots_filled` by
exactly one and stay within `max_slots`.
