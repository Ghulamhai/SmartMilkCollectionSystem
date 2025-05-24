import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RouteScreen extends StatelessWidget {
  const RouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> dummyStops = [
      {
        'name': 'Ramesh Patil',
        'status': 'Pending',
        'lat': 18.5204,
        'lng': 73.8567,
        'stopNumber': 1,
      },
      {
        'name': 'Sita Deshmukh',
        'status': 'Collected',
        'lat': 18.5300,
        'lng': 73.8550,
        'stopNumber': 2,
      },
      {
        'name': 'Vijay Kale',
        'status': 'Pending',
        'lat': 18.5402,
        'lng': 73.8600,
        'stopNumber': 3,
      },
    ];

    int totalStops = dummyStops.length;
    int completed = dummyStops.where((s) => s['status'] == 'Collected').length;
    double progress = completed / totalStops;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Route'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Route Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    color: Colors.green,
                    backgroundColor: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 12),
                Text('$completed / $totalStops')
              ],
            ),
            const SizedBox(height: 20),
            const Text('Stops:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: dummyStops.length,
                itemBuilder: (context, index) {
                  final stop = dummyStops[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: stop['status'] == 'Collected' ? Colors.green.shade100 : Colors.orange.shade100,
                        child: Icon(
                          stop['status'] == 'Collected' ? Icons.check : Icons.hourglass_empty,
                          color: stop['status'] == 'Collected' ? Colors.green : Colors.orange,
                        ),
                      ),
                      title: Text('Stop ${stop['stopNumber']} - ${stop['name']}'),
                      subtitle: Text('Status: ${stop['status']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.navigation, color: Colors.blue),
                        onPressed: () => _openGoogleMaps(stop['lat'], stop['lng']),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openGoogleMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
