import 'package:flutter/material.dart';
import '../utils/chat_constants.dart';
import '../utils/chat_helpers.dart';

class ChatHeader extends StatelessWidget {
  final String recipientName;
  final String recipientRole;
  final bool showBackButton;
  final VoidCallback? onClearChat;
  final VoidCallback? onBlockUser;
  
  const ChatHeader({
    super.key,
    required this.recipientName,
    required this.recipientRole,
    this.showBackButton = false,
    this.onClearChat,
    this.onBlockUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ChatConstants.defaultPadding),
      decoration: BoxDecoration(
        color: ChatConstants.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          CircleAvatar(
            backgroundColor: ChatConstants.primaryColor,
            radius: ChatConstants.avatarRadius,
            child: Text(
              recipientName.isNotEmpty ? recipientName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: ChatConstants.verticalSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipientName,
                  style: const TextStyle(
                    fontSize: ChatConstants.titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  recipientRole,
                  style: TextStyle(
                    fontSize: ChatConstants.subtitleFontSize,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {
              ChatHelpers.showSnackBar(context, ChatConstants.videoCallComingSoon);
            },
            tooltip: ChatConstants.videoCallTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.phone_outlined),
            onPressed: () {
              ChatHelpers.showSnackBar(context, ChatConstants.voiceCallComingSoon);
            },
            tooltip: ChatConstants.voiceCallTooltip,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  onClearChat?.call();
                  break;
                case 'block':
                  onBlockUser?.call();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text(ChatConstants.clearChatMenuItem),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Text(ChatConstants.blockUserMenuItem),
              ),
            ],
          ),
        ],
      ),
    );
  }
}