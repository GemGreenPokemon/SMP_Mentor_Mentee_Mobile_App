import 'package:flutter/material.dart';
import '../../utils/newsletter_constants.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.newspaper_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: NewsletterConstants.smallPadding),
          Text(
            NewsletterConstants.noNewslettersMessage,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}