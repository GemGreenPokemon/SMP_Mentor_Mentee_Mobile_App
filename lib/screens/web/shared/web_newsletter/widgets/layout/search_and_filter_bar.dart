import 'package:flutter/material.dart';
import '../../models/newsletter_filter.dart';
import '../../utils/newsletter_constants.dart';

class SearchAndFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final TimePeriod selectedTimePeriod;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<TimePeriod> onTimePeriodChanged;

  const SearchAndFilterBar({
    super.key,
    required this.searchController,
    required this.selectedTimePeriod,
    required this.onSearchChanged,
    required this.onTimePeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > NewsletterConstants.largeScreenBreakpoint;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLargeScreen ? NewsletterConstants.largePadding : NewsletterConstants.mediumPadding,
        vertical: NewsletterConstants.smallPadding,
      ),
      decoration: const BoxDecoration(
        color: NewsletterConstants.headerBackground,
        border: Border(
          top: BorderSide(color: NewsletterConstants.borderColor),
        ),
      ),
      child: Row(
        children: [
          // Search Field
          Expanded(
            flex: 2,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search newsletters...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(NewsletterConstants.buttonBorderRadius),
                  borderSide: const BorderSide(color: NewsletterConstants.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(NewsletterConstants.buttonBorderRadius),
                  borderSide: const BorderSide(color: NewsletterConstants.borderColor),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: NewsletterConstants.smallPadding,
                  vertical: 14,
                ),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          const SizedBox(width: NewsletterConstants.smallPadding),
          // Time Period Filter
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<TimePeriod>(
              decoration: InputDecoration(
                labelText: 'Time Period',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(NewsletterConstants.buttonBorderRadius),
                  borderSide: const BorderSide(color: NewsletterConstants.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(NewsletterConstants.buttonBorderRadius),
                  borderSide: const BorderSide(color: NewsletterConstants.borderColor),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: NewsletterConstants.smallPadding,
                  vertical: 14,
                ),
              ),
              value: selectedTimePeriod,
              items: TimePeriod.values.map((period) {
                return DropdownMenuItem<TimePeriod>(
                  value: period,
                  child: Text(period.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onTimePeriodChanged(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}