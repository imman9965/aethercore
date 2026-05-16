import '../errors/failures.dart';

/// A sealed two-track return type: every call site must handle both
/// success and failure paths or it won't compile.
///
/// Prefer [Result] over throwing exceptions across layer boundaries so
/// that the type system, not convention, enforces error handling.
sealed class Result<T> {
  const Result();

  /// Convenience constructors for call sites that want to read more linearly.
  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(AppFailure failure) = Err<T>;

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  /// Returns the success value or `null` if this is an error.
  T? get valueOrNull => switch (this) {
        Ok<T>(value: final v) => v,
        Err<T>() => null,
      };

  /// Pattern-matched terminal: forces the caller to handle both arms.
  R when<R>({
    required R Function(T value) ok,
    required R Function(AppFailure failure) err,
  }) {
    return switch (this) {
      Ok<T>(value: final v) => ok(v),
      Err<T>(failure: final f) => err(f),
    };
  }
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final AppFailure failure;
}
