import 'package:flutter/material.dart';

import '../../../core/colors/colors.dart';
import '../../../widgets/live_pulse.dart';
import 'boss_countdown_controller.dart';

/// Live 10 Hz countdown card.
///
/// Binds to `controller.remaining` (a `Stream<Duration>` emitting
/// `boss_end_time - DateTime.now()` every 100 ms) via [StreamBuilder].
/// Wrapped in a `RepaintBoundary` upstream so only this card's digits
/// repaint at 10 Hz — siblings (raid, chat) keep their composited layers.
class WorldBossTimer extends StatelessWidget {
  const WorldBossTimer({super.key, required this.controller});

  final BossCountdownController controller;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF0B3D91), // midnight cobalt
              Color(0xFF1565C0), // cobalt
              Color(0xFF1E88E5), // bright blue accent
            ],
            stops: <double>[0.0, 0.6, 1.0],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF1565C0).withValues(alpha: 0.30),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: <Widget>[
            // Decorative orb — abstract suggestion of "the boss".
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      AppColors.kAccentCyan.withValues(alpha: 0.35),
                      AppColors.kAccentCyan.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const LivePulse(),
                    const SizedBox(width: 8),
                    Text(
                      'WORLD BOSS',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                StreamBuilder<Duration>(
                  stream: controller.remaining,
                  initialData: Duration.zero,
                  builder:
                      (BuildContext _, AsyncSnapshot<Duration> snap) {
                    final Duration value = snap.data ?? Duration.zero;
                    return Text(
                      _format(value),
                      style: TextStyle(
                        fontSize: 30,
                        height: 1.0,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1.5,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                        shadows: <Shadow>[
                          Shadow(
                            color: AppColors.kAccentCyan
                                .withValues(alpha: 0.55),
                            blurRadius: 22,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  'until the dragon ascends',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.75),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _format(Duration d) {
    final String mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final String ds =
        (d.inMilliseconds.remainder(1000) ~/ 100).toString();
    return '$mm:$ss.$ds';
  }
}
