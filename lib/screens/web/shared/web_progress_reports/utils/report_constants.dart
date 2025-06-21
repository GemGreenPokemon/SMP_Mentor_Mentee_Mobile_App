import 'package:flutter/material.dart';

class ReportConstants {
  // Colors
  static const Color primaryColor = Color(0xFF0F2D52);
  static const Color backgroundColor = Colors.white;
  static const Color cardBackgroundColor = Colors.white;
  static const Color borderColor = Color(0xFFE0E0E0);
  
  // Chart Colors
  static const Color chartPrimaryColor = Color(0xFF0F2D52);
  static const Color chartSecondaryColor = Color(0xFF1976D2);
  static const List<Color> chartColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
  ];
  
  // Spacing
  static const double largePadding = 32.0;
  static const double mediumPadding = 24.0;
  static const double standardPadding = 20.0;
  static const double smallPadding = 16.0;
  static const double tinyPadding = 8.0;
  
  // Sizing
  static const double appBarHeight = 56.0;
  static const double filterCardHeight = 56.0;
  static const double summaryCardAspectRatio = 1.5;
  static const double summaryCardAspectRatioMobile = 1.2;
  static const double chartHeight = 300.0;
  static const double activityPanelWidth = 400.0;
  static const double activityPanelWidthTablet = 300.0;
  
  // Text Sizes
  static const double titleTextSize = 20.0;
  static const double subtitleTextSize = 18.0;
  static const double bodyTextSize = 14.0;
  static const double captionTextSize = 12.0;
  static const double largeValueTextSize = 28.0;
  
  // Breakpoints
  static const double desktopBreakpoint = 1200.0;
  static const double tabletBreakpoint = 768.0;
  
  // Layout
  static const double maxContentWidth = 1400.0;
  static const double borderRadius = 8.0;
  static const double cardBorderRadius = 12.0;
  static const double chipBorderRadius = 12.0;
  
  // Grid Configuration
  static int getSummaryGridCrossAxisCount(bool isDesktop) {
    return isDesktop ? 4 : 2;
  }
  
  // Filter Configuration
  static const double filterFieldWidth = 250.0;
  static const double filterButtonWidth = 200.0;
  
  // Export Formats
  static const List<String> exportFormats = ['PDF', 'Excel', 'CSV'];
  
  // Messages
  static const String exportingPdfMessage = 'Exporting to PDF...';
  static const String exportingExcelMessage = 'Exporting to Excel...';
  static const String exportingCsvMessage = 'Exporting to CSV...';
  static const String printingMessage = 'Preparing report for printing...';
  static const String noDataMessage = 'No data available for the selected period';
  static const String loadingMessage = 'Loading report data...';
}