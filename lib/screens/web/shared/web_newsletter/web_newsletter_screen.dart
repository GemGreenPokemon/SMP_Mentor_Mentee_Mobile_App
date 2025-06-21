import 'package:flutter/material.dart';
import 'models/newsletter.dart';
import 'models/newsletter_filter.dart';
import 'utils/newsletter_constants.dart';
import 'utils/newsletter_helpers.dart';
import 'widgets/layout/newsletter_header.dart';
import 'widgets/layout/search_and_filter_bar.dart';
import 'widgets/cards/newsletter_card.dart';
import 'widgets/shared/empty_state.dart';
import 'widgets/dialogs/newsletter_detail_dialog.dart';
import 'widgets/dialogs/create_newsletter_dialog.dart';

class WebNewsletterScreen extends StatefulWidget {
  final bool isMentor;
  final bool isCoordinator;
  
  const WebNewsletterScreen({
    super.key, 
    this.isMentor = false,
    this.isCoordinator = false,
  });

  @override
  State<WebNewsletterScreen> createState() => _WebNewsletterScreenState();
}

class _WebNewsletterScreenState extends State<WebNewsletterScreen> {
  final TextEditingController _searchController = TextEditingController();
  NewsletterFilter _filter = const NewsletterFilter();
  List<Newsletter> _newsletters = [];

  @override
  void initState() {
    super.initState();
    _loadNewsletters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadNewsletters() {
    // In production, this would load from Firebase
    setState(() {
      _newsletters = NewsletterHelpers.generateMockNewsletters();
    });
  }

  List<Newsletter> get _filteredNewsletters {
    return _newsletters.where((newsletter) {
      return _filter.matchesNewsletter(
        newsletter.title,
        newsletter.description,
        newsletter.date,
      );
    }).toList();
  }

  void _updateFilter({String? searchQuery, TimePeriod? timePeriod}) {
    setState(() {
      _filter = _filter.copyWith(
        searchQuery: searchQuery,
        timePeriod: timePeriod,
      );
    });
  }

  void _showNewsletterDetail(Newsletter newsletter) {
    showDialog(
      context: context,
      builder: (context) => NewsletterDetailDialog(newsletter: newsletter),
    );
  }

  void _showCreateNewsletterDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateNewsletterDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > NewsletterConstants.largeScreenBreakpoint;
    final crossAxisCount = NewsletterConstants.getGridCrossAxisCount(screenWidth);
    
    return Scaffold(
      backgroundColor: NewsletterConstants.backgroundColor,
      body: Column(
        children: [
          // Header Section
          Column(
            children: [
              NewsletterHeader(
                isMentor: widget.isMentor,
                isCoordinator: widget.isCoordinator,
                onAddNewsletter: _showCreateNewsletterDialog,
              ),
              SearchAndFilterBar(
                searchController: _searchController,
                selectedTimePeriod: _filter.timePeriod,
                onSearchChanged: (value) => _updateFilter(searchQuery: value),
                onTimePeriodChanged: (value) => _updateFilter(timePeriod: value),
              ),
            ],
          ),
          
          // Newsletter Grid
          Expanded(
            child: _filteredNewsletters.isEmpty
                ? const EmptyState()
                : Padding(
                    padding: EdgeInsets.all(
                      isLargeScreen ? NewsletterConstants.largePadding : NewsletterConstants.mediumPadding,
                    ),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: NewsletterConstants.mediumPadding,
                        mainAxisSpacing: NewsletterConstants.mediumPadding,
                        childAspectRatio: NewsletterConstants.cardAspectRatio,
                      ),
                      itemCount: _filteredNewsletters.length,
                      itemBuilder: (context, index) {
                        final newsletter = _filteredNewsletters[index];
                        return NewsletterCard(
                          newsletter: newsletter,
                          onTap: () => _showNewsletterDetail(newsletter),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}