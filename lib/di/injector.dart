import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/auth/data/firebase_auth_repository.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/ensure_signed_in.dart';
import '../features/chat/data/firestore_chat_repository.dart';
import '../features/chat/domain/repositories/chat_repository.dart';
import '../features/chat/domain/usecases/send_message.dart';
import '../features/chat/domain/usecases/watch_chat.dart';
import '../features/raid/data/firestore_raid_repository.dart';
import '../features/raid/domain/repositories/raid_repository.dart';
import '../features/raid/domain/usecases/join_raid.dart';
import '../features/raid/domain/usecases/watch_raid_state.dart';
import '../features/world_boss/data/firestore_world_boss_repository.dart';
import '../features/world_boss/domain/repositories/world_boss_repository.dart';
import '../features/world_boss/domain/usecases/watch_world_boss.dart';
import '../features/world_boss/presentation/boss_countdown_controller.dart';

/// Manual composition root.
///
/// No DI framework — for an app this size, constructor injection from a
/// single Injector is cleaner than dragging in `get_it` or `riverpod`.
/// The Injector owns repository instances (singletons within an app
/// session) and constructs use cases / controllers on demand.
class Injector {
  Injector({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Lazy singletons — repositories are stateless wrappers, safe to cache.
  late final AuthRepository _authRepo =
      FirebaseAuthRepository(auth: _auth);
  late final RaidRepository _raidRepo =
      FirestoreRaidRepository(firestore: _firestore);
  late final WorldBossRepository _bossRepo =
      FirestoreWorldBossRepository(firestore: _firestore);
  late final ChatRepository _chatRepo =
      FirestoreChatRepository(firestore: _firestore);

  // Auth
  EnsureSignedIn get ensureSignedIn =>
      EnsureSignedIn(repository: _authRepo);

  // Raid
  JoinRaid get joinRaid => JoinRaid(repository: _raidRepo);
  WatchRaidState get watchRaidState =>
      WatchRaidState(repository: _raidRepo);

  // World Boss
  WatchWorldBoss get watchWorldBoss =>
      WatchWorldBoss(repository: _bossRepo);
  BossCountdownController newBossCountdownController() {
    return BossCountdownController(watchWorldBoss: watchWorldBoss);
  }

  // Chat
  WatchChat get watchChat => WatchChat(repository: _chatRepo);
  SendMessage get sendMessage => SendMessage(repository: _chatRepo);
}
