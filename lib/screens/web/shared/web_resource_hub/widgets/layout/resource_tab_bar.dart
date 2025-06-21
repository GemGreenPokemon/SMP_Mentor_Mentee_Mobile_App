import 'package:flutter/material.dart';
import '../../utils/resource_constants.dart';

class ResourceTabBar extends StatelessWidget {
  final TabController tabController;

  const ResourceTabBar({
    super.key,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Theme.of(context).primaryColor,
        tabs: const [
          Tab(text: ResourceConstants.generalResourcesTab),
          Tab(text: ResourceConstants.documentsTab),
        ],
      ),
    );
  }
}