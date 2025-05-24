import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class MilkPriceAndPickupManager extends StatefulWidget {
  const MilkPriceAndPickupManager({Key? key}) : super(key: key);

  @override
  State<MilkPriceAndPickupManager> createState() =>
      _MilkPriceAndPickupManagerState();
}

class _MilkPriceAndPickupManagerState extends State<MilkPriceAndPickupManager> {
  final TextEditingController _priceController = TextEditingController();
  bool _isLoading = true;
  double _currentPrice = 0.0;
  DateTime _lastUpdated = DateTime.now();
  List<Map<String, dynamic>> _scheduledPickups = [];
  String _distributorName = 'Distributor';

  @override
  void initState() {
    super.initState();
    _loadDistributorName();
    _loadCurrentPrice();
    _loadScheduledPickups();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadDistributorName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Try to get the name from the users collection first
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userDoc.exists && userDoc.data()?['name'] != null) {
          setState(() {
            _distributorName = userDoc.data()?['name'];
          });
        } else if (user.displayName != null && user.displayName!.isNotEmpty) {
          setState(() {
            _distributorName = user.displayName!;
          });
        }
      }
    } catch (e) {
      print('Error loading distributor name: $e');
      // Continue with default name if there's an error
    }
  }

  Future<void> _loadCurrentPrice() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docSnapshot =
            await FirebaseFirestore.instance
                .collection('milk_prices')
                .doc(user.uid)
                .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          setState(() {
            _currentPrice = (data?['base_price'] ?? 0.0).toDouble();
            // Handle the Timestamp null issue
            if (data?['updated_at'] != null) {
              _lastUpdated = (data?['updated_at'] as Timestamp).toDate();
            } else {
              _lastUpdated = DateTime.now();
            }
            _priceController.text = _currentPrice.toString();

            // Update distributor name if it exists in the document
            if (data?['distributor_name'] != null &&
                data?['distributor_name'] != 'Distributor') {
              _distributorName = data?['distributor_name'];
            }
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading price: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadScheduledPickups() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Create a composite index for this query in Firebase console
        final querySnapshot =
            await FirebaseFirestore.instance
                .collection('milk_pickups')
                .where('distributor_id', isEqualTo: user.uid)
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
            // Default to current date if format is unknown
            dateTime = DateTime.now();
          }

          // Only include future pickups or pickups from the last 30 days
          final thirtyDaysAgo = DateTime.now().subtract(
            const Duration(days: 30),
          );
          if (dateTime.isAfter(thirtyDaysAgo)) {
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
            });
          }
        }

        // Sort by pickup date
        pickups.sort(
          (a, b) => (a['pickup_date'] as DateTime).compareTo(
            b['pickup_date'] as DateTime,
          ),
        );

        setState(() {
          _scheduledPickups = pickups;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading scheduled pickups: $e')),
      );
    }
  }

  Future<void> _updateMilkPrice() async {
    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final newPrice = double.parse(_priceController.text);

        // Ensure we have the most up-to-date distributor name
        await _loadDistributorName();

        await FirebaseFirestore.instance
            .collection('milk_prices')
            .doc(user.uid)
            .set({
              'base_price': newPrice,
              'distributor_id': user.uid,
              'distributor_name': _distributorName,
              'updated_at': FieldValue.serverTimestamp(),
            });

        setState(() {
          _currentPrice = newPrice;
          _lastUpdated = DateTime.now();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Milk price updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating price: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePickupStatus(String pickupId, String newStatus) async {
    try {
      // Update pickup status
      await FirebaseFirestore.instance
          .collection('milk_pickups')
          .doc(pickupId)
          .update({
            'status': newStatus,
            'updated_at': FieldValue.serverTimestamp(),
          });

      // If status is "completed", create a transaction record
      if (newStatus == 'completed') {
        // Get the pickup details
        final pickupDoc =
            await FirebaseFirestore.instance
                .collection('milk_pickups')
                .doc(pickupId)
                .get();

        if (pickupDoc.exists) {
          final pickupData = pickupDoc.data()!;

          // Create transaction record
          await FirebaseFirestore.instance.collection('transactions').add({
            'farmer_id': pickupData['farmer_id'],
            'distributor_id': pickupData['distributor_id'],
            'pickup_id': pickupId,
            'farmer_name': pickupData['farmer_name'],
            'distributor_name': pickupData['distributor_name'],
            'quantity': pickupData['quantity'],
            'price_per_liter': pickupData['base_price'],
            'cleaning_fee':
                pickupData['cleaning_requested'] == true
                    ? (pickupData['cleaning_fee'] ?? 20.0)
                    : 0.0,
            'total_amount': pickupData['total_amount'],
            'transaction_date': FieldValue.serverTimestamp(),
            'payment_status':
                'paid', // Default to paid, you can modify this as needed
            'payment_method': 'cash', // Default, can be modified
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
        }
      } else {
        // Show regular status update message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pickup status updated to $newStatus')),
        );
      }

      // Refresh the list after updating
      _loadScheduledPickups();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating pickup status: $e')),
      );
    }
  }

  Future<void> _openLocationInMaps(String location) async {
    if (location.isEmpty) return;

    try {
      // Parse the location string to get latitude and longitude
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

  Widget _buildFarmerLocationSection(Map<String, dynamic> pickup) {
    if (pickup['farmer_location'] == null ||
        pickup['farmer_location'].isEmpty) {
      return const SizedBox.shrink();
    }

    // Parse location string into latitude and longitude
    final locationParts = pickup['farmer_location'].split(',');
    if (locationParts.length != 2) {
      return const SizedBox.shrink();
    }

    final latitude = double.tryParse(locationParts[0].trim());
    final longitude = double.tryParse(locationParts[1].trim());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        const Text(
          'Pickup Location',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pickup['formatted_address'] != null &&
                  pickup['formatted_address'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.blue.shade700,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pickup['formatted_address'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Icon(
                    Icons.my_location,
                    color: Colors.blue.shade700,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Coordinates: ${latitude?.toStringAsFixed(6)}, ${longitude?.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _openLocationInMaps(pickup['farmer_location']),
          icon: const Icon(Icons.directions),
          label: const Text('Get Directions'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 40),
          ),
        ),
      ],
    );
  }

  void _navigateToTransactionHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DistributorTransactionHistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Milk Price & Pickups'),
          backgroundColor: Colors.green.shade700,
          actions: [
            IconButton(
              icon: const Icon(Icons.receipt_long),
              tooltip: 'Transaction History',
              onPressed: _navigateToTransactionHistory,
            ),
          ],
          bottom: const TabBar(
            tabs: [Tab(text: 'Set Milk Price'), Tab(text: 'Scheduled Pickups')],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [_buildPriceSettingTab(), _buildScheduledPickupsTab()],
        ),
      ),
    );
  }

  Widget _buildPriceSettingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Current Milk Base Price',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Distributor: $_distributorName',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Base Price:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '₹${_currentPrice.toStringAsFixed(2)} per liter',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Last Updated: ${DateFormat('dd MMM yyyy, hh:mm a').format(_lastUpdated)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Update Milk Base Price',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Base Price (₹ per liter)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateMilkPrice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text(
                                'Update Price',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pricing Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The base price is the minimum price per liter of milk. Farmers will see this rate when scheduling milk pickups.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledPickupsTab() {
    return _scheduledPickups.isEmpty
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hourglass_empty,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No scheduled pickups yet',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                'Farmers will schedule pickups once you set your prices',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        )
        : RefreshIndicator(
          onRefresh: _loadScheduledPickups,
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _scheduledPickups.length,
            itemBuilder: (context, index) {
              final pickup = _scheduledPickups[index];
              final pickupDate = pickup['pickup_date'] as DateTime;
              final status = pickup['status'] as String;

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
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  title: Text(
                    pickup['farmer_name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    '${DateFormat('dd MMM yyyy, hh:mm a').format(pickupDate)} • ${pickup['quantity']} liters',
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
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
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Date: ${DateFormat('dd MMM yyyy').format(pickupDate)}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Time: ${DateFormat('hh:mm a').format(pickupDate)}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.water_drop, size: 16),
                              const SizedBox(width: 8),
                              Text('Quantity: ${pickup['quantity']} liters'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.currency_rupee, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Price: ₹${pickup['base_price'].toStringAsFixed(2)} per liter',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.monetization_on, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Total Amount: ₹${pickup['total_amount'].toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (pickup['farmer_phone'] != null &&
                              pickup['farmer_phone'].isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 16),
                                const SizedBox(width: 8),
                                Text('Phone: ${pickup['farmer_phone']}'),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: () {
                                    // Implement call functionality
                                    final uri = Uri.parse(
                                      'tel:${pickup['farmer_phone']}',
                                    );
                                    launchUrl(uri);
                                  },
                                  icon: const Icon(Icons.call, size: 16),
                                  label: const Text('Call'),
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        Colors.green, // Updated from primary
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (pickup['cleaning_requested'] == true) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.cleaning_services, size: 16),
                                const SizedBox(width: 8),
                                const Text(
                                  'Container Cleaning: Requested',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],

                          // Add the location section
                          _buildFarmerLocationSection(pickup),

                          const SizedBox(height: 16),
                          const Text(
                            'Update Status:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (status != 'confirmed' &&
                                  status != 'completed' &&
                                  status != 'cancelled')
                                ElevatedButton.icon(
                                  onPressed:
                                      () => _updatePickupStatus(
                                        pickup['id'],
                                        'confirmed',
                                      ),
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('Confirm'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor:
                                        Colors.white, // Updated from primary
                                  ),
                                ),
                              if (status == 'confirmed')
                                ElevatedButton.icon(
                                  onPressed:
                                      () => _updatePickupStatus(
                                        pickup['id'],
                                        'completed',
                                      ),
                                  icon: const Icon(Icons.done_all),
                                  label: const Text('Complete'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor:
                                        Colors.white, // Updated from primary
                                  ),
                                ),
                              if (status != 'cancelled' &&
                                  status != 'completed')
                                ElevatedButton.icon(
                                  onPressed:
                                      () => _updatePickupStatus(
                                        pickup['id'],
                                        'cancelled',
                                      ),
                                  icon: const Icon(Icons.cancel),
                                  label: const Text('Cancel'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor:
                                        Colors.white, // Updated from primary
                                  ),
                                ),
                            ],
                          ),
                          if (status == 'completed') ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade700,
                                  ),
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
            },
          ),
        );
  }
}

