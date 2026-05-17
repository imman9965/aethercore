import 'package:flutter/material.dart';
import '../core/colors/colors.dart';

class UserChip extends StatelessWidget {
  const UserChip({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final String short = userId.length <= 6 ? userId : userId.substring(0, 6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.kSurfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.kOutline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.person_outline,
              size: 14, color: AppColors.kPrimaryDark),
          const SizedBox(width: 6),
          Text(
            short,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.kPrimaryDark,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
