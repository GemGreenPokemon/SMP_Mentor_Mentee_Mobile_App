import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smp_mentor_mentee_mobile_app/services/mentor_service.dart';
import '../../utils/dashboard_constants.dart';
import 'mentors_filter_bar.dart';
import 'mentors_list_card.dart';
import 'pending_mentors_card.dart';

class MentorsContent extends StatelessWidget {
  const MentorsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final mentorService = Provider.of<MentorService>(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CoordinatorDashboardDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and filter row
          const MentorsFilterBar(),
          const SizedBox(height: CoordinatorDashboardDimensions.paddingLarge),
          
          // Active Mentors List
          const MentorsListCard(),
          const SizedBox(height: CoordinatorDashboardDimensions.paddingLarge),
          
          // Pending Approvals
          const PendingMentorsCard(),
        ],
      ),
    );
  }
}