import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    // Stable hue per uid so the same user always gets the same avatar tint.
    final int hueSeed = uid.hashCode.abs() % 360;
    final Color tint =
    HSLColor.fromAHSL(1.0, hueSeed.toDouble(), 0.55, 0.55).toColor();
    final String initial = uid.isEmpty ? '?' : uid[0].toUpperCase();
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            tint,
            tint.withValues(alpha: 0.7),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}
