import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/colors/colors.dart';
import '../../../widgets/live_pulse.dart';

class WorldBossTimer extends StatelessWidget {
  const WorldBossTimer({super.key, required this.remaining});

  final ValueListenable<Duration> remaining;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        // margin: const EdgeInsets.all(12),
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
                    LivePulse(),
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
                ValueListenableBuilder<Duration>(
                  valueListenable: remaining,
                  builder: (BuildContext _, Duration value, _) {
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
                            color:
                                AppColors.kAccentCyan.withValues(alpha: 0.55),
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


