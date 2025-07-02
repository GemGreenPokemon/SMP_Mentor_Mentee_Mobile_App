import 'package:flutter/material.dart';
import '../../utils/dashboard_constants.dart';

class QuickActionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..translate(0.0, _isPressed ? 2.0 : (_isHovered ? -2.0 : 0.0)),
          child: Container(
            constraints: const BoxConstraints(minHeight: 120),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isHovered
                    ? [
                        CoordinatorDashboardColors.primaryDark,
                        CoordinatorDashboardColors.primaryDark.withOpacity(0.8),
                      ]
                    : [
                        Colors.white,
                        Colors.grey.shade50,
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isHovered
                    ? CoordinatorDashboardColors.primaryDark
                    : Colors.grey.shade200,
                width: _isHovered ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? CoordinatorDashboardColors.primaryDark.withOpacity(0.3)
                      : Colors.black.withOpacity(0.08),
                  blurRadius: _isHovered ? 25 : 15,
                  spreadRadius: _isHovered ? 5 : 0,
                  offset: Offset(0, _isPressed ? 2 : (_isHovered ? 8 : 5)),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          widget.icon,
                          size: _isHovered ? 36 : 32,
                          color: _isHovered
                              ? Colors.white
                              : CoordinatorDashboardColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Flexible(
                        child: Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _isHovered
                                ? Colors.white
                                : CoordinatorDashboardColors.textPrimary,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}