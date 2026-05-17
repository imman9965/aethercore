import '../../../../core/result/result.dart';
import '../entities/auth_user.dart';

/// Domain-level abstraction over authentication.
abstract interface class AuthRepository {
  Future<Result<AuthUser>> ensureSignedIn();
}
