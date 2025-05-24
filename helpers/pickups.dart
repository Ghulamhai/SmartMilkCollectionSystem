

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

// Import the route navigation screen
// Update this import path to match your project structure
import 'PickupRouteNavigationScreen.dart';

class ConfirmedPickupsScreen extends StatefulWidget {
  const ConfirmedPickupsScreen({Key? key}) : super(key: key);

  @override
  State<ConfirmedPickupsScreen> createState() => _ConfirmedPickupsScreenState();
}

class _ConfirmedPickupsScreenState extends State<ConfirmedPickupsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _confirmedPickups = [];
  int _completedPickups = 0;
  int _totalPickups = 0;

  @override
  void initState() {
    super.initState();
    _loadConfirmedPickups();
  }

  Future<void> _loadConfirmedPickups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Query all confirmed pickups for this distributor
        final querySnapshot =
            await FirebaseFirestore.instance
                .collection('milk_pickups')
                .where('distributor_id', isEqualTo: user.uid)
                .where('status', isEqualTo: 'confirmed')
                .get();

        final List<Map<String, dynamic>> pickups = [];

        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          final pickupDate = data['pickup_date'];

          // Handle different timestamp formats
          DateTime dateTime;
          if (pickupDate is Timestamp) {
            dateTime = pickupDate.toDate();
          } else if (pickupDate is String) {
            dateTime = DateTime.parse(pickupDate);
          } else {
            dateTime = DateTime.now();
          }

          pickups.add({
            'id': doc.id,
            'farmer_name': data['farmer_name'] ?? 'Unknown Farmer',
            'farmer_id': data['farmer_id'] ?? '',
            'farmer_phone': data['farmer_phone'] ?? '',
            'farmer_location': data['farmer_location'] ?? '',
            'formatted_address': data['formatted_address'] ?? '',
            'quantity': data['quantity'] ?? 0.0,
            'base_price': data['base_price'] ?? 0.0,
            'total_amount': data['total_amount'] ?? 0.0,
            'pickup_date': dateTime,
            'status': data['status'] ?? 'scheduled',
            'cleaning_requested': data['cleaning_requested'] ?? false,
            'cleaning_fee': data['cleaning_fee'] ?? 0.0,
            'distributor_name': data['distributor_name'] ?? '',
            'farmer_email': data['farmer_email'] ?? '',
          });
        }

        // Sort by pickup date (upcoming first)
        pickups.sort(
          (a, b) => (a['pickup_date'] as DateTime).compareTo(
            b['pickup_date'] as DateTime,
          ),
        );

        // Count completed pickups
        int completed =
            pickups.where((pickup) => pickup['status'] == 'completed').length;

        setState(() {
          _confirmedPickups = pickups;
          _completedPickups = completed;
          _totalPickups = pickups.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading confirmed pickups: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markPickupAsCompleted(
    String pickupId,
    Map<String, dynamic> pickup,
  ) async {
    try {
      // Update pickup status
      await FirebaseFirestore.instance
          .collection('milk_pickups')
          .doc(pickupId)
          .update({
            'status': 'completed',
            'updated_at': FieldValue.serverTimestamp(),
          });

      // Create transaction record
      await FirebaseFirestore.instance.collection('transactions').add({
        'farmer_id': pickup['farmer_id'],
        'distributor_id': FirebaseAuth.instance.currentUser?.uid,
        'pickup_id': pickupId,
        'farmer_name': pickup['farmer_name'],
        'distributor_name': pickup['distributor_name'] ?? '',
        'quantity': pickup['quantity'],
        'price_per_liter': pickup['base_price'],
        'cleaning_fee':
            pickup['cleaning_requested'] == true
                ? (pickup['cleaning_fee'] ?? 20.0)
                : 0.0,
        'total_amount': pickup['total_amount'],
        'transaction_date': FieldValue.serverTimestamp(),
        'payment_status': 'paid',
        'payment_method': 'cash',
        'transaction_notes': '',
        'receipt_number':
            'RCT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup completed and transaction recorded'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the list
      _loadConfirmedPickups();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error completing pickup: $e')));
    }
  }

  Future<void> _openLocationInMaps(String location) async {
    if (location.isEmpty) return;

    try {
      final locationParts = location.split(',');
      if (locationParts.length == 2) {
        final latitude = double.tryParse(locationParts[0].trim());
        final longitude = double.tryParse(locationParts[1].trim());

        if (latitude != null && longitude != null) {
          final url =
              'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open maps application')),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening location: $e')));
    }
  }

  Future<void> _callFarmer(String phone) async {
    if (phone.isEmpty) return;

    try {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not make a call')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error making call: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmed Pickup Schedule'),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConfirmedPickups,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _buildSummaryCard(),
                  Expanded(
                    child:
                        _confirmedPickups.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No confirmed pickups found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Check back later or confirm pending pickups',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : RefreshIndicator(
                              onRefresh: _loadConfirmedPickups,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16.0),
                                itemCount: _confirmedPickups.length,
                                itemBuilder: (context, index) {
                                  return _buildPickupCard(
                                    _confirmedPickups[index],
                                  );
                                },
                              ),
                            ),
                  ),
                ],
              ),
      // Add floating action button to navigate to the route screen
      floatingActionButton:
          _confirmedPickups.isEmpty
              ? null
              : FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => PickupRouteNavigationScreen(
                            pickups: _confirmedPickups,
                          ),
                    ),
                  );
                },
                label: const Text('View Route'),
                icon: const Icon(Icons.map),
                backgroundColor: Colors.green,
              ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Confirmed Pickups',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      _totalPickups.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Total Pickups'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      _completedPickups.toString(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color:
                            _completedPickups == _totalPickups &&
                                    _totalPickups > 0
                                ? Colors.green
                                : null,
                      ),
                    ),
                    const Text('Completed'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      (_totalPickups - _completedPickups).toString(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color:
                            _totalPickups - _completedPickups > 0
                                ? Colors.orange
                                : Colors.grey,
                      ),
                    ),
                    const Text('Remaining'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupCard(Map<String, dynamic> pickup) {
    final pickupTime = pickup['pickup_date'] as DateTime;
    final status = pickup['status'] as String;
    final isCompleted = status == 'completed';
    final isCancelled = status == 'cancelled';

    Color statusColor;
    switch (status) {
      case 'scheduled':
        statusColor = Colors.blue;
        break;
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'completed':
        statusColor = Colors.purple;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  DateFormat('hh:mm a').format(pickupTime),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (!isCompleted && !isCancelled)
                  ElevatedButton.icon(
                    onPressed:
                        () => _markPickupAsCompleted(pickup['id'], pickup),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Farmer Info Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      radius: 24,
                      child: Text(
                        pickup['farmer_name'].substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pickup['farmer_name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          if (pickup['farmer_phone'] != null &&
                              pickup['farmer_phone'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.phone,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    pickup['farmer_phone'],
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed:
                                        () =>
                                            _callFarmer(pickup['farmer_phone']),
                                    icon: const Icon(Icons.call, size: 14),
                                    label: const Text('Call'),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 0,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (pickup['farmer_email'] != null &&
                              pickup['farmer_email'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.email,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    pickup['farmer_email'],
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24),

                // Pickup Date Section
                Row(
                  children: [
                    Icon(Icons.event, size: 16, color: Colors.orange.shade800),
                    const SizedBox(width: 8),
                    Text(
                      'Scheduled for: ${DateFormat('EEE, MMM d, yyyy').format(pickupTime)}',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Pickup Details Section
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            Icons.water_drop,
                            'Quantity',
                            '${pickup['quantity']} liters',
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            Icons.currency_rupee,
                            'Price',
                            '₹${pickup['base_price'].toStringAsFixed(2)}/liter',
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            Icons.monetization_on,
                            'Total',
                            '₹${pickup['total_amount'].toStringAsFixed(2)}',
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (pickup['cleaning_requested'] == true)
                            _buildDetailRow(
                              Icons.cleaning_services,
                              'Cleaning',
                              'Requested (₹${pickup['cleaning_fee'].toStringAsFixed(2)})',
                              textColor: Colors.blue.shade700,
                            ),
                          const SizedBox(height: 8),
                          if (pickup['formatted_address'] != null &&
                              pickup['formatted_address'].isNotEmpty)
                            _buildDetailRow(
                              Icons.location_on,
                              'Location',
                              pickup['formatted_address'],
                              maxLines: 2,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (pickup['farmer_location'] != null &&
                    pickup['farmer_location'].isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed:
                        () => _openLocationInMaps(pickup['farmer_location']),
                    icon: const Icon(Icons.directions),
                    label: const Text('Get Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ],

                if (isCompleted) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'This pickup has been completed and a transaction record has been created.',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isBold = false,
    int maxLines = 1,
    Color? textColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: textColor,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
