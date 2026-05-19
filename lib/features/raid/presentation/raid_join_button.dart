import 'package:flutter/material.dart';

import '../../../core/colors/colors.dart';
import '../../../widgets/gradient_join_button.dart';
import '../../../widgets/outcommer.dart';
import '../domain/entities/join_outcome.dart';
import '../domain/entities/raid_state.dart';
import '../domain/usecases/join_raid.dart';
import '../domain/usecases/watch_raid_state.dart';


class RaidJoinButton extends StatefulWidget {
  const RaidJoinButton({
    super.key,
    required this.joinRaid,
    required this.watchRaidState,
    required this.userId,
  });

  final JoinRaid joinRaid;
  final WatchRaidState watchRaidState;
  final String userId;

  @override
  State<RaidJoinButton> createState() => _RaidJoinButtonState();
}

class _RaidJoinButtonState extends State<RaidJoinButton> {
  bool _submitting = false;
  JoinOutcome? _lastOutcome;

  // Cache the stream once: `widget.watchRaidState()` returns a fresh
  // `_raidRef.snapshots()` listener on every call. Reading it directly
  // inside `build()` caused StreamBuilder to tear down and re-subscribe
  // every time `setState` fired (each tap toggles `_submitting` twice),
  // billing a fresh Firestore read each round-trip. Capturing once
  // keeps the subscription stable for the lifetime of the State.
  late final Stream<RaidState> _raidStateStream = widget.watchRaidState();

  Future<void> _onPressed() async {
    setState(() {
      _submitting = true;
      _lastOutcome = null;
    });
    final JoinOutcome outcome =
        await widget.joinRaid(userId: widget.userId);
    if (!mounted) {
      return;
    }
    setState(() {
      _submitting = false;
      _lastOutcome = outcome;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RaidState>(
      stream: _raidStateStream,
      builder: (BuildContext context, AsyncSnapshot<RaidState> snap) {
        final RaidState state =
            snap.data ?? const RaidState(slotsFilled: 0, maxSlots: 15);
        final double progress = state.maxSlots == 0
            ? 0.0
            : state.slotsFilled / state.maxSlots;
        return Container(
          padding: const EdgeInsets.symmetric(vertical:8, horizontal: 16),
          // padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.kSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.kOutline),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.kPrimary.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'DRAGON RAID',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.kOnSurfaceMuted,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Geo-locked party slot',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.kOnSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontFeatures: <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                      children: <InlineSpan>[
                        TextSpan(
                          text: '${state.slotsFilled}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.kPrimary,
                            height: 1.0,
                          ),
                        ),
                        const TextSpan(
                          text: '  /  ',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.kOnSurfaceMuted,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: '${state.maxSlots}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.kOnSurfaceMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.kSurfaceContainer,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.kPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GradientJoinButton(
                onPressed:
                    _submitting || state.isFull ? null : _onPressed,
                submitting: _submitting,
                isFull: state.isFull,
              ),
              if (_lastOutcome != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: OutcomeBanner(outcome: _lastOutcome!),
                ),
            ],
          ),
        );
      },
    );
  }
}


