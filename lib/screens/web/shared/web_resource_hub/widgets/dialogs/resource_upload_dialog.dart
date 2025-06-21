import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../services/mentor_service.dart';
import '../../models/resource_category.dart';
import '../../models/resource.dart';
import '../../utils/resource_constants.dart';

class ResourceUploadDialog extends StatefulWidget {
  final bool isMentor;
  final bool isCoordinator;
  final String? initialCategory;

  const ResourceUploadDialog({
    super.key,
    required this.isMentor,
    required this.isCoordinator,
    this.initialCategory,
  });

  @override
  State<ResourceUploadDialog> createState() => _ResourceUploadDialogState();
}

class _ResourceUploadDialogState extends State<ResourceUploadDialog> {
  String? selectedCategory;
  ResourceType? selectedType;
  Map<String, bool> selectedMentees = {};
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory;
    
    if (widget.isMentor) {
      final mentorService = Provider.of<MentorService>(context, listen: false);
      for (var mentee in mentorService.mentees) {
        selectedMentees[mentee['name']] = false;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mentorService = widget.isMentor ? Provider.of<MentorService>(context, listen: false) : null;
    
    return AlertDialog(
      title: const Text('Upload Resource'),
      content: SizedBox(
        width: ResourceConstants.dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCategoryDropdown(),
              const SizedBox(height: ResourceConstants.mediumPadding),
              _buildTitleField(),
              const SizedBox(height: ResourceConstants.mediumPadding),
              _buildDescriptionField(),
              const SizedBox(height: ResourceConstants.mediumPadding),
              _buildTypeDropdown(),
              const SizedBox(height: ResourceConstants.mediumPadding),
              _buildFileUploadButton(),
              
              if (widget.isMentor && mentorService != null) ...[
                const SizedBox(height: ResourceConstants.largePadding),
                const Divider(),
                const SizedBox(height: ResourceConstants.smallPadding),
                _buildMenteeAssignment(mentorService),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleUpload,
          child: const Text('Upload'),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = ResourceCategory.values
        .where((cat) => cat != ResourceCategory.all)
        .toList();

    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
      ),
      value: selectedCategory,
      items: categories.map((category) {
        return DropdownMenuItem(
          value: category.displayName,
          child: Text(category.displayName),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedCategory = value;
        });
      },
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Title',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<ResourceType>(
      decoration: const InputDecoration(
        labelText: 'Document Type',
        border: OutlineInputBorder(),
      ),
      items: ResourceType.values.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type.value),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedType = value;
        });
      },
    );
  }

  Widget _buildFileUploadButton() {
    return ElevatedButton.icon(
      onPressed: () {
        // TODO: Implement file picker
      },
      icon: const Icon(Icons.attach_file),
      label: const Text('Choose File'),
    );
  }

  Widget _buildMenteeAssignment(MentorService mentorService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assign to Mentees',
          style: TextStyle(
            fontSize: ResourceConstants.subtitleTextSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: ResourceConstants.smallPadding),
        ...mentorService.mentees.map((mentee) {
          String menteeName = mentee['name'];
          return CheckboxListTile(
            title: Text(menteeName),
            subtitle: Text(mentee['program']),
            value: selectedMentees[menteeName] ?? false,
            onChanged: (bool? value) {
              setState(() {
                selectedMentees[menteeName] = value ?? false;
              });
            },
            secondary: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            dense: true,
          );
        }).toList(),
      ],
    );
  }

  void _handleUpload() {
    List<String> assignedMentees = [];
    if (widget.isMentor) {
      selectedMentees.forEach((mentee, isSelected) {
        if (isSelected) {
          assignedMentees.add(mentee);
        }
      });
    }
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          assignedMentees.isEmpty
              ? ResourceConstants.uploadSuccessMessage
              : '${ResourceConstants.uploadSuccessMessage} and assigned to ${assignedMentees.length} mentee(s)',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
}