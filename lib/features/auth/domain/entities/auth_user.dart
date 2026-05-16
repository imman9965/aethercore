/// Domain identity of the signed-in user. Pure Dart — no Firebase types.
final class AuthUser {
  const AuthUser({required this.uid});
  final String uid;
}
