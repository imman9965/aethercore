import 'package:flutter/material.dart';

import '../core/colors/colors.dart';
import '../features/raid/domain/entities/join_outcome.dart';

class OutcomeBanner extends StatelessWidget {
  const OutcomeBanner({super.key, required this.outcome});

  final JoinOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color tint, String text) = switch (outcome) {
      JoinOutcome.admitted => (
      Icons.check_circle_rounded,
      const Color(0xFF1B5E20),
      'Slot claimed. The dragon awaits.',
      ),
      JoinOutcome.raidFull => (
      Icons.lock_clock_outlined,
      AppColors.kOnSurfaceMuted,
      'Raid filled before your request landed.',
      ),
      JoinOutcome.alreadyJoined => (
      Icons.info_outline_rounded,
      AppColors.kPrimary,
      'You already have a slot.',
      ),
      JoinOutcome.raidNotFound => (
      Icons.error_outline,
      Color(0xFFC62828),
      'Raid not seeded yet — check Firestore data.',
      ),
      JoinOutcome.infrastructureError => (
      Icons.cloud_off_rounded,
      Color(0xFFC62828),
      'Network error. Please try again.',
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: tint, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: tint,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
