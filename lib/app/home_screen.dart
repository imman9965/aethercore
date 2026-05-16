import 'dart:async';

import 'package:flutter/material.dart';

import '../di/injector.dart';
import '../features/chat/presentation/chat_box.dart';
import '../features/raid/presentation/raid_join_button.dart';
import '../features/world_boss/presentation/boss_countdown_controller.dart';
import '../features/world_boss/presentation/world_boss_timer.dart';
import 'app.dart';

/// Single-screen composition: boss timer, raid button, live chat,
/// stacked on a soft blue-tinted background. Each child rebuilds in
/// isolation — the 100 ms timer never causes a chat repaint, and a
/// new chat message never repaints the timer.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.injector,
    required this.userId,
  });

  final Injector injector;
  final String userId;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final BossCountdownController _bossController;

  @override
  void initState() {
    super.initState();
    _bossController = widget.injector.newBossCountdownController()..start();
  }

  @override
  void dispose() {
    unawaited(_bossController.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AetherApp.kSurfaceSubtle,
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFF0B3D91),
                    Color(0xFF1E88E5),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.bolt_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('AetherCore'),
          ],
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _UserChip(userId: widget.userId),
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(12),
        child: Column(
          spacing: 8,
          children: <Widget>[
            WorldBossTimer(remaining: _bossController.remaining),
            RaidJoinButton(
              joinRaid: widget.injector.joinRaid,
              watchRaidState: widget.injector.watchRaidState,
              userId: widget.userId,
            ),
            Expanded(
              child: ChatBox(
                watchChat: widget.injector.watchChat,
                sendMessage: widget.injector.sendMessage,
                userId: widget.userId,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final String short = userId.length <= 6 ? userId : userId.substring(0, 6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AetherApp.kSurfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AetherApp.kOutline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.person_outline,
              size: 14, color: AetherApp.kPrimaryDark),
          const SizedBox(width: 6),
          Text(
            short,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AetherApp.kPrimaryDark,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
