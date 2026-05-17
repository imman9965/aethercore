import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/colors/colors.dart';

class AnimatedGradientField extends StatefulWidget {
  const AnimatedGradientField({super.key,
    required this.controller,
    required this.enabled,
    required this.maxLength,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final int maxLength;
  final ValueChanged<String> onSubmitted;

  @override
  State<AnimatedGradientField> createState() =>
      _AnimatedGradientFieldState();
}

class _AnimatedGradientFieldState extends State<AnimatedGradientField>
    with SingleTickerProviderStateMixin {
  static const double _borderWidth = 2;
  static const Duration _spinPeriod = Duration(seconds: 3);

  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: _spinPeriod,
    )..repeat();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget? child) {
        final double angle = _animation.value * 2 * math.pi;
        return Container(

          // height: MediaQuery.of(context).size.height/,

          // padding: EdgeInsets.only(bottom:2 ,top: 2),
          padding: const EdgeInsets.all(_borderWidth),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: SweepGradient(
              startAngle: 0,
              endAngle: 2 * math.pi,
              transform: GradientRotation(angle),
              colors: const <Color>[
                Color(0xFF0B3D91), // midnight cobalt
                Color(0xFF1E88E5), // bright blue
                Color(0xFF00E5FF), // cyan accent
                Color(0xFF1E88E5),
                Color(0xFF0B3D91),
              ],
            ),
          ),
          child: child,
        );
      },
      // Cached subtree — built once, reused every animation frame.
      child: Container(
        // margin: EdgeInsets.only(bottom:30 ,top: 30),
        // padding:EdgeInsets.only(bottom:0 ,top: 0) ,
        decoration: BoxDecoration(
          color: AppColors.kSurfaceSubtle,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          maxLength: widget.maxLength,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Say something',
            counterText: '',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            fillColor: Colors.transparent,
            filled: true,
            // contentPadding:
            //     EdgeInsets.symmetric(ve),
          ),
          textInputAction: TextInputAction.send,
          onSubmitted: widget.onSubmitted,
        ),
      ),
    );
  }
}