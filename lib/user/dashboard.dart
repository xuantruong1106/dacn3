import 'package:flutter/material.dart';
import '../db_connect.dart';

class MainApp extends StatefulWidget {
  MainApp({Key? key}) : super(key: key);

  final db = DatabaseConnection();

  @override
  State<StatefulWidget> createState() {
    return DashboardState();
  }
}

class DashboardState extends State<MainApp> {
  late bool _isLoading; // State to track loading
  late List<Map<String, dynamic>> _data; // State to hold query results

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _data = [];
    _loadData(); // Fetch data from the database
  }

  Future<void> _loadData() async {
    try {
      await widget.db.connect();
      final results = await widget.db.executeQuery('SELECT username, phone, address FROM accounts');
      setState(() {
        // Convert query results into a list of maps
        _data = results
            .map((row) => {
                  'username': row[0],
                  'phone': row[1],
                  'address': row[2],
                })
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
    } finally {
      await widget.db.close();
      print('Connection closed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Data'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data.isEmpty
              ? const Center(child: Text('No data available'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Username')),
                      DataColumn(label: Text('Phone')),
                      DataColumn(label: Text('Address')),
                    ],
                    rows: _data.map((row) {
                      return DataRow(
                        cells: [
                          DataCell(Text(row['username'].toString())),
                          DataCell(Text(row['phone'])),
                          DataCell(Text(row['address'])),
                        ],
                      );
                    }).toList(),
                  ),
                ),
    );
  }
}
