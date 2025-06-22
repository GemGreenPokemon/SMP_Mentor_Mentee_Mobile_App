import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/messaging_constants.dart';
import '../../utils/messaging_helpers.dart';

class MessageComposer extends StatefulWidget {
  final Future<bool> Function(String message) onSendMessage;
  final Function(bool isTyping) onTypingChanged;

  const MessageComposer({
    super.key,
    required this.onSendMessage,
    required this.onTypingChanged,
  });

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _handleTextChanged(String text) {
    final wasTyping = _isTyping;
    _isTyping = text.trim().isNotEmpty;
    
    if (_isTyping && !wasTyping) {
      // Started typing
      widget.onTypingChanged(true);
    }
    
    // Reset typing timer
    _typingTimer?.cancel();
    if (_isTyping) {
      _typingTimer = Timer(MessagingConstants.typingDebounce, () {
        if (_isTyping) {
          widget.onTypingChanged(false);
          _isTyping = false;
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (!MessagingHelpers.isValidMessage(message) || _isSending) return;

    setState(() {
      _isSending = true;
    });

    // Stop typing indicator
    if (_isTyping) {
      widget.onTypingChanged(false);
      _isTyping = false;
      _typingTimer?.cancel();
    }

    final success = await widget.onSendMessage(message);
    
    if (success) {
      _messageController.clear();
    }

    setState(() {
      _isSending = false;
    });
    
    // Keep focus on input
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          constraints: BoxConstraints(
            minHeight: MessagingConstants.inputFieldHeight + (2 * MessagingConstants.smallPadding),
            maxHeight: MessagingConstants.inputFieldMaxHeight + (2 * MessagingConstants.smallPadding),
          ),
          child: Padding(
            padding: const EdgeInsets.all(MessagingConstants.smallPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _isSending ? null : _handleAttachment,
                  color: Colors.grey[600],
                  tooltip: 'Attach file',
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(MessagingConstants.inputBorderRadius),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            focusNode: _focusNode,
                            onChanged: _handleTextChanged,
                            onSubmitted: (_) => _sendMessage(),
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(
                                MessagingConstants.maxMessageLength,
                              ),
                            ],
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.emoji_emotions_outlined),
                          onPressed: _isSending ? null : _handleEmoji,
                          color: Colors.grey[600],
                          tooltip: 'Add emoji',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _messageController.text.trim().isEmpty || _isSending
                        ? Colors.grey[300]
                        : MessagingConstants.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            size: 20,
                          ),
                    onPressed: _messageController.text.trim().isEmpty || _isSending
                        ? null
                        : _sendMessage,
                    color: Colors.white,
                    tooltip: 'Send message',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleAttachment() {
    // TODO: Implement file attachment
    MessagingHelpers.showSnackBar(
      context,
      'File attachments coming soon!',
    );
  }

  void _handleEmoji() {
    // TODO: Implement emoji picker
    MessagingHelpers.showSnackBar(
      context,
      'Emoji picker coming soon!',
    );
  }
}