import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'distributor_prices_screen.dart';

class FarmerScheduledPickupsScreen extends StatefulWidget {
  const FarmerScheduledPickupsScreen({Key? key}) : super(key: key);

  @override
  State<FarmerScheduledPickupsScreen> createState() =>
      _FarmerScheduledPickupsScreenState();
}

class _FarmerScheduledPickupsScreenState
    extends State<FarmerScheduledPickupsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _scheduledPickups = [];

  @override
  void initState() {
    super.initState();
    _loadScheduledPickups();
  }

  Future<void> _loadScheduledPickups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final querySnapshot =
            await FirebaseFirestore.instance
                .collection('milk_pickups')
                .where('farmer_id', isEqualTo: user.uid)
                .orderBy('pickup_date', descending: false)
                .get();

        final pickups =
            querySnapshot.docs.map((doc) {
              final data = doc.data();

              // Handle different timestamp formats
              DateTime pickupDate;
              if (data['pickup_date'] is Timestamp) {
                pickupDate = (data['pickup_date'] as Timestamp).toDate();
              } else {
                pickupDate = DateTime.now(); // Fallback
              }

              return {
                'id': doc.id,
                'distributor_name':
                    data['distributor_name'] ?? 'Unknown Distributor',
                'distributor_id': data['distributor_id'] ?? '',
                'quantity': data['quantity'] ?? 0.0,
                'base_price': data['base_price'] ?? 0.0,
                'total_amount': data['total_amount'] ?? 0.0,
                'pickup_date': pickupDate,
                'status': data['status'] ?? 'scheduled',
                'cleaning_requested': data['cleaning_requested'] ?? false,
              };
            }).toList();

        setState(() {
          _scheduledPickups = pickups;
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading scheduled pickups: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelPickup(String pickupId) async {
    try {
      await FirebaseFirestore.instance
          .collection('milk_pickups')
          .doc(pickupId)
          .update({
            'status': 'cancelled',
            'updated_at': FieldValue.serverTimestamp(),
          });

      // Refresh the list
      _loadScheduledPickups();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup cancelled successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cancelling pickup: $e')));
    }
  }

  Future<void> _toggleCleaningOption(
    String pickupId,
    bool cleaningRequested,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('milk_pickups')
          .doc(pickupId)
          .update({
            'cleaning_requested': cleaningRequested,
            'updated_at': FieldValue.serverTimestamp(),
          });

      // Refresh the list
      _loadScheduledPickups();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cleaningRequested
                ? 'Container cleaning requested successfully'
                : 'Container cleaning request removed',
          ),
          backgroundColor: cleaningRequested ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating cleaning option: $e')),
      );
    }
  }

  Future<void> _deletePickup(String pickupId) async {
    try {
      // Show confirmation dialog
      bool confirmDelete =
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Delete Pickup'),
                content: const Text(
                  'Are you sure you want to permanently delete this pickup? This action cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            },
          ) ??
          false;

      if (!confirmDelete) return;

      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('milk_pickups')
          .doc(pickupId)
          .delete();

      // Remove from local list
      setState(() {
        _scheduledPickups.removeWhere((pickup) => pickup['id'] == pickupId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup deleted successfully'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting pickup: $e')));
    }
  }

  Future<void> _deleteAllPickups() async {
    try {
      // Show confirmation dialog
      bool confirmDelete =
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Delete All Pickups'),
                content: const Text(
                  'Are you sure you want to permanently delete all pickups? This action cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Delete All',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            },
          ) ??
          false;

      if (!confirmDelete) return;

      // Get all pickup IDs
      final pickupIds =
          _scheduledPickups.map((pickup) => pickup['id'] as String).toList();

      // Delete all pickups in a batch
      final batch = FirebaseFirestore.instance.batch();
      for (String id in pickupIds) {
        batch.delete(
          FirebaseFirestore.instance.collection('milk_pickups').doc(id),
        );
      }
      await batch.commit();

      // Clear local list
      setState(() {
        _scheduledPickups.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All pickups deleted successfully'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting pickups: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Scheduled Pickups'),
        backgroundColor: Colors.green,
        actions: [
          if (_scheduledPickups.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Delete All Pickups',
              onPressed: () => _deleteAllPickups(),
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _scheduledPickups.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No scheduled pickups',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Schedule a pickup with a distributor',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const DistributorPricesScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Schedule New Pickup'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
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

                    bool isPastPickup = pickupDate.isBefore(DateTime.now());
                    bool canCancel =
                        !isPastPickup &&
                        (status == 'scheduled' || status == 'confirmed');

                    return Dismissible(
                      key: Key(pickup['id']),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Delete Pickup'),
                              content: const Text(
                                'Are you sure you want to permanently delete this pickup?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) {
                        _deletePickup(pickup['id']);
                      },
                      child: Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            if (pickup['cleaning_requested'] == true)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.cleaning_services,
                                    color: Colors.blue.shade800,
                                    size: 16,
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        pickup['distributor_name'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: statusColor,
                                            width: 1,
                                          ),
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
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        color: Colors.green.shade700,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Date: ${DateFormat('dd MMM yyyy').format(pickupDate)}',
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        color: Colors.green.shade700,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Time: ${DateFormat('hh:mm a').format(pickupDate)}',
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.water_drop,
                                        color: Colors.green.shade700,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Quantity: ${pickup['quantity']} liters',
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.currency_rupee,
                                        color: Colors.green.shade700,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Price: ₹${pickup['base_price'].toStringAsFixed(2)} per liter',
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.monetization_on,
                                        color: Colors.green.shade700,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Total: ₹${pickup['total_amount'].toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.cleaning_services,
                                        color: Colors.green.shade700,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Container Cleaning: ${pickup['cleaning_requested'] ? 'Requested' : 'Not Requested'}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight:
                                              pickup['cleaning_requested']
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (status ==
                                          'scheduled') // Only allow changes if pickup is still scheduled
                                        TextButton(
                                          onPressed:
                                              () => _toggleCleaningOption(
                                                pickup['id'],
                                                !pickup['cleaning_requested'],
                                              ),
                                          child: Text(
                                            pickup['cleaning_requested']
                                                ? 'Remove'
                                                : 'Add Cleaning',
                                            style: TextStyle(
                                              color:
                                                  pickup['cleaning_requested']
                                                      ? Colors.red
                                                      : Colors.green,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (canCancel)
                                        TextButton.icon(
                                          onPressed:
                                              () => _cancelPickup(pickup['id']),
                                          icon: const Icon(
                                            Icons.cancel,
                                            color: Colors.red,
                                          ),
                                          label: const Text(
                                            'Cancel Pickup',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed:
                                            () => _deletePickup(pickup['id']),
                                        icon: const Icon(
                                          Icons.delete_forever,
                                          color: Colors.red,
                                        ),
                                        label: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DistributorPricesScreen(),
            ),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}
