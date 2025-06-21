import 'package:flutter/material.dart';
import '../../models/quick_link.dart';
import '../../utils/resource_constants.dart';
import '../../utils/resource_helpers.dart';
import '../cards/resource_card.dart';
import '../shared/coordinator_controls.dart';

class GeneralResourcesTab extends StatelessWidget {
  final bool isCoordinator;
  final VoidCallback onAddResource;

  const GeneralResourcesTab({
    super.key,
    required this.isCoordinator,
    required this.onAddResource,
  });

  @override
  Widget build(BuildContext context) {
    final quickLinks = ResourceHelpers.getQuickLinks();
    final programResources = ResourceHelpers.getProgramResources();

    return Container(
      padding: const EdgeInsets.all(ResourceConstants.largePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCoordinator)
            CoordinatorControls(onAddResource: onAddResource),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = ResourceConstants.getGridCrossAxisCount(
                  constraints.maxWidth,
                );

                return CustomScrollView(
                  slivers: [
                    // Quick Links Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: ResourceConstants.largePadding,
                        ),
                        child: Text(
                          ResourceConstants.quickLinksTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ),
                    SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: ResourceConstants.cardAspectRatio,
                        crossAxisSpacing: ResourceConstants.mediumPadding,
                        mainAxisSpacing: ResourceConstants.mediumPadding,
                      ),
                      delegate: SliverChildListDelegate(
                        quickLinks.map((link) => ResourceCard(quickLink: link)).toList(),
                      ),
                    ),
                    
                    // Spacer
                    const SliverToBoxAdapter(
                      child: SizedBox(height: ResourceConstants.largePadding * 2),
                    ),
                    
                    // Program Resources Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: ResourceConstants.largePadding,
                        ),
                        child: Text(
                          ResourceConstants.programResourcesTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ),
                    SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: ResourceConstants.cardAspectRatio,
                        crossAxisSpacing: ResourceConstants.mediumPadding,
                        mainAxisSpacing: ResourceConstants.mediumPadding,
                      ),
                      delegate: SliverChildListDelegate(
                        programResources.map((link) => ResourceCard(quickLink: link)).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}