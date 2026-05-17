import 'dart:async';
import 'package:flutter/material.dart';
import '../core/colors/colors.dart';
import '../di/injector.dart';
import '../features/chat/presentation/chat_box.dart';
import '../features/world_boss/presentation/boss_countdown_controller.dart';
import '../widgets/compact_status_bar.dart';


class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.injector,
    required this.userId,
  });

  final Injector injector;
  final String userId;

  /// Convenience factory for `Navigator.push(context, ChatScreen.route(...))`.
  static Route<void> route({
    required Injector injector,
    required String userId,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => ChatScreen(injector: injector, userId: userId),
    );
  }

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
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
      backgroundColor: AppColors.kSurfaceSubtle,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Realm Chat'),
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            spacing: 8,
            children: <Widget>[
              CompactStatusBar(
                remaining: _bossController.remaining,
                joinRaid: widget.injector.joinRaid,
                watchRaidState: widget.injector.watchRaidState,
                userId: widget.userId,
              ),
              Expanded(
                child: ChatBox(
                  watchChat: widget.injector.watchChat,
                  sendMessage: widget.injector.sendMessage,
                  userId: widget.userId,
                  // No onComposerTap — real input is shown here.
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 56-px gradient pill showing the boss countdown on the left and the
/// live raid headcount + inline join action on the right.

