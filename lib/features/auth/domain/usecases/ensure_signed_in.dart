import '../../../../core/result/result.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

final class EnsureSignedIn {
  const EnsureSignedIn({required AuthRepository repository})
      : _repository = repository;
  final AuthRepository _repository;

  Future<Result<AuthUser>> call() => _repository.ensureSignedIn();
}
