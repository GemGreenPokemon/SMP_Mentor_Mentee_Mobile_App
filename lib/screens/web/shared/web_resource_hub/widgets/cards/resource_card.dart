import 'package:flutter/material.dart';
import '../../models/quick_link.dart';
import '../../utils/resource_constants.dart';

class ResourceCard extends StatelessWidget {
  final QuickLink quickLink;

  const ResourceCard({
    super.key,
    required this.quickLink,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: ResourceConstants.cardElevation,
      child: InkWell(
        onTap: quickLink.onTap ?? () {
          // Default action - could open URL if provided
          if (quickLink.url != null) {
            // TODO: Implement URL opening
          }
        },
        borderRadius: BorderRadius.circular(ResourceConstants.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(ResourceConstants.mediumPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                quickLink.icon,
                size: ResourceConstants.iconSizeLarge,
                color: quickLink.color,
              ),
              const SizedBox(height: ResourceConstants.smallPadding * 1.5),
              Text(
                quickLink.title,
                style: const TextStyle(
                  fontSize: ResourceConstants.subtitleTextSize,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ResourceConstants.smallPadding),
              Text(
                quickLink.description,
                style: TextStyle(
                  fontSize: ResourceConstants.bodyTextSize,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}