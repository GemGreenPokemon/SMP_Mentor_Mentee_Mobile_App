import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/dashboard_constants.dart';
import '../../utils/dashboard_layout_config.dart';

/// A responsive grid widget that automatically arranges dashboard cards
/// based on screen size and configuration
class ResponsiveDashboardGrid extends StatefulWidget {
  final Map<String, Widget> cards;
  final bool enableAnimations;
  final Duration? animationDelay;

  const ResponsiveDashboardGrid({
    super.key,
    required this.cards,
    this.enableAnimations = true,
    this.animationDelay,
  });

  @override
  State<ResponsiveDashboardGrid> createState() => _ResponsiveDashboardGridState();
}

class _ResponsiveDashboardGridState extends State<ResponsiveDashboardGrid>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: widget.animationDelay ?? DashboardDurations.staggeredAnimation,
      vsync: this,
    );
    
    if (widget.enableAnimations) {
      _staggerController.forward();
    }
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final layoutConfig = DashboardLayoutConfig.getLayoutConfig(screenWidth);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: layoutConfig.padding,
          child: Column(
            children: _buildRows(layoutConfig, constraints.maxWidth),
          ),
        );
      },
    );
  }

  List<Widget> _buildRows(LayoutConfig config, double availableWidth) {
    final rows = <Widget>[];
    int animationIndex = 0;

    for (final row in config.cardArrangement) {
      if (row.isEmpty) continue;

      final visibleCards = row.where((cardId) {
        return widget.cards.containsKey(cardId) &&
            DashboardLayoutConfig.shouldShowCard(cardId, availableWidth);
      }).toList();

      if (visibleCards.isEmpty) continue;

      if (config.columns == 1) {
        // Single column layout
        for (final cardId in visibleCards) {
          rows.add(
            _buildAnimatedCard(
              cardId: cardId,
              child: widget.cards[cardId]!,
              animationIndex: animationIndex++,
              constraints: DashboardLayoutConfig.getCardConstraints(
                cardId,
                availableWidth - config.padding.horizontal,
              ),
            ),
          );
          
          if (cardId != visibleCards.last) {
            rows.add(SizedBox(height: config.mainAxisSpacing));
          }
        }
      } else {
        // Multi-column layout
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _buildRowChildren(
                visibleCards,
                config,
                availableWidth,
                animationIndex,
              ),
            ),
          ),
        );
        animationIndex += visibleCards.length;
      }

      if (row != config.cardArrangement.last) {
        rows.add(SizedBox(height: config.mainAxisSpacing));
      }
    }

    return rows;
  }

  List<Widget> _buildRowChildren(
    List<String> cardIds,
    LayoutConfig config,
    double availableWidth,
    int startingAnimationIndex,
  ) {
    final children = <Widget>[];
    int animationIndex = startingAnimationIndex;

    for (int i = 0; i < cardIds.length; i++) {
      final cardId = cardIds[i];
      final flexRatio = config.flexRatios[cardId] ?? 1;

      children.add(
        Expanded(
          flex: flexRatio,
          child: _buildAnimatedCard(
            cardId: cardId,
            child: widget.cards[cardId]!,
            animationIndex: animationIndex++,
            constraints: DashboardLayoutConfig.getCardConstraints(
              cardId,
              availableWidth,
            ),
          ),
        ),
      );

      if (i < cardIds.length - 1) {
        children.add(SizedBox(width: config.crossAxisSpacing));
      }
    }

    return children;
  }

  Widget _buildAnimatedCard({
    required String cardId,
    required Widget child,
    required int animationIndex,
    required BoxConstraints constraints,
  }) {
    final card = ConstrainedBox(
      constraints: constraints,
      child: child,
    );

    if (!widget.enableAnimations) {
      return card;
    }

    final delay = Duration(milliseconds: 150 * animationIndex);

    return card
        .animate(controller: _staggerController)
        .fadeIn(
          delay: delay,
          duration: const Duration(milliseconds: 600),
          curve: DashboardCurves.smoothCurve,
        )
        .slideY(
          begin: 0.1,
          end: 0,
          delay: delay,
          duration: const Duration(milliseconds: 600),
          curve: DashboardCurves.smoothCurve,
        )
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          delay: delay,
          duration: const Duration(milliseconds: 600),
          curve: DashboardCurves.smoothCurve,
        );
  }
}