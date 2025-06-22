import 'package:flutter/material.dart';
import '../../models/typing_indicator.dart';
import '../../utils/messaging_constants.dart';

class TypingIndicatorWidget extends StatefulWidget {
  final TypingIndicator typingIndicator;

  const TypingIndicatorWidget({
    super.key,
    required this.typingIndicator,
  });

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _dot1Animation;
  late Animation<double> _dot2Animation;
  late Animation<double> _dot3Animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _dot1Animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -8.0),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -8.0, end: 0.0),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _dot2Animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -8.0),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -8.0, end: 0.0),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.0),
        weight: 30,
      ),
    ]).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _dot3Animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.0),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -8.0),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -8.0, end: 0.0),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.0),
        weight: 10,
      ),
    ]).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MessagingConstants.defaultPadding,
          vertical: MessagingConstants.smallPadding,
        ),
        color: MessagingConstants.messagesBackgroundColor,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(MessagingConstants.messageBorderRadius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.typingIndicator.displayText.replaceAll('...', ''),
                    style: TextStyle(
                      fontSize: 13,
                      color: MessagingConstants.typingIndicatorColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 2),
                  _buildDots(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDots() {
    return SizedBox(
      width: 24,
      height: 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _dot1Animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(-8, _dot1Animation.value),
                child: _buildDot(),
              );
            },
          ),
          AnimatedBuilder(
            animation: _dot2Animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _dot2Animation.value),
                child: _buildDot(),
              );
            },
          ),
          AnimatedBuilder(
            animation: _dot3Animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(8, _dot3Animation.value),
                child: _buildDot(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: MessagingConstants.typingIndicatorColor,
        shape: BoxShape.circle,
      ),
    );
  }
}