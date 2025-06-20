import 'package:flutter/material.dart';
import 'package:smp_mentor_mentee_mobile_app/utils/responsive.dart';
import 'models/checklist.dart';
import 'models/checklist_filter.dart';
import 'utils/checklist_constants.dart';
import 'utils/checklist_helpers.dart';
import 'widgets/checklist_header.dart';
import 'widgets/checklist_section.dart';
import 'widgets/mentee_selector.dart';
import 'widgets/dialogs/checklist_details_dialog.dart';
import 'widgets/dialogs/create_checklist_dialog.dart';
import 'widgets/dialogs/edit_checklist_dialog.dart';
import 'widgets/dialogs/delete_confirmation_dialog.dart';

class WebChecklistScreen extends StatefulWidget {
  final bool isMentor;
  
  const WebChecklistScreen({
    super.key,
    this.isMentor = true,
  });

  @override
  State<WebChecklistScreen> createState() => _WebChecklistScreenState();
}

class _WebChecklistScreenState extends State<WebChecklistScreen> {
  // State
  ChecklistFilter _filter = ChecklistFilter.allMentees;
  List<Checklist> _defaultChecklists = [];
  List<Checklist> _customChecklists = [];
  List<Map<String, String>> _mentees = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // Load mock data
    setState(() {
      _defaultChecklists = ChecklistHelpers.createMockDefaultChecklists();
      _customChecklists = ChecklistHelpers.createMockCustomChecklists();
      _mentees = ChecklistHelpers.getMockMentees();
    });
  }

  void _updateFilter(ChecklistFilter filter) {
    setState(() {
      _filter = filter;
    });
  }

  void _showChecklistDetails(Checklist checklist) {
    showDialog(
      context: context,
      builder: (context) => ChecklistDetailsDialog(
        checklist: checklist,
        isMentor: widget.isMentor,
        selectedMenteeId: _filter.menteeId,
        mentees: _mentees,
        onChecklistUpdated: (updatedChecklist) {
          _updateChecklist(updatedChecklist);
        },
      ),
    );
  }

  void _showCreateChecklistDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateChecklistDialog(
        onCreate: (checklist) {
          setState(() {
            _customChecklists.add(checklist);
          });
          _showSuccessSnackBar('Checklist created successfully!');
        },
      ),
    );
  }

  void _showEditChecklistDialog(Checklist checklist) {
    showDialog(
      context: context,
      builder: (context) => EditChecklistDialog(
        checklist: checklist,
        onUpdate: (updatedChecklist) {
          _updateChecklist(updatedChecklist);
          _showSuccessSnackBar('Checklist updated successfully!');
        },
      ),
    );
  }

  void _duplicateChecklist(Checklist checklist) {
    final duplicatedChecklist = checklist.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '${checklist.title} (Copy)',
      items: checklist.items.map((item) => item.copyWith(
        completed: false,
        proof: null,
        proofStatus: null,
        feedback: null,
      )).toList(),
    );

    setState(() {
      _customChecklists.add(duplicatedChecklist);
    });
    
    _showSuccessSnackBar('Checklist duplicated successfully!');
  }

  void _confirmDeleteChecklist(Checklist checklist) {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        checklist: checklist,
        onConfirm: () {
          setState(() {
            _customChecklists.removeWhere((c) => c.id == checklist.id);
          });
          _showSuccessSnackBar('Checklist deleted successfully', isWarning: true);
        },
      ),
    );
  }

  void _updateChecklist(Checklist updatedChecklist) {
    setState(() {
      if (updatedChecklist.isCustom) {
        final index = _customChecklists.indexWhere((c) => c.id == updatedChecklist.id);
        if (index != -1) {
          _customChecklists[index] = updatedChecklist;
        }
      } else {
        final index = _defaultChecklists.indexWhere((c) => c.id == updatedChecklist.id);
        if (index != -1) {
          _defaultChecklists[index] = updatedChecklist;
        }
      }
    });
  }

  void _showSuccessSnackBar(String message, {bool isWarning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isWarning ? ChecklistConstants.warningColor : ChecklistConstants.successColor,
        duration: ChecklistConstants.snackBarDuration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    
    // Apply filters
    final filteredDefaultChecklists = ChecklistHelpers.filterChecklists(_defaultChecklists, _filter);
    final filteredCustomChecklists = ChecklistHelpers.filterChecklists(_customChecklists, _filter);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ChecklistHeader(
          isMentor: widget.isMentor,
          onCreateChecklist: widget.isMentor ? _showCreateChecklistDialog : null,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? ChecklistConstants.extraLargePadding : ChecklistConstants.defaultPadding),
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: ChecklistConstants.maxContentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isMentor)
                    MenteeSelector(
                      filter: _filter,
                      mentees: _mentees,
                      onFilterChanged: _updateFilter,
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Default Checklists Section
                  ChecklistSection(
                    title: 'Default Checklists',
                    checklists: filteredDefaultChecklists,
                    isMentor: widget.isMentor,
                    onChecklistTap: _showChecklistDetails,
                    emptyStateTitle: 'No default checklists available',
                    emptyStateSubtitle: _filter.hasActiveFilters 
                        ? 'Try adjusting your filters to see more checklists.'
                        : 'Default checklists will appear here once configured.',
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Custom Checklists Section
                  if (widget.isMentor) 
                    ChecklistSection(
                      title: 'Custom Checklists',
                      checklists: filteredCustomChecklists,
                      isMentor: widget.isMentor,
                      onChecklistTap: _showChecklistDetails,
                      onEdit: _showEditChecklistDialog,
                      onDuplicate: _duplicateChecklist,
                      onDelete: _confirmDeleteChecklist,
                      onCreateNew: _showCreateChecklistDialog,
                      emptyStateTitle: 'No custom checklists yet',
                      emptyStateSubtitle: _filter.hasActiveFilters 
                          ? 'Try adjusting your filters or create a new checklist.'
                          : 'Create your first custom checklist to get started.',
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}