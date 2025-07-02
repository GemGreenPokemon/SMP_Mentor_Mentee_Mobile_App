import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smp_mentor_mentee_mobile_app/services/mentor_service.dart';
import '../../models/coordinator_dashboard_data.dart';
import '../../utils/dashboard_constants.dart';
import 'program_overview_card.dart';
import 'quick_actions_section.dart';
import 'messages_section.dart';
import 'assignments_section.dart';
import 'activity_section.dart';
import 'events_section.dart';
import 'action_items_section.dart';
import 'mentees_list_section.dart';

class DashboardOverview extends StatelessWidget {
  final CoordinatorDashboardData? dashboardData;

  const DashboardOverview({
    super.key,
    this.dashboardData,
  });

  @override
  Widget build(BuildContext context) {
    final mentorService = Provider.of<MentorService>(context);
    
    if (dashboardData == null) {
      return const Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Program Overview Card
          ProgramOverviewCard(dashboardData: dashboardData!),
          const SizedBox(height: 24),
          
          // Quick Actions
          const QuickActionsSection(),
          const SizedBox(height: 24),
          
          // Two-column layout for the rest
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column - Messages and Assignments
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    MessagesSection(dashboardData: dashboardData!),
                    const SizedBox(height: 24),
                    AssignmentsSection(dashboardData: dashboardData!),
                  ],
                ),
              ),
              
              const SizedBox(width: 24),
              
              // Right column - Activity, Events, Action Items
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    ActivitySection(dashboardData: dashboardData!),
                    const SizedBox(height: 24),
                    EventsSection(dashboardData: dashboardData!),
                    const SizedBox(height: 24),
                    const ActionItemsSection(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // List of Mentees Section
          const MenteesListSection(),
        ],
      ),
    );
  }
}