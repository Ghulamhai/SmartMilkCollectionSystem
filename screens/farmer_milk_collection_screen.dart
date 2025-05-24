import 'package:flutter/material.dart';

class MilkCollectionPage extends StatefulWidget {
  @override
  _MilkCollectionPageState createState() => _MilkCollectionPageState();
}

class _MilkCollectionPageState extends State<MilkCollectionPage> {
  List<Map<String, String>> milkRecords = [
    {'date': '2025-04-08', 'quantity': '10L', 'fat': '4.5%', 'time': '7:30 AM'},
    {'date': '2025-04-07', 'quantity': '12L', 'fat': '4.2%', 'time': '7:45 AM'},
    {'date': '2025-04-06', 'quantity': '9.5L', 'fat': '4.6%', 'time': '7:35 AM'},
  ];

  DateTime? selectedDate;

  void _showAddMilkDialog() {
    final quantityController = TextEditingController();
    final fatController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Milk Record"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(selectedDate == null
                      ? 'Select Date'
                      : '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2023),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                      Navigator.of(context).pop();
                      _showAddMilkDialog(); // Reopen to show the updated date
                    }
                  },
                ),
                TextField(
                  controller: quantityController,
                  decoration: InputDecoration(labelText: "Quantity (e.g. 10L)"),
                ),
                TextField(
                  controller: fatController,
                  decoration: InputDecoration(labelText: "Fat % (e.g. 4.5)"),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedDate != null &&
                    quantityController.text.isNotEmpty &&
                    fatController.text.isNotEmpty) {
                  final formattedDate =
                      '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';
                  final now = TimeOfDay.now();
                  setState(() {
                    milkRecords.insert(0, {
                      'date': formattedDate,
                      'quantity': quantityController.text,
                      'fat': '${fatController.text}%',
                      'time': now.format(context),
                    });
                    selectedDate = null; // Reset for next time
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Milk Collection")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: milkRecords.length,
        itemBuilder: (context, index) {
          final record = milkRecords[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.local_drink, color: Colors.blue),
              title: Text('Date: ${record['date']} - ${record['time']}'),
              subtitle: Text(
                'Quantity: ${record['quantity']}  |  Fat: ${record['fat']}',
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMilkDialog,
        backgroundColor: Colors.grey[700], // Greyish color
        icon: Icon(Icons.add),
        label: Text('Add Milk'),
        tooltip: 'Add Milk Record',
      ),
    );
  }
}
