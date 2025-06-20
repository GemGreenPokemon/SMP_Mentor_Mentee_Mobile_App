import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dashboard_data.dart';
import '../../utils/dashboard_constants.dart';
import '../../utils/responsive.dart';
import '../dialogs/add_mentee_dialog.dart';
import 'mentees_search_bar.dart';
import 'mentee_grid_card.dart';
import '../../../../../../../../../services/mentor_service.dart';

class MenteesContent extends StatefulWidget {
  final DashboardData? dashboardData;

  const MenteesContent({
    super.key,
    required this.dashboardData,
  });

  @override
  State<MenteesContent> createState() => _MenteesContentState();
}

class _MenteesContentState extends State<MenteesContent> {
  String _searchQuery = '';
  String _filterValue = 'All';

  @override
  Widget build(BuildContext context) {
    final mentorService = Provider.of<MentorService>(context);
    
    if (widget.dashboardData == null) {
      return const Center(child: Text(DashboardStrings.noDataAvailable));
    }

    final mentees = widget.dashboardData!.mentees;

    return Padding(
      padding: const EdgeInsets.all(DashboardSizes.spacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MenteesSearchBar(
            onSearchChanged: (value) => setState(() => _searchQuery = value),
            onFilterChanged: (value) => setState(() => _filterValue = value ?? 'All'),
            onAddMentee: () => AddMenteeDialog.show(
              context,
              (menteeData) => mentorService.addMentee(menteeData),
            ),
          ),
          const SizedBox(height: DashboardSizes.spacingLarge),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: Responsive.isDesktop(context) ? 3 : 2,
                crossAxisSpacing: DashboardSizes.spacingMedium,
                mainAxisSpacing: DashboardSizes.spacingMedium,
                childAspectRatio: 1.5,
              ),
              itemCount: mentees.length,
              itemBuilder: (context, index) {
                final mentee = mentees[index];
                return MenteeGridCard(
                  mentee: mentee,
                  onRemove: () => mentorService.mentees.remove(mentee),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}