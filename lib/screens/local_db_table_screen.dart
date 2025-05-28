import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../services/local_database_service.dart';
import '../models/user.dart';
import '../models/meeting.dart';
import '../models/announcement.dart';
import '../models/event.dart';
import '../models/checklist.dart';
import '../models/message.dart';

class LocalDbTableScreen extends StatefulWidget {
  final String tableName;
  const LocalDbTableScreen({Key? key, required this.tableName}) : super(key: key);

  @override
  State<LocalDbTableScreen> createState() => _LocalDbTableScreenState();
}

class _LocalDbTableScreenState extends State<LocalDbTableScreen> {
  List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _filteredRows = [];
  List<String> _columns = [];
  bool _loading = true;
  String _searchQuery = '';
  String? _selectedColumn;
  bool _showRawData = false;
  int? _selectedRowIndex;
  Map<String, String> _userNames = {}; // Cache for user names by ID
  Map<String, String> _studentIdToName = {}; // Cache for student ID to name mapping

  @override
  void initState() {
    super.initState();
    _loadTable();
  }

  Future<void> _loadTable() async {
    setState(() => _loading = true);
    try {
      final rows = await LocalDatabaseService.instance.getTableData(widget.tableName);
      
      // Load user names for relationship tables
      if (_needsUserNames()) {
        await _loadUserNames();
      }
      
      setState(() {
        _rows = rows;
        _filteredRows = rows;
        _columns = rows.isNotEmpty ? rows.first.keys.toList() : [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading table: $e')),
        );
      }
    }
  }

  bool _needsUserNames() {
    // Tables that contain user IDs that should show names
    return [
      'mentorships',
      'meetings',
      'messages',
      'meeting_notes',
      'meeting_ratings',
      'checklists',
      'announcements',
      'events',
      'resources',
      'progress_reports',
      'availability',
    ].contains(widget.tableName);
  }

  Future<void> _loadUserNames() async {
    final users = await LocalDatabaseService.instance.getAllUsers();
    _userNames = {};
    _studentIdToName = {};
    
    for (final user in users) {
      // For mentorships table, include student ID
      if (widget.tableName == 'mentorships' && user.studentId != null) {
        _userNames[user.id] = '${user.name} (${user.studentId})';
      } else {
        _userNames[user.id] = '${user.name} (${user.userType})';
      }
      
      // Also map student IDs to names for the mentee field
      if (user.studentId != null) {
        _studentIdToName[user.studentId] = user.name;
      }
    }
  }

  void _filterData() {
    setState(() {
      _filteredRows = _rows.where((row) {
        if (_searchQuery.isEmpty) return true;
        
        // Search in selected column or all columns
        if (_selectedColumn != null) {
          final value = row[_selectedColumn]?.toString().toLowerCase() ?? '';
          return value.contains(_searchQuery.toLowerCase());
        } else {
          // Search in all columns
          return row.values.any((value) {
            final strValue = value?.toString().toLowerCase() ?? '';
            return strValue.contains(_searchQuery.toLowerCase());
          });
        }
      }).toList();
    });
  }

  String _formatValue(dynamic value, String column) {
    if (value == null) return 'null';
    
    // Format user IDs to show names
    if (_isUserIdColumn(column) && value is String && _userNames.containsKey(value)) {
      final name = _userNames[value]!;
      if (_showRawData) {
        return '$name\n$value';
      }
      return name;
    }
    
    // Special handling for mentee field (JSON array of student IDs)
    if (column == 'mentee' && value is String && value.startsWith('[')) {
      try {
        final menteeIds = json.decode(value) as List;
        if (menteeIds.isEmpty) return 'None';
        
        // Map student IDs to names
        final menteeNames = menteeIds
            .map((id) => _studentIdToName[id] ?? id.toString())
            .toList();
        
        if (_showRawData) {
          // Show both names and IDs
          final namesWithIds = [];
          for (int i = 0; i < menteeIds.length; i++) {
            namesWithIds.add('${menteeNames[i]} (${menteeIds[i]})');
          }
          return namesWithIds.join(', ');
        }
        
        // Show just the names
        return menteeNames.join(', ');
      } catch (e) {
        // If not valid JSON, return as is
      }
    }
    
    // Format timestamps
    if (column.contains('_at') || column.contains('time')) {
      try {
        if (value is int) {
          final date = DateTime.fromMillisecondsSinceEpoch(value);
          return '${date.toLocal()}'.split('.')[0];
        } else if (value is String && value.contains('T')) {
          final date = DateTime.parse(value);
          return '${date.toLocal()}'.split('.')[0];
        }
      } catch (e) {
        // If parsing fails, return original value
      }
    }
    
    // Format boolean values
    if (column.contains('is_') || column.contains('synced')) {
      if (value == 1 || value == true) return '✓';
      if (value == 0 || value == false) return '✗';
    }
    
    // Truncate long strings
    final strValue = value.toString();
    if (strValue.length > 50 && !_showRawData) {
      return '${strValue.substring(0, 47)}...';
    }
    
    return strValue;
  }

  bool _isUserIdColumn(String column) {
    return column == 'mentor_id' || 
           column == 'mentee_id' || 
           column == 'user_id' ||
           column == 'author_id' ||
           column == 'sender_id' ||
           column == 'created_by' ||
           column == 'uploaded_by' ||
           column == 'assigned_by';
  }

  Color? _getRowColor(Map<String, dynamic> row) {
    // Color code by user type
    if (widget.tableName == 'users') {
      switch (row['userType']) {
        case 'coordinator':
          return Colors.purple.withOpacity(0.1);
        case 'mentor':
          return Colors.blue.withOpacity(0.1);
        case 'mentee':
          return Colors.green.withOpacity(0.1);
      }
    }
    
    // Color code by status
    if (row.containsKey('status')) {
      switch (row['status']) {
        case 'pending':
          return Colors.orange.withOpacity(0.1);
        case 'accepted':
          return Colors.green.withOpacity(0.1);
        case 'rejected':
          return Colors.red.withOpacity(0.1);
      }
    }
    
    // Color code by priority
    if (row.containsKey('priority')) {
      switch (row['priority']) {
        case 'high':
          return Colors.red.withOpacity(0.1);
        case 'medium':
          return Colors.orange.withOpacity(0.1);
        case 'low':
          return Colors.yellow.withOpacity(0.1);
      }
    }
    
    return null;
  }

  void _showRowDetails(Map<String, dynamic> row, int index) {
    setState(() => _selectedRowIndex = index);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Row Details (${widget.tableName})',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: () {
                final jsonStr = const JsonEncoder.withIndent('  ').convert(row);
                Clipboard.setData(ClipboardData(text: jsonStr));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
              tooltip: 'Copy as JSON',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: _columns.map((column) {
              final value = row[column];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        '$column:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: SelectableText(
                        _formatValue(value, column),
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          if (index > 0)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showRowDetails(_filteredRows[index - 1], index - 1);
              },
              child: const Text('Previous'),
            ),
          if (index < _filteredRows.length - 1)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showRowDetails(_filteredRows[index + 1], index + 1);
              },
              child: const Text('Next'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tableName} (${_filteredRows.length} rows)'),
        actions: [
          IconButton(
            icon: Icon(_showRawData ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _showRawData = !_showRawData),
            tooltip: _showRawData ? 'Hide raw data' : 'Show raw data',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTable,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          onChanged: (value) {
                            _searchQuery = value;
                            _filterData();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String?>(
                        value: _selectedColumn,
                        hint: const Text('All columns'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All columns'),
                          ),
                          ..._columns.map((col) => DropdownMenuItem(
                            value: col,
                            child: Text(col),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedColumn = value);
                          _filterData();
                        },
                      ),
                    ],
                  ),
                ),
                // Data table
                Expanded(
                  child: _filteredRows.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'No data in ${widget.tableName}'
                                : 'No results found',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              showCheckboxColumn: false,
                              columns: _columns
                                  .map((col) => DataColumn(
                                        label: Text(
                                          col,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ))
                                  .toList(),
                              rows: _filteredRows.asMap().entries.map((entry) {
                                final index = entry.key;
                                final row = entry.value;
                                final isSelected = _selectedRowIndex == index;
                                
                                return DataRow(
                                  selected: isSelected,
                                  color: MaterialStateProperty.resolveWith<Color?>(
                                    (Set<MaterialState> states) {
                                      if (states.contains(MaterialState.selected)) {
                                        return Theme.of(context).colorScheme.primary.withOpacity(0.2);
                                      }
                                      return _getRowColor(row);
                                    },
                                  ),
                                  onSelectChanged: (_) => _showRowDetails(row, index),
                                  cells: _columns
                                      .map((col) => DataCell(
                                            Container(
                                              constraints: const BoxConstraints(maxWidth: 200),
                                              child: Text(
                                                _formatValue(row[col], col),
                                                style: const TextStyle(fontSize: 12),
                                                maxLines: _showRawData ? 3 : 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
