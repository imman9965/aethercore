/// All possible outcomes of a `joinRaid` attempt.
///
/// Returning an enum (rather than `bool`) makes the failure modes explicit
/// at the call site and lets the UI render an accurate message without
/// the caller having to inspect exception strings.
enum JoinOutcome {
  /// The user was admitted; `slots_filled` advanced by one.
  admitted,

  /// The raid was already at capacity when the transaction committed.
  raidFull,

  /// The user already had a slot — atomic guard against double-join.
  alreadyJoined,

  /// The raid document doesn't exist (seeding step skipped).
  raidNotFound,

  /// Infrastructure error (network, Firestore unavailable, etc).
  infrastructureError,
}
