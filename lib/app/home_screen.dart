import 'dart:async';

import 'package:flutter/material.dart';

import '../core/colors/colors.dart';
import '../di/injector.dart';
import '../features/chat/presentation/chat_box.dart';
import '../features/raid/presentation/raid_join_button.dart';
import '../features/world_boss/presentation/boss_countdown_controller.dart';
import '../features/world_boss/presentation/world_boss_timer.dart';
import '../widgets/user_chip.dart';
import 'chat_screen.dart';

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

  // Cached children — constructed once, reused across every rebuild.
  late final PreferredSizeWidget _appBar;
  late final Widget _worldBossTimer;
  late final Widget _raidJoinButton;
  late final Widget _chatBox;

  @override
  void initState() {
    super.initState();
    _bossController = widget.injector.newBossCountdownController()..start();

    _appBar = AppBar(
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
          child: UserChip(userId: widget.userId),
        ),
      ],
    );

    _worldBossTimer = RepaintBoundary(
      child: WorldBossTimer(remaining: _bossController.remaining),
    );

    _raidJoinButton = RepaintBoundary(
      child: RaidJoinButton(
        joinRaid: widget.injector.joinRaid,
        watchRaidState: widget.injector.watchRaidState,
        userId: widget.userId,
      ),
    );

    _chatBox = RepaintBoundary(
      child: ChatBox(
        watchChat: widget.injector.watchChat,
        sendMessage: widget.injector.sendMessage,
        userId: widget.userId,
        onComposerTap: _openChatScreen,
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_bossController.dispose());
    super.dispose();
  }

  void _openChatScreen() {
    Navigator.of(context).push(
      ChatScreen.route(
        injector: widget.injector,
        userId: widget.userId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kSurfaceSubtle,
      resizeToAvoidBottomInset: true,
      appBar: _appBar,
      body: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            spacing: 8,
            children: <Widget>[
              _worldBossTimer,
              _raidJoinButton,
              Expanded(child: _chatBox),
            ],
          ),
        ),
      ),
    );
  }
}






