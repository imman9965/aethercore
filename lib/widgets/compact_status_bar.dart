import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/colors/colors.dart';
import '../features/raid/domain/entities/raid_state.dart';
import '../features/raid/domain/usecases/join_raid.dart';
import '../features/raid/domain/usecases/watch_raid_state.dart';

class CompactStatusBar extends StatefulWidget {
  const CompactStatusBar({super.key,
    required this.remaining,
    required this.joinRaid,
    required this.watchRaidState,
    required this.userId,
  });

  final ValueListenable<Duration> remaining;
  final JoinRaid joinRaid;
  final WatchRaidState watchRaidState;
  final String userId;

  @override
  State<CompactStatusBar> createState() => _CompactStatusBarState();
}

class _CompactStatusBarState extends State<CompactStatusBar> {
  bool _joining = false;

  Future<void> _onJoin() async {
    setState(() => _joining = true);
    await widget.joinRaid(userId: widget.userId);
    if (mounted) {
      setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF0B3D91),
            Color(0xFF1565C0),
            Color(0xFF1E88E5),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.kAccentCyan,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppColors.kAccentCyan
                              .withValues(alpha: 0.7),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ValueListenableBuilder<Duration>(
                      valueListenable: widget.remaining,
                      builder: (BuildContext _, Duration value, _) {
                        return Text(
                          _format(value),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            fontFeatures: <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: StreamBuilder<RaidState>(
              stream: widget.watchRaidState(),
              builder:
                  (BuildContext ctx, AsyncSnapshot<RaidState> snap) {
                final RaidState state = snap.data ??
                    const RaidState(slotsFilled: 0, maxSlots: 15);
                final bool isFull = state.isFull;
                final bool disabled = _joining || isFull;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          'RAID',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 9,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${state.slotsFilled} / ${state.maxSlots}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            fontFeatures: <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: disabled ? null : _onJoin,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: disabled
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white
                                    .withValues(alpha: 0.35)),
                          ),
                          child: _joining
                              ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                              AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          )
                              : Text(
                            isFull ? 'Full' : 'Join',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
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