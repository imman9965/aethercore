/// Immutable snapshot of the live raid headcount.
///
/// Pure Dart — no Firebase types in the domain layer. The data layer maps
/// Firestore documents into this shape at the boundary.
final class RaidState {
  const RaidState({
    required this.slotsFilled,
    required this.maxSlots,
  });

  final int slotsFilled;
  final int maxSlots;

  bool get isFull => slotsFilled >= maxSlots;
  int get slotsRemaining => maxSlots - slotsFilled;
}
