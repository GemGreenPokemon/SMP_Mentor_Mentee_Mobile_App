import 'package:flutter/material.dart';
import '../../utils/newsletter_constants.dart';

class NewsletterHeader extends StatelessWidget {
  final bool isMentor;
  final bool isCoordinator;
  final VoidCallback onAddNewsletter;

  const NewsletterHeader({
    super.key,
    required this.isMentor,
    required this.isCoordinator,
    required this.onAddNewsletter,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > NewsletterConstants.largeScreenBreakpoint;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isLargeScreen ? NewsletterConstants.largePadding : NewsletterConstants.mediumPadding,
          vertical: NewsletterConstants.mediumPadding,
        ),
        child: Row(
          children: [
            Icon(
              Icons.newspaper_rounded,
              size: NewsletterConstants.iconSizeLarge,
              color: NewsletterConstants.primaryBlue,
            ),
            const SizedBox(width: NewsletterConstants.smallPadding),
            const Text(
              'Newsletters',
              style: TextStyle(
                fontSize: NewsletterConstants.titleTextSize,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            const Spacer(),
            if (isMentor || isCoordinator) ...[
              ElevatedButton.icon(
                onPressed: onAddNewsletter,
                icon: const Icon(Icons.add),
                label: const Text('New Newsletter'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: NewsletterConstants.mediumPadding,
                    vertical: NewsletterConstants.smallPadding,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}