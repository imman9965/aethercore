import 'package:flutter/cupertino.dart';

import '../core/colors/colors.dart';

class LivePulse extends StatelessWidget {
  const LivePulse({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.kAccentCyan,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.kAccentCyan.withValues(alpha: 0.75),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}