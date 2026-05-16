import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/chat_message.dart';
import '../domain/usecases/send_message.dart';
import '../domain/usecases/watch_chat.dart';

/// Real-time engagement chat with a modern bubble layout.
///
/// My messages: cobalt gradient bubble, white text, right-aligned, with
/// a tail. Others: white bubble with a thin outline, dark text, left.
/// Input bar sits flush at the bottom with a rounded field and a
/// gradient send button.
class ChatBox extends StatefulWidget {
  const ChatBox({
    super.key,
    required this.watchChat,
    required this.sendMessage,
    required this.userId,
  });

  final WatchChat watchChat;
  final SendMessage sendMessage;
  final String userId;

  @override
  State<ChatBox> createState() => _ChatBoxState();
}

class _ChatBoxState extends State<ChatBox> {
  static const int _maxInputChars = 280;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sending = false;
  String? _error;

  Future<void> _onSend() async {
    final String text = _controller.text;
    if (text.trim().isEmpty) {
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final result =
        await widget.sendMessage(uid: widget.userId, text: text);
    if (!mounted) {
      return;
    }
    result.when(
      ok: (_) {
        _controller.clear();
      },
      err: (AppFailure failure) {
        _error = _humanize(failure);
      },
    );
    setState(() => _sending = false);
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
        color: AetherApp.kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AetherApp.kOutline),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AetherApp.kPrimary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          const _ChatHeader(),
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
                  AlwaysStoppedAnimation<Color>(AetherApp.kPrimary),
            ),
          );
        }
        final List<ChatMessage> messages =
            snapshot.data ?? const <ChatMessage>[];
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.forum_outlined,
                  size: 36,
                  color: AetherApp.kOnSurfaceMuted.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No messages yet. Be the first.',
                  style: TextStyle(
                    color: AetherApp.kOnSurfaceMuted,
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
            return _MessageBubble(
              message: m,
              isMe: m.uid == widget.userId,
            );
          },
        );
      },
    );
  }

  Widget _buildComposer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _AnimatedGradientField(
              controller: _controller,
              enabled: !_sending,
              maxLength: _maxInputChars,
              onSubmitted: (_) => _onSend(),
            ),
          ),
          const SizedBox(width: 10),
          _SendButton(onPressed: _sending ? null : _onSend),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AetherApp.kAccentCyan,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AetherApp.kAccentCyan.withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Realm Chat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AetherApp.kOnSurface,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AetherApp.kSurfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
                color: AetherApp.kPrimaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onPressed});

  final VoidCallback? onPressed;

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
                      Color(0xFF1565C0),
                      Color(0xFF1E88E5),
                    ],
                  ),
            color: disabled ? AetherApp.kSurfaceContainer : null,
          ),
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});

  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          if (!isMe) _Avatar(uid: message.uid),
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        colors: <Color>[
                          Color(0xFF1565C0),
                          Color(0xFF1E88E5),
                        ],
                      )
                    : null,
                color: isMe ? null : AetherApp.kSurfaceSubtle,
                border: isMe
                    ? null
                    : Border.all(color: AetherApp.kOutline),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: isMe
                    ? <BoxShadow>[
                        BoxShadow(
                          color: const Color(0xFF1565C0)
                              .withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    isMe ? 'You' : _shortUid(message.uid),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.85)
                          : AetherApp.kOnSurfaceMuted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.text,
                    style: TextStyle(
                      color:
                          isMe ? Colors.white : AetherApp.kOnSurface,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _shortUid(String uid) {
    return uid.length <= 6 ? uid : uid.substring(0, 6);
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    // Stable hue per uid so the same user always gets the same avatar tint.
    final int hueSeed = uid.hashCode.abs() % 360;
    final Color tint =
        HSLColor.fromAHSL(1.0, hueSeed.toDouble(), 0.55, 0.55).toColor();
    final String initial = uid.isEmpty ? '?' : uid[0].toUpperCase();
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            tint,
            tint.withValues(alpha: 0.7),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
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
class _AnimatedGradientField extends StatefulWidget {
  const _AnimatedGradientField({
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
  State<_AnimatedGradientField> createState() =>
      _AnimatedGradientFieldState();
}

class _AnimatedGradientFieldState extends State<_AnimatedGradientField>
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
        decoration: BoxDecoration(
          color: AetherApp.kSurfaceSubtle,
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
            //     EdgeInsets.only(bottom: ),
          ),
          textInputAction: TextInputAction.send,
          onSubmitted: widget.onSubmitted,
        ),
      ),
    );
  }
}
