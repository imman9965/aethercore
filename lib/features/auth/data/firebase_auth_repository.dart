import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../domain/entities/auth_user.dart';
import '../domain/repositories/auth_repository.dart';

/// Firebase-backed [AuthRepository] using anonymous sign-in.
///
/// Anonymous auth gives every device a stable `uid` without a signup
/// flow — that uid is the source of truth for raid attribution and
/// chat authorship.
final class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({required FirebaseAuth auth}) : _auth = auth;

  final FirebaseAuth _auth;

  @override
  Future<Result<AuthUser>> ensureSignedIn() async {
    try {
      final User? existing = _auth.currentUser;
      if (existing != null) {
        return Ok<AuthUser>(AuthUser(uid: existing.uid));
      }
      final UserCredential credential = await _auth.signInAnonymously();
      final User? user = credential.user;
      if (user == null) {
        return const Err<AuthUser>(
          AuthenticationFailure(
            'Anonymous sign-in returned null. Is the Anonymous provider '
            'enabled in the Firebase console?',
          ),
        );
      }
      return Ok<AuthUser>(AuthUser(uid: user.uid));
    } on FirebaseAuthException catch (e) {
      return Err<AuthUser>(
        AuthenticationFailure(e.message ?? 'Sign-in failed.'),
      );
    }
  }
}
