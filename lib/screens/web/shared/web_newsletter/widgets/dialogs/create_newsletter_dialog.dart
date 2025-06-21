import 'package:flutter/material.dart';
import '../../utils/newsletter_constants.dart';

class CreateNewsletterDialog extends StatelessWidget {
  const CreateNewsletterDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NewsletterConstants.dialogBorderRadius),
      ),
      title: const Text(NewsletterConstants.createNewsletterTitle),
      content: const Text(NewsletterConstants.createNewsletterMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}