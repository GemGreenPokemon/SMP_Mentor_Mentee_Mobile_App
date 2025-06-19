import 'package:flutter/material.dart';
import 'dart:ui';
import '../../utils/announcement_constants.dart';

class CreateAnnouncementDialog extends StatefulWidget {
  final Function(String title, String content, String priority, String targetAudience) onCreatePressed;

  const CreateAnnouncementDialog({
    super.key,
    required this.onCreatePressed,
  });

  @override
  State<CreateAnnouncementDialog> createState() => _CreateAnnouncementDialogState();
}

class _CreateAnnouncementDialogState extends State<CreateAnnouncementDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _priority = 'none';
  String _targetAudience = 'both';

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create Announcement',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2D52),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter announcement title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0F2D52), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _contentController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Content',
                    hintText: 'Enter announcement content',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0F2D52), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Priority Level',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2D52),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: AnnouncementConstants.priorityConfig.entries.map((entry) {
                    final config = entry.value;
                    final isSelected = _priority == entry.key;
                    final color = config['color'] as MaterialColor;
                    return ChoiceChip(
                      label: Text(config['label'] as String),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _priority = entry.key);
                      },
                      selectedColor: color[config['colorValue'] as int]!.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? color[config['colorValue'] as int] : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill in all fields'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        widget.onCreatePressed(
                          _titleController.text,
                          _contentController.text,
                          _priority,
                          _targetAudience,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F2D52),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Create',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}