import 'package:flutter/material.dart';

class DashboardLayoutConfig {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  static const double largeDesktopBreakpoint = 1800;

  // Grid configurations
  static int getGridColumns(double width) {
    if (width < mobileBreakpoint) return 1;
    if (width < tabletBreakpoint) return 2;
    if (width < desktopBreakpoint) return 3;
    if (width < largeDesktopBreakpoint) return 4;
    return 5;
  }

  static double getGridSpacing(double width) {
    if (width < mobileBreakpoint) return 16.0;
    if (width < tabletBreakpoint) return 20.0;
    return 24.0;
  }

  // Content widths
  static double getContentMaxWidth(double screenWidth) {
    if (screenWidth < mobileBreakpoint) return screenWidth - 32;
    if (screenWidth < tabletBreakpoint) return screenWidth - 48;
    if (screenWidth < desktopBreakpoint) return screenWidth - 64;
    return 1400;
  }

  // Card configurations
  static double getCardAspectRatio(CardType type, double screenWidth) {
    switch (type) {
      case CardType.mentorInfo:
        return screenWidth < tabletBreakpoint ? 1.2 : 1.5;
      case CardType.progress:
        return screenWidth < tabletBreakpoint ? 1.0 : 1.8;
      case CardType.announcement:
        return screenWidth < tabletBreakpoint ? 0.8 : 1.2;
      case CardType.meeting:
        return screenWidth < tabletBreakpoint ? 1.0 : 0.9;
      case CardType.quickAccess:
        return 1.0;
      default:
        return 1.0;
    }
  }

  // Flex configurations for row layouts
  static int getMentorCardFlex(double screenWidth) {
    if (screenWidth < tabletBreakpoint) return 1;
    return 2;
  }

  static int getProgressCardFlex(double screenWidth) {
    if (screenWidth < tabletBreakpoint) return 1;
    return 3;
  }

  static int getAnnouncementCardFlex(double screenWidth) {
    if (screenWidth < tabletBreakpoint) return 1;
    return 3;
  }

  static int getMeetingCardFlex(double screenWidth) {
    if (screenWidth < tabletBreakpoint) return 1;
    return 2;
  }

  // Quick access grid
  static int getQuickAccessColumns(double width) {
    if (width < mobileBreakpoint) return 2;
    if (width < tabletBreakpoint) return 3;
    if (width < desktopBreakpoint) return 4;
    return 5;
  }

  static double getQuickAccessItemHeight(double width) {
    if (width < mobileBreakpoint) return 100;
    if (width < tabletBreakpoint) return 120;
    return 140;
  }

  // Sidebar behavior
  static bool shouldShowSidebar(double width) {
    return width >= tabletBreakpoint;
  }

  static bool shouldCollapseSidebar(double width) {
    return width < desktopBreakpoint && width >= tabletBreakpoint;
  }

  // Padding configurations
  static EdgeInsets getScreenPadding(double width) {
    if (width < mobileBreakpoint) {
      return const EdgeInsets.all(16.0);
    }
    if (width < tabletBreakpoint) {
      return const EdgeInsets.all(20.0);
    }
    return const EdgeInsets.all(24.0);
  }

  static EdgeInsets getCardPadding(double width) {
    if (width < mobileBreakpoint) {
      return const EdgeInsets.all(16.0);
    }
    if (width < tabletBreakpoint) {
      return const EdgeInsets.all(18.0);
    }
    return const EdgeInsets.all(20.0);
  }

  // Font size scaling
  static double getScaledFontSize(double baseSize, double width) {
    if (width < mobileBreakpoint) return baseSize * 0.9;
    if (width < tabletBreakpoint) return baseSize * 0.95;
    return baseSize;
  }

  // Helper methods
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeDesktopBreakpoint;
  }
}

enum CardType {
  mentorInfo,
  progress,
  announcement,
  meeting,
  quickAccess,
  activity,
}