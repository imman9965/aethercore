import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/colors/colors.dart';
import '../../../core/errors/failures.dart';
import '../../../widgets/animated_gradient_field.dart';
import '../../../widgets/chat_header.dart';
import '../../../widgets/message_bubble.dart';
import '../../../widgets/send_button.dart';
import '../domain/entities/chat_message.dart';
import '../domain/usecases/send_message.dart';
import '../domain/usecases/watch_chat.dart';


class ChatBox extends StatefulWidget {
  const ChatBox({
    super.key,
    required this.watchChat,
    required this.sendMessage,
    required this.userId,
    this.onComposerTap,
  });

  final WatchChat watchChat;
  final SendMessage sendMessage;
  final String userId;

  /// When set, the composer becomes a non-editable "Tap to write a
  /// message" pill that invokes this callback instead of opening the
  /// keyboard. Used on the home screen to navigate to the dedicated
  /// [ChatScreen] for a proper full-screen typing experience.
  final VoidCallback? onComposerTap;

  @override
  State<ChatBox> createState() => _ChatBoxState();
}

class _ChatBoxState extends State<ChatBox> {
  static const int _maxInputChars = 280;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _error;

  // -1 = haven't received the first stream emission yet. After the
  // first batch we use this to detect when the list grew (a new
  // message arrived from anyone) and auto-scroll to the bottom.
  int _previousMessageCount = -1;

  /// Schedules a scroll to the bottom on the next frame, after the
  /// new ListView item has been laid out and `maxScrollExtent` reflects
  /// the new content height.
  void _scrollToBottom({required bool jump}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final double target = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  /// Optimistic, WhatsApp-style send: clear the input *immediately* so
  /// the user can keep typing without any "sending..." gating. The
  /// actual write fires in the background; if it fails, we restore the
  /// text so they can retry without re-typing.
  void _onSend() {
    final String text = _controller.text;
    if (text.trim().isEmpty) {
      return;
    }
    // Instant clear — the new bubble will arrive via the stream within
    // a few hundred milliseconds and slide in via the auto-scroll path.
    _controller.clear();
    if (_error != null) {
      setState(() => _error = null);
    }
    unawaited(_dispatchSend(text));
  }

  Future<void> _dispatchSend(String text) async {
    final result =
        await widget.sendMessage(uid: widget.userId, text: text);
    if (!mounted) {
      return;
    }
    result.when(
      ok: (_) {
        // Nothing to do — the stream delivers the message.
      },
      err: (AppFailure failure) {
        setState(() {
          _error = _humanize(failure);
          // Put the text back so the user can retry without re-typing.
          _controller.text = text;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: text.length),
          );
        });
      },
    );
  }

  String _humanize(AppFailure failure) {
    return switch (failure) {
      ValidationFailure(reason: final r) => r,
      InfrastructureFailure(message: final m) => m,
      AuthenticationFailure(message: final m) => m,
      NotFoundFailure(resource: final r) => 'Not found: $r',
      UnknownFailure() => 'Unexpected error.',
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.kOutline),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.kPrimary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          const ChatHeader(),
          const Divider(height: 1),
          Expanded(child: _buildMessageList()),
          if (_error != null)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFFDECEA),
              child: Text(
                _error!,
                style: const TextStyle(
                    color: Color(0xFFC62828),
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          const Divider(height: 1),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<List<ChatMessage>>(
      stream: widget.watchChat(userId: widget.userId),
      builder: (BuildContext context,
          AsyncSnapshot<List<ChatMessage>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.kPrimary),
            ),
          );
        }
        final List<ChatMessage> messages =
            snapshot.data ?? const <ChatMessage>[];

        // Auto-scroll: on first batch, jump straight to the bottom so
        // the user lands on the latest messages. On every subsequent
        // growth (new message from anyone, including me), animate to
        // the bottom so the newest bubble slides into view.
        if (messages.length != _previousMessageCount) {
          final bool firstLoad = _previousMessageCount == -1;
          final bool grew = messages.length > _previousMessageCount;
          _previousMessageCount = messages.length;
          if (firstLoad || grew) {
            _scrollToBottom(jump: firstLoad);
          }
        }

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.forum_outlined,
                  size: 36,
                  color: AppColors.kOnSurfaceMuted.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No messages yet. Be the first.',
                  style: TextStyle(
                    color: AppColors.kOnSurfaceMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          controller: _scrollController,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          itemCount: messages.length,
          itemBuilder: (BuildContext context, int index) {
            final ChatMessage m = messages[index];
            return MessageBubble(
              message: m,
              isMe: m.uid == widget.userId,
            );
          },
        );
      },
    );
  }

  Widget _buildComposer() {
    final VoidCallback? tap = widget.onComposerTap;
    if (tap != null) {
      return _buildTapPill(tap);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: AnimatedGradientField(
              controller: _controller,
              enabled: true,
              maxLength: _maxInputChars,
              onSubmitted: (_) => _onSend(),
            ),
          ),
          const SizedBox(width: 10),
          SendButton(onPressed: _onSend),
        ],
      ),
    );
  }

  Widget _buildTapPill(VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Material(
        color: AppColors.kSurfaceSubtle,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            child: Row(
              children: const <Widget>[
                Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.kOnSurfaceMuted),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tap to write a message…',
                    style: TextStyle(
                      color: AppColors.kOnSurfaceMuted,
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: 20, color: AppColors.kOnSurfaceMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}





/// Text field whose 2 px border is a continuously rotating cobalt → cyan
/// sweep gradient. The animation runs on a single AnimationController and
/// only rebuilds the outer Container's decoration each frame — the
/// TextField subtree is passed via `child` to AnimatedBuilder so it is
/// rebuilt zero times per tick.

