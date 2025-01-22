import 'package:flutter/material.dart';
import '../database_connect.dart';

class DashboardInterface extends StatefulWidget {
  DashboardInterface({super.key});

  final db = DatabaseConnection();

  @override
  State<StatefulWidget> createState() {
    return DashboardState();
  }
}

class DashboardState extends State<DashboardInterface> {
  late bool isLoading;
  late List<Map<String, dynamic>> data;

  @override
  void initState() {
    super.initState();
    isLoading = true;
    data = [];
    loadData();
  }

  Future<void> loadData() async {
    try {
      await widget.db.connect();
      final results = await widget.db
          .executeQuery('SELECT username, phone, address FROM accounts');
      setState(() {
        data = results
            .map((row) => {
                  'username': row[0],
                  'phone': row[1],
                  'address': row[2],
                })
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
    } finally {
      await widget.db.close();
      print('Connection closed');
    }
  }

  Future? onPressed() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: Container(
          margin: const EdgeInsets.only(left: 10, top: 15),
          width: 60, // Specify the width of the container
          height: 60,
          child: ClipOval(
            child: Image.asset(
              "assets/avatar.png",
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(
              left: 10.0, top: 10.0, bottom: 5.0), // Add padding
          child: Row(
            children: [
              // Column for greeting and username
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome back,",
                    style: TextStyle(
                      color: const Color.fromARGB(124, 157, 157, 153),
                      fontSize: 14,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Text(
                      "${data[0]['username']}",
                      style: TextStyle(
                        color: const Color.fromARGB(255, 37, 37, 37),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Spacer(), // This will push the text to the left and the icon to the right
              Container(
                decoration: BoxDecoration(
            color:   Color.fromARGB(205, 220, 219, 219), // Background color for the icon
            border: Border.all(
              color:  Color.fromARGB(205, 232, 231, 231), 
              width: 2, // Border width
            ),
            borderRadius: BorderRadius.circular(30), // Rounded corners
          ),
              child: IconButton(
                icon: Icon(Icons.search,),
                onPressed: () {
                  onPressed();
                },
                 color: const Color.fromARGB(255, 0, 0, 0), 
              ),
              )
            ],
          ),
        ),
      ),

      // body: isLoading
      //     ? const Center(child: CircularProgressIndicator())
      //     : data.isEmpty
      //         ? const Center(child: Text('No data available'))
      //         : SingleChildScrollView(
      //             scrollDirection: Axis.horizontal,
      //             child: DataTable(
      //               columns: const [
      //                 DataColumn(label: Text('Username')),
      //                 DataColumn(label: Text('Phone')),
      //                 DataColumn(label: Text('Address')),
      //               ],
      //               rows: data.map((row) {
      //                 return DataRow(
      //                   cells: [
      //                     DataCell(Text(row['username'].toString())),
      //                     DataCell(Text(row['phone'])),
      //                     DataCell(Text(row['address'])),
      //                   ],
      //                 );
      //               }).toList(),
      //             ),
      //           ),
    );
  }
}
