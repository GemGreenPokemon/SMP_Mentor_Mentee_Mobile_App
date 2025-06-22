import 'package:flutter/material.dart';
import 'dashboard_constants.dart';

/// Configuration for dashboard card layouts
class DashboardLayoutConfig {
  /// Card identifiers for easy management
  static const String menteesCard = 'mentees_overview';
  static const String meetingsCard = 'meetings_carousel';
  static const String announcementsCard = 'announcements_preview';
  static const String activityCard = 'activity_timeline';

  /// Card metadata including priority and constraints
  static const Map<String, CardConfig> cardConfigs = {
    menteesCard: CardConfig(
      priority: 1,
      minWidth: 350,
      maxWidth: 600,
      minHeight: 300,
      aspectRatio: null,
      canCollapse: false,
    ),
    meetingsCard: CardConfig(
      priority: 1,
      minWidth: 400,
      maxWidth: 800,
      minHeight: 250,
      aspectRatio: null,
      canCollapse: false,
    ),
    announcementsCard: CardConfig(
      priority: 2,
      minWidth: 350,
      maxWidth: 700,
      minHeight: 350,
      aspectRatio: null,
      canCollapse: true,
    ),
    activityCard: CardConfig(
      priority: 3,
      minWidth: 300,
      maxWidth: 500,
      minHeight: 350,
      aspectRatio: null,
      canCollapse: true,
    ),
  };

  /// Grid configurations for different screen sizes
  static LayoutConfig getLayoutConfig(double screenWidth) {
    if (screenWidth >= 1400) {
      // Large desktop - 2x2 grid with optimal spacing
      return LayoutConfig(
        columns: 2,
        crossAxisSpacing: DashboardSizes.spacingLarge,
        mainAxisSpacing: DashboardSizes.spacingLarge,
        padding: const EdgeInsets.all(DashboardSizes.spacingXLarge),
        cardArrangement: [
          [menteesCard, meetingsCard],
          [announcementsCard, activityCard],
        ],
        flexRatios: {
          menteesCard: 2,
          meetingsCard: 3,
          announcementsCard: 3,
          activityCard: 2,
        },
      );
    } else if (screenWidth >= 1100) {
      // Desktop - 2x2 grid with medium spacing
      return LayoutConfig(
        columns: 2,
        crossAxisSpacing: DashboardSizes.spacingMedium,
        mainAxisSpacing: DashboardSizes.spacingMedium,
        padding: const EdgeInsets.all(DashboardSizes.spacingLarge),
        cardArrangement: [
          [menteesCard, meetingsCard],
          [announcementsCard, activityCard],
        ],
        flexRatios: {
          menteesCard: 1,
          meetingsCard: 1,
          announcementsCard: 1,
          activityCard: 1,
        },
      );
    } else if (screenWidth >= 768) {
      // Tablet - 2x2 grid with adjusted ratios
      return LayoutConfig(
        columns: 2,
        crossAxisSpacing: DashboardSizes.spacingSmall,
        mainAxisSpacing: DashboardSizes.spacingSmall,
        padding: const EdgeInsets.all(DashboardSizes.spacingMedium),
        cardArrangement: [
          [menteesCard, meetingsCard],
          [announcementsCard, activityCard],
        ],
        flexRatios: {
          menteesCard: 1,
          meetingsCard: 1,
          announcementsCard: 1,
          activityCard: 1,
        },
      );
    } else {
      // Mobile - Single column
      return LayoutConfig(
        columns: 1,
        crossAxisSpacing: 0,
        mainAxisSpacing: DashboardSizes.spacingMedium,
        padding: const EdgeInsets.all(DashboardSizes.spacingMedium),
        cardArrangement: [
          [menteesCard],
          [meetingsCard],
          [announcementsCard],
          [activityCard],
        ],
        flexRatios: {
          menteesCard: 1,
          meetingsCard: 1,
          announcementsCard: 1,
          activityCard: 1,
        },
      );
    }
  }

  /// Get responsive card constraints
  static BoxConstraints getCardConstraints(String cardId, double availableWidth) {
    final config = cardConfigs[cardId];
    if (config == null) {
      return const BoxConstraints();
    }

    return BoxConstraints(
      minWidth: config.minWidth,
      maxWidth: config.maxWidth ?? double.infinity,
      minHeight: config.minHeight,
      maxHeight: config.maxHeight ?? double.infinity,
    );
  }

  /// Check if card should be visible based on priority and screen size
  static bool shouldShowCard(String cardId, double screenWidth) {
    final config = cardConfigs[cardId];
    if (config == null) return true;

    // On very small screens, only show priority 1 cards
    if (screenWidth < 400 && config.priority > 1) {
      return false;
    }

    return true;
  }
}

/// Configuration for a single card
class CardConfig {
  final int priority;
  final double minWidth;
  final double? maxWidth;
  final double minHeight;
  final double? maxHeight;
  final double? aspectRatio;
  final bool canCollapse;

  const CardConfig({
    required this.priority,
    required this.minWidth,
    this.maxWidth,
    required this.minHeight,
    this.maxHeight,
    this.aspectRatio,
    required this.canCollapse,
  });
}

/// Layout configuration for a specific screen size
class LayoutConfig {
  final int columns;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsets padding;
  final List<List<String>> cardArrangement;
  final Map<String, int> flexRatios;

  const LayoutConfig({
    required this.columns,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
    required this.padding,
    required this.cardArrangement,
    required this.flexRatios,
  });
}