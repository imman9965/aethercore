/// Domain-level failure taxonomy. All failure paths surface here so we
/// never have to write empty `catch` blocks or check string equality on
/// exception messages.
sealed class AppFailure {
  const AppFailure();
}

/// Generic infrastructure error (network, Firestore unavailable, etc).
final class InfrastructureFailure extends AppFailure {
  const InfrastructureFailure(this.message, {this.cause});
  final String message;
  final Object? cause;
}

/// The caller is not signed in or sign-in failed.
final class AuthenticationFailure extends AppFailure {
  const AuthenticationFailure(this.message);
  final String message;
}

/// The requested resource was not found.
final class NotFoundFailure extends AppFailure {
  const NotFoundFailure(this.resource);
  final String resource;
}

/// Caller violated a business rule (e.g. message exceeds size cap).
final class ValidationFailure extends AppFailure {
  const ValidationFailure(this.reason);
  final String reason;
}

/// Catch-all for unexpected exceptions. Carries the original error for
/// observability; nothing should be silently swallowed.
final class UnknownFailure extends AppFailure {
  const UnknownFailure(this.error, {this.stackTrace});
  final Object error;
  final StackTrace? stackTrace;
}
