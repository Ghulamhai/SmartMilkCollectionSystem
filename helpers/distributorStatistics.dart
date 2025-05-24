import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DistributorStatisticsScreen extends StatefulWidget {
  const DistributorStatisticsScreen({Key? key}) : super(key: key);

  @override
  State<DistributorStatisticsScreen> createState() =>
      _DistributorStatisticsScreenState();
}

class _DistributorStatisticsScreenState
    extends State<DistributorStatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('You must be logged in to view statistics')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Distribution Statistics'),
        backgroundColor: Colors.blue,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Summary'), Tab(text: 'Transactions')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSummaryTab(), _buildTransactionsTab()],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('transactions')
              .where('distributorId', isEqualTo: currentUser!.uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No transactions found.'));
        }

        // Calculate total statistics
        double totalMilk = 0;
        double totalSpent = 0;
        Map<String, Map<String, dynamic>> farmerStats = {};

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final farmerId = data['farmerId'] as String;
          final milkInLitres = data['milkInLitres'] as double;
          final totalPrice = data['totalPrice'] as double;

          totalMilk += milkInLitres;
          totalSpent += totalPrice;

          // Aggregate by farmer
          if (!farmerStats.containsKey(farmerId)) {
            farmerStats[farmerId] = {
              'milk': 0.0,
              'spent': 0.0,
              'transactions': 0,
            };
          }

          farmerStats[farmerId]!['milk'] += milkInLitres;
          farmerStats[farmerId]!['spent'] += totalPrice;
          farmerStats[farmerId]!['transactions'] += 1;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(
                totalMilk,
                totalSpent,
                snapshot.data!.docs.length,
              ),
              const SizedBox(height: 20),
              const Text(
                'Farmer Breakdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _getFarmerDetails(farmerStats),
                builder: (context, farmerSnapshot) {
                  if (!farmerSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: farmerSnapshot.data!.length,
                    itemBuilder: (context, index) {
                      final farmer = farmerSnapshot.data![index];
                      return _buildFarmerCard(farmer);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getFarmerDetails(
    Map<String, Map<String, dynamic>> farmerStats,
  ) async {
    List<Map<String, dynamic>> result = [];

    for (var entry in farmerStats.entries) {
      final farmerId = entry.key;
      final stats = entry.value;

      // Get farmer details
      final farmerDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(farmerId)
              .get();

      if (farmerDoc.exists) {
        final farmerData = farmerDoc.data()!;
        result.add({
          'id': farmerId,
          'name': farmerData['name'] ?? 'Unknown',
          'phone': farmerData['phone'] ?? 'N/A',
          'location': farmerData['location'] ?? 'N/A',
          'milk': stats['milk'],
          'spent': stats['spent'],
          'transactions': stats['transactions'],
        });
      }
    }

    return result;
  }

  // Future<List<Map<String, dynamic>>> _getFarmerDetails(Map<String, Map<String, dynamic>> farmerStats) async {
  //   List<Map<String, dynamic>> result = [];

  //   for (var entry in farmerStats.entries) {
  //     final farmerId = entry.key;
  //     final stats = entry.value;

  //     // Get farmer details
  //     final farmerDoc = await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(farmerId)
  //         .get();

  //     if (farmerDoc.exists) {
  //       final farmerData = farmerDoc.data()!;
  //       String address = 'Unknown';

  //       // Check if location exists and is a string
  //       if (farmerData['location'] != null && farmerData['location'] is String) {
  //         final location = farmerData['location'] as String;
  //         // Split the string into latitude and longitude
  //         final parts = location.split(',').map((s) => s.trim()).toList();
  //         if (parts.length == 2) {
  //           try {
  //             final latitude = double.parse(parts[0]);
  //             final longitude = double.parse(parts[1]);
  //             List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
  //             if (placemarks.isNotEmpty) {
  //               Placemark placemark = placemarks.first;
  //               address = [
  //                 placemark.street,
  //                 placemark.locality,
  //                 placemark.administrativeArea,
  //                 placemark.country
  //               ].where((e) => e != null && e.isNotEmpty).join(', ');
  //             }
  //           } catch (e) {
  //             address = 'Failed to get address';
  //           }
  //         }
  //       }

  //       result.add({
  //         'id': farmerId,
  //         'name': farmerData['name'] ?? 'Unknown',
  //         'phone': farmerData['phone'] ?? 'N/A',
  //         'location': address,
  //         'milk': stats['milk'],
  //         'spent': stats['spent'],
  //         'transactions': stats['transactions'],
  //       });
  //     }
  //   }

  //   return result;
  // }

  Widget _buildSummaryCard(
    double totalMilk,
    double totalSpent,
    int transactionCount,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Distribution Statistics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 10),
            _buildStatRow(
              Icons.water_drop,
              'Total Milk Collected',
              '${totalMilk.toStringAsFixed(2)} Litres',
            ),
            const SizedBox(height: 10),
            _buildStatRow(
              Icons.currency_rupee,
              'Total Amount Paid',
              '₹${totalSpent.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 10),
            _buildStatRow(
              Icons.receipt_long,
              'Total Transactions',
              '$transactionCount',
            ),
            const SizedBox(height: 10),
            _buildStatRow(
              Icons.calculate,
              'Average Price Paid',
              '₹${(totalSpent / totalMilk).toStringAsFixed(2)}/L',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmerCard(Map<String, dynamic> farmer) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    farmer['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildStatRow(
              Icons.water_drop,
              'Milk Collected',
              '${farmer['milk'].toStringAsFixed(2)} Litres',
            ),
            const SizedBox(height: 6),
            _buildStatRow(
              Icons.currency_rupee,
              'Total Paid',
              '₹${farmer['spent'].toStringAsFixed(2)}',
            ),
            const SizedBox(height: 6),
            _buildStatRow(
              Icons.receipt_long,
              'Transactions',
              '${farmer['transactions']}',
            ),
            const SizedBox(height: 6),
            _buildStatRow(Icons.phone, 'Contact', farmer['phone']),
            const SizedBox(height: 6),
            _buildStatRow(Icons.location_on, 'Location', farmer['location']),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _showFarmerDetails(farmer);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 36),
              ),
              child: const Text('View Detailed Profile'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFarmerDetails(Map<String, dynamic> farmer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farmer['name'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Farmer ID: ${farmer['id'].substring(0, 8)}...',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                'Contact Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.phone, 'Phone', farmer['phone']),
              _buildDetailRow(
                Icons.location_on,
                'Location',
                farmer['location'],
              ),
              const SizedBox(height: 20),
              const Text(
                'Transaction Summary',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildDetailRow(
                Icons.water_drop,
                'Total Milk Collected',
                '${farmer['milk'].toStringAsFixed(2)} Litres',
              ),
              _buildDetailRow(
                Icons.currency_rupee,
                'Total Amount Paid',
                '₹${farmer['spent'].toStringAsFixed(2)}',
              ),
              _buildDetailRow(
                Icons.receipt_long,
                'Number of Transactions',
                '${farmer['transactions']}',
              ),
              _buildDetailRow(
                Icons.calculate,
                'Average Price Paid',
                '₹${(farmer['spent'] / farmer['milk']).toStringAsFixed(2)}/L',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showFarmerTransactions(farmer['id']);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: const Text('View All Transactions'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showFarmerTransactions(String farmerId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Transaction History',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('transactions')
                          .where('distributorId', isEqualTo: currentUser!.uid)
                          .where('farmerId', isEqualTo: farmerId)
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('No transactions found.'),
                      );
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final timestamp = data['timestamp'] as Timestamp?;
                        final dateString =
                            timestamp != null
                                ? DateFormat(
                                  'dd MMM yyyy, hh:mm a',
                                ).format(timestamp.toDate())
                                : 'Date not available';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Transaction ID: ${doc.id.substring(0, 8)}...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      dateString,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.water_drop,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${data['milkInLitres'].toStringAsFixed(2)} Litres',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '₹${data['totalPrice'].toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Rate: ₹${data['pricePerLitre'].toStringAsFixed(2)}/L',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTransactionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('transactions')
              .where('distributorId', isEqualTo: currentUser!.uid)
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No transactions found.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final timestamp = data['timestamp'] as Timestamp?;
            final dateString =
                timestamp != null
                    ? DateFormat(
                      'dd MMM yyyy, hh:mm a',
                    ).format(timestamp.toDate())
                    : 'Date not available';

            final farmerId = data['farmerId'] as String;

            return FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(farmerId)
                      .get(),
              builder: (context, farmerSnapshot) {
                String farmerName = 'Loading...';

                if (farmerSnapshot.hasData && farmerSnapshot.data!.exists) {
                  final farmerData =
                      farmerSnapshot.data!.data() as Map<String, dynamic>;
                  farmerName = farmerData['name'] ?? 'Unknown';
                }

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: const Icon(Icons.water_drop, color: Colors.blue),
                    ),
                    title: Text(
                      '${data['milkInLitres'].toStringAsFixed(2)} Litres at ₹${data['pricePerLitre'].toStringAsFixed(2)}/L',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('From: $farmerName'),
                        Text('Date: $dateString'),
                      ],
                    ),
                    trailing: Text(
                      '₹${data['totalPrice'].toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    isThreeLine: true,
                    onTap: () {
                      if (farmerSnapshot.hasData &&
                          farmerSnapshot.data!.exists) {
                        final farmerData =
                            farmerSnapshot.data!.data() as Map<String, dynamic>;
                        _showTransactionDetails(
                          data,
                          farmerData,
                          doc.id,
                          dateString,
                        );
                      }
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showTransactionDetails(
    Map<String, dynamic> transaction,
    Map<String, dynamic> farmerData,
    String transactionId,
    String dateString,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Transaction Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Transaction ID: ${transactionId.substring(0, 8)}...'),
                const SizedBox(height: 10),
                Text('Date: $dateString'),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  'Farmer Information',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text('Name: ${farmerData['name'] ?? 'Unknown'}'),
                Text('Phone: ${farmerData['phone'] ?? 'N/A'}'),
                Text('Location: ${farmerData['location'] ?? 'N/A'}'),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  'Transaction Information',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  'Milk Quantity: ${transaction['milkInLitres'].toStringAsFixed(2)} Litres',
                ),
                Text(
                  'Price per Litre: ₹${transaction['pricePerLitre'].toStringAsFixed(2)}',
                ),
                Text(
                  'Total Amount: ₹${transaction['totalPrice'].toStringAsFixed(2)}',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
