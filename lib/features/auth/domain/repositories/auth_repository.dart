import '../../../../core/result/result.dart';
import '../entities/auth_user.dart';

/// Domain-level abstraction over authentication.
abstract interface class AuthRepository {
  /// Returns the current user if already signed in, otherwise signs in
  /// anonymously and returns the new user.
  Future<Result<AuthUser>> ensureSignedIn();
}
