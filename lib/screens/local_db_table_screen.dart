import 'package:flutter/material.dart';
import '../services/local_database_service.dart';

class LocalDbTableScreen extends StatefulWidget {
  final String tableName;
  const LocalDbTableScreen({Key? key, required this.tableName}) : super(key: key);

  @override
  State<LocalDbTableScreen> createState() => _LocalDbTableScreenState();
}

class _LocalDbTableScreenState extends State<LocalDbTableScreen> {
  List<Map<String, dynamic>> _rows = [];
  List<String> _columns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTable();
  }

  Future<void> _loadTable() async {
    final db = await LocalDatabaseService.instance.database;
    final rows = await db.query(widget.tableName);
    setState(() {
      _rows = rows;
      _columns = rows.isNotEmpty ? rows.first.keys.toList() : [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.tableName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: _columns
                      .map((col) => DataColumn(label: Text(col)))
                      .toList(),
                  rows: _rows
                      .map(
                        (row) => DataRow(
                          cells: _columns
                              .map((col) => DataCell(Text(row[col]?.toString() ?? '')))
                              .toList(),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
    );
  }
}