// Transaction History Screen for Distributors
class DistributorTransactionHistoryScreen extends StatefulWidget {
  const DistributorTransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<DistributorTransactionHistoryScreen> createState() =>
      _DistributorTransactionHistoryScreenState();
}

class _DistributorTransactionHistoryScreenState
    extends State<DistributorTransactionHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  double _totalSpent = 0.0;
  int _totalTransactions = 0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final querySnapshot =
            await FirebaseFirestore.instance
                .collection('transactions')
                .where('distributor_id', isEqualTo: user.uid)
                .orderBy('transaction_date', descending: true)
                .get();

        final transactions =
            querySnapshot.docs.map((doc) {
              final data = doc.data();

              // Handle different timestamp formats
              DateTime transactionDate;
              if (data['transaction_date'] is Timestamp) {
                transactionDate =
                    (data['transaction_date'] as Timestamp).toDate();
              } else {
                transactionDate = DateTime.now(); // Fallback
              }

              return {
                'id': doc.id,
                'farmer_name': data['farmer_name'] ?? 'Unknown Farmer',
                'farmer_id': data['farmer_id'] ?? '',
                'quantity': data['quantity'] ?? 0.0,
                'price_per_liter': data['price_per_liter'] ?? 0.0,
                'cleaning_fee': data['cleaning_fee'] ?? 0.0,
                'total_amount': data['total_amount'] ?? 0.0,
                'transaction_date': transactionDate,
                'payment_status': data['payment_status'] ?? 'unknown',
                'receipt_number': data['receipt_number'] ?? '',
              };
            }).toList();

        // Calculate totals
        double totalSpent = 0.0;
        for (var transaction in transactions) {
          totalSpent += transaction['total_amount'];
        }

        setState(() {
          _transactions = transactions;
          _totalSpent = totalSpent;
          _totalTransactions = transactions.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading transactions: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: Colors.green.shade700,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _buildSummaryCard(),
                  Expanded(
                    child:
                        _transactions.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No transactions yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : RefreshIndicator(
                              onRefresh: _loadTransactions,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16.0),
                                itemCount: _transactions.length,
                                itemBuilder: (context, index) {
                                  return _buildTransactionCard(
                                    _transactions[index],
                                  );
                                },
                              ),
                            ),
                  ),
                ],
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
              'Transaction Summary',
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
                      _totalTransactions.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Total Transactions'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '₹${_totalSpent.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Total Amount'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final transactionDate = transaction['transaction_date'] as DateTime;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  transaction['farmer_name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${transaction['total_amount'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(transactionDate),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        transaction['payment_status'] == 'paid'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          transaction['payment_status'] == 'paid'
                              ? Colors.green
                              : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    transaction['payment_status'].toUpperCase(),
                    style: TextStyle(
                      color:
                          transaction['payment_status'] == 'paid'
                              ? Colors.green
                              : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Quantity:'),
                Text('${transaction['quantity']} liters'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Price per liter:'),
                Text('₹${transaction['price_per_liter'].toStringAsFixed(2)}'),
              ],
            ),
            if (transaction['cleaning_fee'] > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cleaning fee:'),
                  Text('₹${transaction['cleaning_fee'].toStringAsFixed(2)}'),
                ],
              ),
            ],
            const SizedBox(height: 8),
            if (transaction['receipt_number'].isNotEmpty)
              Text(
                'Receipt: ${transaction['receipt_number']}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
          ],
        ),
      ),
    );
  }
}
