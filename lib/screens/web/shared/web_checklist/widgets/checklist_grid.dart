import 'package:flutter/material.dart';
import 'package:smp_mentor_mentee_mobile_app/utils/responsive.dart';
import '../models/checklist.dart';
import '../utils/checklist_constants.dart';
import 'checklist_card.dart';

class ChecklistGrid extends StatelessWidget {
  final List<Checklist> checklists;
  final bool isMentor;
  final Function(Checklist) onChecklistTap;
  final Function(Checklist)? onEdit;
  final Function(Checklist)? onDuplicate;
  final Function(Checklist)? onDelete;

  const ChecklistGrid({
    super.key,
    required this.checklists,
    required this.isMentor,
    required this.onChecklistTap,
    this.onEdit,
    this.onDuplicate,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isDesktop 
            ? ChecklistConstants.desktopGridColumns 
            : (isTablet 
                ? ChecklistConstants.tabletGridColumns 
                : ChecklistConstants.mobileGridColumns);

        final aspectRatio = isDesktop 
            ? ChecklistConstants.desktopCardAspectRatio 
            : (isTablet 
                ? ChecklistConstants.tabletCardAspectRatio 
                : ChecklistConstants.mobileCardAspectRatio);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: ChecklistConstants.defaultPadding,
            mainAxisSpacing: ChecklistConstants.defaultPadding,
            childAspectRatio: aspectRatio,
          ),
          itemCount: checklists.length,
          itemBuilder: (context, index) {
            final checklist = checklists[index];
            return ChecklistCard(
              checklist: checklist,
              isMentor: isMentor,
              onTap: () => onChecklistTap(checklist),
              onEdit: checklist.isCustom && onEdit != null
                  ? () => onEdit!(checklist)
                  : null,
              onDuplicate: checklist.isCustom && onDuplicate != null
                  ? () => onDuplicate!(checklist)
                  : null,
              onDelete: checklist.isCustom && onDelete != null
                  ? () => onDelete!(checklist)
                  : null,
            );
          },
        );
      },
    );
  }
}