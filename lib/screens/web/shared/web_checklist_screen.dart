import 'package:flutter/material.dart';
import 'package:smp_mentor_mentee_mobile_app/utils/responsive.dart';

class WebChecklistScreen extends StatefulWidget {
  final bool isMentor;
  const WebChecklistScreen({super.key, this.isMentor = true});

  @override
  State<WebChecklistScreen> createState() => _WebChecklistScreenState();
}

class _WebChecklistScreenState extends State<WebChecklistScreen> {
  String selectedMentee = 'All Mentees';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = Responsive.isDesktop(context);
    bool isTablet = Responsive.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklists'),
        backgroundColor: const Color(0xFF0F2D52),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.isMentor)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Create Custom Checklist'),
                onPressed: () => _showCreateChecklistDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F2D52),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 1400 : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isMentor)
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 300,
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Select Mentee',
                                  prefixIcon: Icon(Icons.person),
                                  border: OutlineInputBorder(),
                                ),
                                value: selectedMentee,
                                items: [
                                  'All Mentees',
                                  'Alice Johnson',
                                  'Bob Wilson',
                                  'Carlos Rodriguez',
                                ].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedMentee = value!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 24),
                            if (selectedMentee != 'All Mentees')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.blue),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Viewing checklists for $selectedMentee',
                                      style: const TextStyle(color: Colors.blue),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Default Checklists Section
                  _buildSection('Default Checklists', defaultChecklists, isDesktop),
                  
                  const SizedBox(height: 32),
                  
                  // Custom Checklists Section
                  if (widget.isMentor) 
                    _buildSection('Custom Checklists', customChecklists, isDesktop),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> checklists, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${checklists.length} checklist${checklists.length != 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Responsive grid layout
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = isDesktop ? 3 : (Responsive.isTablet(context) ? 2 : 1);
            
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isDesktop ? 1.5 : (Responsive.isTablet(context) ? 1.3 : 1.2),
              ),
              itemCount: checklists.length,
              itemBuilder: (context, index) {
                return _buildChecklistCard(checklists[index]);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildChecklistCard(Map<String, dynamic> checklist) {
    final completedItems = checklist['items'].where((item) => item['completed'] == true).length;
    final totalItems = checklist['items'].length;
    final progress = totalItems > 0 ? completedItems / totalItems : 0.0;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showChecklistDetails(checklist),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      checklist['title'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.isMentor && checklist['isCustom'] == true)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showEditChecklistDialog(checklist);
                            break;
                          case 'duplicate':
                            _duplicateChecklist(checklist);
                            break;
                          case 'delete':
                            _confirmDeleteChecklist(checklist);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.copy, size: 20),
                              SizedBox(width: 8),
                              Text('Duplicate'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                checklist['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              
              // Progress section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$completedItems of $totalItems completed',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: progress == 1.0 ? Colors.green : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress == 1.0 ? Colors.green : Colors.blue,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (checklist['isCustom'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.purple),
                          SizedBox(width: 4),
                          Text(
                            'Custom',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.purple,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('View Details'),
                    onPressed: () => _showChecklistDetails(checklist),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChecklistDetails(Map<String, dynamic> checklist) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: Responsive.isDesktop(context) ? 800 : 600,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F2D52),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            checklist['title'],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            checklist['description'],
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Mentee selector (if mentor view)
              if (widget.isMentor)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Text(
                        'Viewing for:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 250,
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          value: selectedMentee == 'All Mentees' ? 'Alice Johnson' : selectedMentee,
                          items: [
                            'Alice Johnson',
                            'Bob Wilson',
                            'Carlos Rodriguez',
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            // TODO: Load checklist data for selected mentee
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Checklist items
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...checklist['items'].asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return _buildChecklistItem(checklist, item, index);
                      }).toList(),
                    ],
                  ),
                ),
              ),
              
              // Footer
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Progress summary
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Progress: ${(checklist['progress'] * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${checklist['items'].where((item) => item['completed'] == true).length} of ${checklist['items'].length} tasks completed',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    // Action buttons
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                        if (widget.isMentor) ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('Save Changes'),
                            onPressed: () {
                              // TODO: Save checklist state
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Checklist updated successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F2D52),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistItem(Map<String, dynamic> checklist, Map<String, dynamic> item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: item['completed'],
              onChanged: widget.isMentor ? (bool? value) {
                setState(() {
                  item['completed'] = value;
                  // Recalculate progress
                  final totalItems = checklist['items'].length;
                  final completedItems = checklist['items'].where((item) => item['completed'] == true).length;
                  checklist['progress'] = totalItems > 0 ? completedItems / totalItems : 0.0;
                });
              } : null,
              activeColor: const Color(0xFF0F2D52),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      decoration: item['completed'] ? TextDecoration.lineThrough : null,
                      color: item['completed'] ? Colors.grey : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: item['completed'] ? Colors.grey[400] : Colors.grey[600],
                      decoration: item['completed'] ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (item['proof'] != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item['proofStatus'] == 'approved' 
                          ? Colors.green.withOpacity(0.1)
                          : item['proofStatus'] == 'rejected'
                            ? Colors.red.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: item['proofStatus'] == 'approved' 
                            ? Colors.green
                            : item['proofStatus'] == 'rejected'
                              ? Colors.red
                              : Colors.orange,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                item['proofStatus'] == 'approved'
                                  ? Icons.check_circle
                                  : item['proofStatus'] == 'rejected'
                                    ? Icons.cancel
                                    : Icons.pending,
                                size: 16,
                                color: item['proofStatus'] == 'approved' 
                                  ? Colors.green
                                  : item['proofStatus'] == 'rejected'
                                    ? Colors.red
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Proof: ${item['proof']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: item['proofStatus'] == 'approved' 
                                    ? Colors.green[700]
                                    : item['proofStatus'] == 'rejected'
                                      ? Colors.red[700]
                                      : Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                          if (item['proofStatus'] == 'rejected' && item['feedback'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Feedback: ${item['feedback']}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.isMentor && item['proof'] != null && item['proofStatus'] == 'pending')
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () {
                      setState(() {
                        item['proofStatus'] = 'approved';
                      });
                    },
                    tooltip: 'Approve',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _showRejectProofDialog(item),
                    tooltip: 'Reject',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showRejectProofDialog(Map<String, dynamic> item) {
    final feedbackController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Proof'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide feedback for the mentee:'),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              decoration: const InputDecoration(
                labelText: 'Feedback',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                item['proofStatus'] = 'rejected';
                item['feedback'] = feedbackController.text;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showCreateChecklistDialog() {
    List<Map<String, dynamic>> items = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: Responsive.isDesktop(context) ? 800 : 600,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F2D52),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
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
                        onPressed: () {
                          _titleController.clear();
                          _descriptionController.clear();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
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
                              onPressed: () {
                                _showAddItemDialog(context, (title, description) {
                                  setState(() {
                                    items.add({
                                      'title': title,
                                      'description': description,
                                      'completed': false,
                                    });
                                  });
                                });
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Item'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F2D52),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (items.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.checklist,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No items added yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Click "Add Item" to create your first checklist item.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...items.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF0F2D52).withOpacity(0.1),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Color(0xFF0F2D52),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  item['title'],
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  item['description'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () {
                                        _showEditItemDialog(
                                          context,
                                          item['title'],
                                          item['description'],
                                          (title, description) {
                                            setState(() {
                                              items[index]['title'] = title;
                                              items[index]['description'] = description;
                                            });
                                          },
                                        );
                                      },
                                      tooltip: 'Edit',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          items.removeAt(index);
                                        });
                                      },
                                      tooltip: 'Delete',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  ),
                ),
                
                // Footer
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          _titleController.clear();
                          _descriptionController.clear();
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: (_titleController.text.isEmpty || items.isEmpty)
                            ? null
                            : () {
                                // Add the new checklist to customChecklists
                                final newChecklist = {
                                  'title': _titleController.text,
                                  'description': _descriptionController.text,
                                  'progress': 0.0,
                                  'isCustom': true,
                                  'items': items,
                                };
                                setState(() {
                                  customChecklists.add(newChecklist);
                                });
                                _titleController.clear();
                                _descriptionController.clear();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Checklist created successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F2D52),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: const Text('Create Checklist'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddItemDialog(
    BuildContext context,
    Function(String title, String description) onAdd,
  ) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Checklist Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Item Title',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Item Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                onAdd(titleController.text, descriptionController.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F2D52),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(
    BuildContext context,
    String currentTitle,
    String currentDescription,
    Function(String title, String description) onEdit,
  ) {
    final titleController = TextEditingController(text: currentTitle);
    final descriptionController = TextEditingController(text: currentDescription);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Checklist Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Item Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Item Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                onEdit(titleController.text, descriptionController.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F2D52),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditChecklistDialog(Map<String, dynamic> checklist) {
    // Similar to create dialog but pre-filled
    // Implementation would be similar to _showCreateChecklistDialog but with pre-filled data
  }

  void _duplicateChecklist(Map<String, dynamic> checklist) {
    final newChecklist = {
      'title': '${checklist['title']} (Copy)',
      'description': checklist['description'],
      'progress': 0.0,
      'isCustom': true,
      'items': checklist['items'].map((item) => {
        'title': item['title'],
        'description': item['description'],
        'completed': false,
      }).toList(),
    };
    
    setState(() {
      customChecklists.add(newChecklist);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checklist duplicated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _confirmDeleteChecklist(Map<String, dynamic> checklist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Checklist'),
        content: Text('Are you sure you want to delete "${checklist['title']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                customChecklists.remove(checklist);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Checklist deleted successfully'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Mock data
  final List<Map<String, dynamic>> defaultChecklists = [
    {
      'title': 'Initial Mentorship Setup',
      'description': 'Essential tasks for starting the mentorship relationship',
      'progress': 0.4,
      'isCustom': false,
      'items': [
        {
          'title': 'First Meeting Completed',
          'description': 'Introductory meeting with mentee',
          'completed': true,
        },
        {
          'title': 'Program Overview Discussed',
          'description': 'Review program expectations and guidelines',
          'completed': true,
        },
        {
          'title': 'Goals Established',
          'description': 'Set academic and personal development goals',
          'completed': false,
        },
        {
          'title': 'Communication Preferences Set',
          'description': 'Establish preferred contact methods and times',
          'completed': false,
        },
        {
          'title': 'Resource Access Confirmed',
          'description': 'Ensure access to necessary program resources',
          'completed': false,
        },
      ],
    },
    {
      'title': 'Monthly Progress Review',
      'description': 'Regular check-in items for tracking progress',
      'progress': 0.0,
      'isCustom': false,
      'items': [
        {
          'title': 'Academic Progress Review',
          'description': 'Discuss current academic performance',
          'completed': false,
        },
        {
          'title': 'Goals Progress Check',
          'description': 'Review progress on established goals',
          'completed': false,
        },
        {
          'title': 'Resource Utilization',
          'description': 'Evaluate use of available resources',
          'completed': false,
        },
        {
          'title': 'Challenges Discussion',
          'description': 'Address any current challenges or concerns',
          'completed': false,
        },
      ],
    },
  ];

  final List<Map<String, dynamic>> customChecklists = [
    {
      'title': 'Research Project Guidance',
      'description': 'Steps for mentoring through research project',
      'progress': 0.6,
      'isCustom': true,
      'items': [
        {
          'title': 'Topic Selection',
          'description': 'Help mentee choose research topic',
          'completed': true,
          'proof': 'Research proposal document',
          'proofStatus': 'approved',
        },
        {
          'title': 'Literature Review',
          'description': 'Guide through literature review process',
          'completed': true,
          'proof': 'Literature review draft',
          'proofStatus': 'approved',
        },
        {
          'title': 'Methodology Planning',
          'description': 'Assist with research methodology',
          'completed': true,
          'proof': 'Methodology section draft',
          'proofStatus': 'pending',
        },
        {
          'title': 'Data Collection',
          'description': 'Support during data collection phase',
          'completed': false,
        },
        {
          'title': 'Data Analysis',
          'description': 'Help with data analysis and interpretation',
          'completed': false,
        },
      ],
    },
  ];
}