import 'package:flutter/material.dart';

import '../core/colors/colors.dart';
import '../features/chat/domain/entities/chat_message.dart';
import 'avatar.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, required this.isMe});

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
          if (!isMe) Avatar(uid: message.uid),
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
                color: isMe ? null : AppColors.kSurfaceSubtle,
                border: isMe
                    ? null
                    : Border.all(color: AppColors.kOutline),
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
                          : AppColors.kOnSurfaceMuted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.text,
                    style: TextStyle(
                      color:
                      isMe ? Colors.white : AppColors.kOnSurface,
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
