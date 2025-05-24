import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('dd MMM yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections Overview'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today - $today',
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 16),
            _buildSummaryCards(),
            const SizedBox(height: 20),
            const Text('Recent Collections',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildCollectionList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard('Milk Collected', '140 L', Icons.local_drink),
        _buildStatCard('Stops Visited', '4', Icons.pin_drop),
        _buildStatCard('Pending', '1', Icons.pending_actions),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: Colors.green, size: 30),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionList() {
    final dummyCollections = [
      {'name': 'Ramesh Patil', 'quantity': '35L', 'time': '9:15 AM', 'status': 'Collected'},
      {'name': 'Sita Deshmukh', 'quantity': '-', 'time': '-', 'status': 'Pending'},
      {'name': 'Vijay Kale', 'quantity': '40L', 'time': '10:45 AM', 'status': 'Collected'},
      {'name': 'Anita Shinde', 'quantity': '65L', 'time': '11:30 AM', 'status': 'Collected'},
    ];

    return Column(
      children: dummyCollections.map((entry) {
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: Icon(
              entry['status'] == 'Collected' ? Icons.check_circle : Icons.hourglass_bottom,
              color: entry['status'] == 'Collected' ? Colors.green : Colors.orange,
            ),
            title: Text(entry['name'] ?? ''),
            subtitle: Text(
              entry['status'] == 'Collected'
                  ? 'Collected ${entry['quantity']} at ${entry['time']}'
                  : 'Pending collection',
              style: const TextStyle(fontSize: 14),
            ),
            trailing: Text(entry['status'] ?? '',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: entry['status'] == 'Collected' ? Colors.green : Colors.orange,
                )),
          ),
        );
      }).toList(),
    );
  }
}
