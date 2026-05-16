import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../domain/entities/join_outcome.dart';
import '../domain/entities/raid_state.dart';
import '../domain/usecases/join_raid.dart';
import '../domain/usecases/watch_raid_state.dart';

/// Live counter + join button.
///
/// White card with a blue progress bar showing slots filled, and a deep
/// cobalt gradient CTA. The button is disabled when the raid is full or
/// while a join is in flight — UX layer only; the database is still
/// authoritative.
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
      stream: widget.watchRaidState(),
      builder: (BuildContext context, AsyncSnapshot<RaidState> snap) {
        final RaidState state =
            snap.data ?? const RaidState(slotsFilled: 0, maxSlots: 15);
        final double progress = state.maxSlots == 0
            ? 0.0
            : state.slotsFilled / state.maxSlots;
        return Container(
          padding: const EdgeInsets.symmetric(vertical:10, horizontal: 16),
          // padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            color: AetherApp.kSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AetherApp.kOutline),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AetherApp.kPrimary.withValues(alpha: 0.06),
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
                          color: AetherApp.kOnSurfaceMuted,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Geo-locked party slot',
                        style: TextStyle(
                          fontSize: 14,
                          color: AetherApp.kOnSurface,
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
                            color: AetherApp.kPrimary,
                            height: 1.0,
                          ),
                        ),
                        const TextSpan(
                          text: '  /  ',
                          style: TextStyle(
                            fontSize: 18,
                            color: AetherApp.kOnSurfaceMuted,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextSpan(
                          text: '${state.maxSlots}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: AetherApp.kOnSurfaceMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AetherApp.kSurfaceContainer,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AetherApp.kPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _GradientJoinButton(
                onPressed:
                    _submitting || state.isFull ? null : _onPressed,
                submitting: _submitting,
                isFull: state.isFull,
              ),
              if (_lastOutcome != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _OutcomeBanner(outcome: _lastOutcome!),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GradientJoinButton extends StatelessWidget {
  const _GradientJoinButton({
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
            borderRadius: BorderRadius.circular(14),
            gradient: disabled
                ? null
                : const LinearGradient(
                    colors: <Color>[
                      Color(0xFF0B3D91),
                      Color(0xFF1565C0),
                    ],
                  ),
            color: disabled ? AetherApp.kSurfaceContainer : null,
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
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (submitting)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(
                    isFull ? Icons.lock_outline : Icons.bolt_rounded,
                    color: disabled ? AetherApp.kOnSurfaceMuted : Colors.white,
                    size: 20,
                  ),
                const SizedBox(width: 10),
                Text(
                  submitting
                      ? 'Joining...'
                      : isFull
                          ? 'Raid Full'
                          : 'Join Raid',
                  style: TextStyle(
                    color: disabled
                        ? AetherApp.kOnSurfaceMuted
                        : Colors.white,
                    fontSize: 16,
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

class _OutcomeBanner extends StatelessWidget {
  const _OutcomeBanner({required this.outcome});

  final JoinOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color tint, String text) = switch (outcome) {
      JoinOutcome.admitted => (
          Icons.check_circle_rounded,
          const Color(0xFF1B5E20),
          'Slot claimed. The dragon awaits.',
        ),
      JoinOutcome.raidFull => (
          Icons.lock_clock_outlined,
          AetherApp.kOnSurfaceMuted,
          'Raid filled before your request landed.',
        ),
      JoinOutcome.alreadyJoined => (
          Icons.info_outline_rounded,
          AetherApp.kPrimary,
          'You already have a slot.',
        ),
      JoinOutcome.raidNotFound => (
          Icons.error_outline,
          Color(0xFFC62828),
          'Raid not seeded yet — check Firestore data.',
        ),
      JoinOutcome.infrastructureError => (
          Icons.cloud_off_rounded,
          Color(0xFFC62828),
          'Network error. Please try again.',
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: tint, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: tint,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
