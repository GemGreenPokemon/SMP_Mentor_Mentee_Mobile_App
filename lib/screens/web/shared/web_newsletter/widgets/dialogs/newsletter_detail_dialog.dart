import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/newsletter.dart';
import '../../utils/newsletter_constants.dart';
import '../../utils/newsletter_helpers.dart';

class NewsletterDetailDialog extends StatelessWidget {
  final Newsletter newsletter;

  const NewsletterDetailDialog({
    super.key,
    required this.newsletter,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NewsletterConstants.dialogBorderRadius),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: NewsletterConstants.maxDialogWidth,
          maxHeight: MediaQuery.of(context).size.height * NewsletterConstants.dialogHeightFactor,
        ),
        child: Column(
          children: [
            _buildHeader(context),
            _buildContent(),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(NewsletterConstants.mediumPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [NewsletterConstants.primaryBlue, NewsletterConstants.darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(NewsletterConstants.dialogBorderRadius),
          topRight: Radius.circular(NewsletterConstants.dialogBorderRadius),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.newspaper_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: NewsletterConstants.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  newsletter.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: NewsletterConstants.subtitleTextSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  NewsletterHelpers.formatDate(newsletter.date),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: NewsletterConstants.captionTextSize,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              newsletter.description,
              style: const TextStyle(
                fontSize: NewsletterConstants.bodyTextSize,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            _buildHighlightsSection(),
            const SizedBox(height: 32),
            _buildAdditionalInfo(),
            const SizedBox(height: 32),
            _buildContactInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightsSection() {
    if (newsletter.highlights.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(NewsletterConstants.mediumPadding),
      decoration: BoxDecoration(
        color: NewsletterConstants.highlightBackground,
        borderRadius: BorderRadius.circular(NewsletterConstants.cardBorderRadius),
        border: Border.all(color: NewsletterConstants.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star_rounded,
                color: Colors.amber[700],
                size: NewsletterConstants.iconSizeMedium,
              ),
              const SizedBox(width: NewsletterConstants.tinyPadding),
              const Text(
                'Key Highlights',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: NewsletterConstants.smallPadding),
          ...newsletter.highlights.map((highlight) => Padding(
                padding: const EdgeInsets.only(bottom: NewsletterConstants.smallPadding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        highlight,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          NewsletterConstants.additionalInfoTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: NewsletterConstants.smallPadding),
        Text(
          NewsletterConstants.additionalInfoContent,
          style: const TextStyle(
            fontSize: NewsletterConstants.bodyTextSize,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NewsletterConstants.contactInfoBackground,
        borderRadius: BorderRadius.circular(NewsletterConstants.buttonBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: NewsletterConstants.primaryBlue,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.email, size: 18, color: NewsletterConstants.primaryBlue),
              const SizedBox(width: NewsletterConstants.tinyPadding),
              Text(NewsletterConstants.contactEmail),
            ],
          ),
          const SizedBox(height: NewsletterConstants.tinyPadding),
          Row(
            children: [
              Icon(Icons.phone, size: 18, color: NewsletterConstants.primaryBlue),
              const SizedBox(width: NewsletterConstants.tinyPadding),
              Text(NewsletterConstants.contactPhone),
            ],
          ),
          const SizedBox(height: NewsletterConstants.tinyPadding),
          Row(
            children: [
              Icon(Icons.location_on, size: 18, color: NewsletterConstants.primaryBlue),
              const SizedBox(width: NewsletterConstants.tinyPadding),
              Text(NewsletterConstants.contactLocation),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(NewsletterConstants.mediumPadding),
      decoration: BoxDecoration(
        color: NewsletterConstants.headerBackground,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(NewsletterConstants.dialogBorderRadius),
          bottomRight: Radius.circular(NewsletterConstants.dialogBorderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(NewsletterConstants.downloadingMessage)),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Download PDF'),
          ),
          const SizedBox(width: NewsletterConstants.smallPadding),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Share.share(NewsletterHelpers.generateShareText(newsletter));
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: NewsletterConstants.mediumPadding,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}