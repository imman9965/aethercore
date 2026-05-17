import 'package:flutter/material.dart';

import '../core/colors/colors.dart';

class SendButton extends StatelessWidget {
  const SendButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: disabled
                ? null
                : const LinearGradient(
              colors: <Color>[
                Color(0xFF1565C0),
                Color(0xFF1E88E5),
              ],
            ),
            color: disabled ? AppColors.kSurfaceContainer : null,
          ),
          child: const SizedBox(
            width: 50,
            height: 50,
            child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
