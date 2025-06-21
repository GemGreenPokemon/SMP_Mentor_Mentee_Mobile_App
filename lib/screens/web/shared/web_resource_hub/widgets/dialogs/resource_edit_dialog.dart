import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../services/mentor_service.dart';
import '../../models/resource.dart';
import '../../models/resource_category.dart';
import '../../utils/resource_constants.dart';

class ResourceEditDialog extends StatefulWidget {
  final Resource resource;
  final bool isMentor;
  final bool isCoordinator;

  const ResourceEditDialog({
    super.key,
    required this.resource,
    required this.isMentor,
    required this.isCoordinator,
  });

  @override
  State<ResourceEditDialog> createState() => _ResourceEditDialogState();
}

class _ResourceEditDialogState extends State<ResourceEditDialog> {
  late String selectedCategory;
  late ResourceType selectedType;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  Map<String, bool> selectedMentees = {};
  
  @override
  void initState() {
    super.initState();
    selectedCategory = widget.resource.category;
    selectedType = widget.resource.type;
    _titleController = TextEditingController(text: widget.resource.title);
    _descriptionController = TextEditingController(text: widget.resource.description);
    
    if (widget.isMentor) {
      final mentorService = Provider.of<MentorService>(context, listen: false);
      for (var mentee in mentorService.mentees) {
        String menteeName = mentee['name'];
        selectedMentees[menteeName] = widget.resource.assignedTo.contains(menteeName);
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
      title: const Text('Edit Document'),
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
              _buildFileReplaceButton(),
              
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
          onPressed: _handleSaveChanges,
          child: const Text('Save Changes'),
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
          selectedCategory = value!;
        });
      },
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Document Title',
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
      value: selectedType,
      items: ResourceType.values.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type.value),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedType = value!;
        });
      },
    );
  }

  Widget _buildFileReplaceButton() {
    return ElevatedButton.icon(
      onPressed: () {
        // TODO: Implement file picker
      },
      icon: const Icon(Icons.attach_file),
      label: const Text('Replace File'),
    );
  }

  Widget _buildMenteeAssignment(MentorService mentorService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assign to Specific Mentees',
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
            dense: true,
          );
        }).toList(),
      ],
    );
  }

  void _handleSaveChanges() {
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
              ? ResourceConstants.updateSuccessMessage
              : '${ResourceConstants.updateSuccessMessage} and assigned to ${assignedMentees.length} mentee(s)',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
}