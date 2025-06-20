import 'package:flutter/material.dart';
import 'package:smp_mentor_mentee_mobile_app/utils/responsive.dart';
import '../../models/checklist.dart';
import '../../models/checklist_item.dart';
import '../../utils/checklist_constants.dart';
import '../empty_state.dart';
import 'add_item_dialog.dart';
import 'edit_item_dialog.dart';

class CreateChecklistDialog extends StatefulWidget {
  final Function(Checklist) onCreate;

  const CreateChecklistDialog({
    super.key,
    required this.onCreate,
  });

  @override
  State<CreateChecklistDialog> createState() => _CreateChecklistDialogState();
}

class _CreateChecklistDialogState extends State<CreateChecklistDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<ChecklistItem> _items = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addItem(String title, String description) {
    setState(() {
      _items.add(ChecklistItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
      ));
    });
  }

  void _editItem(int index, String title, String description) {
    setState(() {
      _items[index] = _items[index].copyWith(
        title: title,
        description: description,
      );
    });
  }

  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _createChecklist() {
    if (_titleController.text.isNotEmpty && _items.isNotEmpty) {
      final checklist = Checklist(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        items: _items,
        isCustom: true,
      );
      
      widget.onCreate(checklist);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = Responsive.isDesktop(context) 
        ? ChecklistConstants.maxDialogWidth 
        : 600.0;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ChecklistConstants.dialogBorderRadius),
      ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(child: _buildContent()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(ChecklistConstants.largePadding),
      decoration: BoxDecoration(
        color: ChecklistConstants.primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(ChecklistConstants.dialogBorderRadius),
          topRight: Radius.circular(ChecklistConstants.dialogBorderRadius),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Create Custom Checklist',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ChecklistConstants.largePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Checklist Title',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          _buildItemsSection(),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Checklist Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddItemDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChecklistConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_items.isEmpty)
          EmptyState(
            title: 'No items added yet',
            subtitle: 'Click "Add Item" to create your first checklist item.',
          )
        else
          ..._items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildItemCard(index, item);
          }),
      ],
    );
  }

  Widget _buildItemCard(int index, ChecklistItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: ChecklistConstants.primaryColor.withOpacity(0.1),
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: ChecklistConstants.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          item.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showEditItemDialog(index, item),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteItem(index),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(ChecklistConstants.largePadding),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(ChecklistConstants.dialogBorderRadius),
          bottomRight: Radius.circular(ChecklistConstants.dialogBorderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: (_titleController.text.isEmpty || _items.isEmpty)
                ? null
                : _createChecklist,
            style: ElevatedButton.styleFrom(
              backgroundColor: ChecklistConstants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Create Checklist'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        onAdd: _addItem,
      ),
    );
  }

  void _showEditItemDialog(int index, ChecklistItem item) {
    showDialog(
      context: context,
      builder: (context) => EditItemDialog(
        currentTitle: item.title,
        currentDescription: item.description,
        onEdit: (title, description) => _editItem(index, title, description),
      ),
    );
  }
}