import 'package:flutter/material.dart';
import '../core/colors/colors.dart';

class GradientJoinButton extends StatelessWidget {
  const GradientJoinButton({super.key,
    required this.onPressed,
    required this.submitting,
    required this.isFull,
  });

  final VoidCallback? onPressed;
  final bool submitting;
  final bool isFull;

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
            borderRadius: BorderRadius.circular(8),
            gradient: disabled
                ? null
                : const LinearGradient(
              colors: <Color>[
                Color(0xFF0B3D91),
                Color(0xFF1565C0),
              ],
            ),
            color: disabled ? AppColors.kSurfaceContainer : null,
            boxShadow: disabled
                ? null
                : <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF1565C0)
                    .withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (submitting)
                  const SizedBox(
                    width: 18,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(
                    isFull ? Icons.lock_outline : Icons.bolt_rounded,
                    color: disabled ? AppColors.kOnSurfaceMuted : Colors.white,
                    size: 15,
                  ),
                const SizedBox(width: 8),
                Text(
                  submitting
                      ? 'Joining...'
                      : isFull
                      ? 'Raid Full'
                      : 'Join Raid',
                  style: TextStyle(
                    color: disabled
                        ? AppColors.kOnSurfaceMuted
                        : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
