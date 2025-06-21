import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/newsletter.dart';
import '../../utils/newsletter_constants.dart';
import '../../utils/newsletter_helpers.dart';

class NewsletterCard extends StatelessWidget {
  final Newsletter newsletter;
  final VoidCallback onTap;

  const NewsletterCard({
    super.key,
    required this.newsletter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NewsletterConstants.cardBorderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NewsletterConstants.cardBorderRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildContent(),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [NewsletterConstants.primaryBlue, NewsletterConstants.darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(NewsletterConstants.cardBorderRadius),
          topRight: Radius.circular(NewsletterConstants.cardBorderRadius),
        ),
      ),
      padding: const EdgeInsets.all(NewsletterConstants.smallPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.newspaper_rounded,
                color: Colors.white,
                size: NewsletterConstants.iconSizeMedium,
              ),
              const Spacer(),
              Text(
                NewsletterHelpers.formatDate(newsletter.date),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: NewsletterConstants.smallTextSize,
                ),
              ),
            ],
          ),
          const SizedBox(height: NewsletterConstants.tinyPadding),
          Text(
            newsletter.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(NewsletterConstants.smallPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              newsletter.description,
              style: const TextStyle(
                fontSize: NewsletterConstants.captionTextSize,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            if (newsletter.highlights.isNotEmpty) ...[
              const SizedBox(height: NewsletterConstants.smallTextSize),
              Wrap(
                spacing: NewsletterConstants.tinyPadding,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: NewsletterConstants.iconSizeTiny,
                    color: Colors.amber[700],
                  ),
                  Text(
                    '${newsletter.highlights.length} highlights',
                    style: TextStyle(
                      fontSize: NewsletterConstants.smallTextSize,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NewsletterConstants.smallPadding,
        vertical: NewsletterConstants.tinyPadding,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.visibility, size: NewsletterConstants.iconSizeTiny),
            label: const Text('View'),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(NewsletterHelpers.generateDownloadMessage(newsletter.title)),
                    ),
                  );
                },
                icon: const Icon(Icons.download, size: NewsletterConstants.iconSizeSmall),
                tooltip: 'Download',
              ),
              IconButton(
                onPressed: () {
                  Share.share(NewsletterHelpers.generateShareText(newsletter));
                },
                icon: const Icon(Icons.share, size: NewsletterConstants.iconSizeSmall),
                tooltip: 'Share',
              ),
            ],
          ),
        ],
      ),
    );
  }
}