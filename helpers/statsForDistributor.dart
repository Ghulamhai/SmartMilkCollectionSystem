import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DistributorStatisticsScreen1 extends StatefulWidget {
  const DistributorStatisticsScreen1({Key? key}) : super(key: key);

  @override
  State<DistributorStatisticsScreen1> createState() =>
      _DistributorStatisticsScreenState();
}

class _DistributorStatisticsScreenState
    extends State<DistributorStatisticsScreen1>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currentUser = FirebaseAuth.instance.currentUser;
  String _selectedTimeFilter = 'all';
  List<Map<String, dynamic>> _filteredTransactions = [];
  bool _isLoading = true;

  // Statistics
  double _totalMilk = 0;
  double _totalSpent = 0;
  int _transactionCount = 0;
  Map<String, Map<String, dynamic>> _farmerStats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('transactions')
              .where('distributor_id', isEqualTo: currentUser!.uid)
              .get();

      _filteredTransactions =
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

      _filterTransactionsByTime();
    } catch (e) {
      print('Error loading transactions: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterTransactionsByTime() {
    final now = DateTime.now();
    List<Map<String, dynamic>> filtered = List.from(_filteredTransactions);

    if (_selectedTimeFilter == 'week') {
      final weekAgo = now.subtract(const Duration(days: 7));
      filtered =
          _filteredTransactions.where((t) {
            final timestamp = t['transaction_date'] as Timestamp;
            return timestamp.toDate().isAfter(weekAgo);
          }).toList();
    } else if (_selectedTimeFilter == 'month') {
      final monthAgo = DateTime(now.year, now.month - 1, now.day);
      filtered =
          _filteredTransactions.where((t) {
            final timestamp = t['transaction_date'] as Timestamp;
            return timestamp.toDate().isAfter(monthAgo);
          }).toList();
    } else if (_selectedTimeFilter == 'year') {
      final yearAgo = DateTime(now.year - 1, now.month, now.day);
      filtered =
          _filteredTransactions.where((t) {
            final timestamp = t['transaction_date'] as Timestamp;
            return timestamp.toDate().isAfter(yearAgo);
          }).toList();
    }

    // Calculate statistics
    _totalMilk = 0;
    _totalSpent = 0;
    _transactionCount = filtered.length;
    _farmerStats = {};

    for (var transaction in filtered) {
      final farmerId = transaction['farmer_id'] as String;

      // Fix type casting issues by safely converting to double
      final milkInLitres = _parseToDouble(transaction['quantity']);
      final totalPrice = _parseToDouble(transaction['total_amount']);

      _totalMilk += milkInLitres;
      _totalSpent += totalPrice;

      // Aggregate by farmer
      if (!_farmerStats.containsKey(farmerId)) {
        _farmerStats[farmerId] = {'milk': 0.0, 'spent': 0.0, 'transactions': 0};
      }

      _farmerStats[farmerId]!['milk'] += milkInLitres;
      _farmerStats[farmerId]!['spent'] += totalPrice;
      _farmerStats[farmerId]!['transactions'] += 1;
    }

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  // Helper method to safely parse numeric values to double
  double _parseToDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
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
        backgroundColor: Colors.green.shade700,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Summary'), Tab(text: 'Transactions')],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildTimeFilterButtons(),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildSummaryTab(), _buildTransactionsTab()],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildTimeFilterButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 8),
          _buildFilterButton('week', 'This Week'),
          const SizedBox(width: 8),
          _buildFilterButton('month', 'This Month'),
          const SizedBox(width: 8),
          _buildFilterButton('year', 'This Year'),
          const SizedBox(width: 8),
          _buildFilterButton('all', 'All Time'),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String filterValue, String label) {
    bool isSelected = _selectedTimeFilter == filterValue;

    // Use Material for better touch feedback
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          print("Filter tapped: $filterValue");
          setState(() {
            _selectedTimeFilter = filterValue;
            _filterTransactionsByTime();
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green.shade100 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.green.shade700 : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.green.shade800 : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTab() {
    if (_filteredTransactions.isEmpty) {
      return const Center(
        child: Text('No transactions found for the selected period.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 20),
          const Text(
            'Farmer Breakdown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getFarmerDetails(),
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
  }

  Widget _buildSummaryCard() {
    double avgPrice = _totalMilk > 0 ? _totalSpent / _totalMilk : 0;

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
              '${_totalMilk.toStringAsFixed(2)} Litres',
            ),
            const SizedBox(height: 10),
            _buildStatRow(
              Icons.currency_rupee,
              'Total Amount Paid',
              '₹${_totalSpent.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 10),
            _buildStatRow(
              Icons.receipt_long,
              'Total Transactions',
              '$_transactionCount',
            ),
            const SizedBox(height: 10),
            _buildStatRow(
              Icons.calculate,
              'Average Price Paid',
              '₹${avgPrice.toStringAsFixed(2)}/L',
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getFarmerDetails() async {
    List<Map<String, dynamic>> result = [];

    for (var entry in _farmerStats.entries) {
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
                const Icon(Icons.person, color: Colors.green),
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
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
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
                    backgroundColor: Colors.green.shade100,
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.green,
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
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
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
          Icon(icon, size: 20, color: Colors.green.shade700),
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
                          .where('distributor_id', isEqualTo: currentUser!.uid)
                          .where('farmer_id', isEqualTo: farmerId)
                          .orderBy('transaction_date', descending: true)
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

                        final timestamp =
                            data['transaction_date'] as Timestamp?;
                        final dateString =
                            timestamp != null
                                ? DateFormat(
                                  'dd MMM yyyy, hh:mm a',
                                ).format(timestamp.toDate())
                                : 'Date not available';

                        // Safe conversion of numeric values
                        final quantity = _parseToDouble(data['quantity']);
                        final pricePerLitre = _parseToDouble(
                          data['price_per_liter'],
                        );
                        final totalAmount = _parseToDouble(
                          data['total_amount'],
                        );

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
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${quantity.toStringAsFixed(2)} Litres',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '₹${totalAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Rate: ₹${pricePerLitre.toStringAsFixed(2)}/L',
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
        Icon(icon, size: 20, color: Colors.green.shade700),
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
    if (_filteredTransactions.isEmpty) {
      return const Center(
        child: Text('No transactions found for the selected period.'),
      );
    }

    // Sort transactions by timestamp (newest first)
    _filteredTransactions.sort((a, b) {
      final timestampA = a['transaction_date'] as Timestamp;
      final timestampB = b['transaction_date'] as Timestamp;
      return timestampB.compareTo(timestampA);
    });

    return ListView.builder(
      itemCount: _filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _filteredTransactions[index];

        final timestamp = transaction['transaction_date'] as Timestamp;
        final dateString = DateFormat(
          'dd MMM yyyy, hh:mm a',
        ).format(timestamp.toDate());

        final farmerId = transaction['farmer_id'] as String;

        // Safe conversion of numeric values
        final quantity = _parseToDouble(transaction['quantity']);
        final pricePerLitre = _parseToDouble(transaction['price_per_liter']);
        final totalAmount = _parseToDouble(transaction['total_amount']);

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
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: const Icon(Icons.water_drop, color: Colors.green),
                ),
                title: Text(
                  '${quantity.toStringAsFixed(2)} Litres at ₹${pricePerLitre.toStringAsFixed(2)}/L',
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
                  '₹${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                isThreeLine: true,
                onTap: () {
                  _showTransactionDetails(transaction, farmerName, dateString);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showTransactionDetails(
    Map<String, dynamic> transaction,
    String farmerName,
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
                Text('Transaction ID: ${transaction['id'].substring(0, 8)}...'),
                const SizedBox(height: 10),
                Text('Date: $dateString'),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  'Farmer Information',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text('Name: $farmerName'),
                FutureBuilder<DocumentSnapshot>(
                  future:
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(transaction['farmer_id'])
                          .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Text('Loading farmer details...');
                    }

                    final farmerData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Phone: ${farmerData['phone'] ?? 'N/A'}'),
                        Text('Location: ${farmerData['location'] ?? 'N/A'}'),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  'Transaction Information',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  'Milk Quantity: ${_parseToDouble(transaction['quantity']).toStringAsFixed(2)} Litres',
                ),
                Text(
                  'Price per Litre: ₹${_parseToDouble(transaction['price_per_liter']).toStringAsFixed(2)}',
                ),
                Text(
                  'Total Amount: ₹${_parseToDouble(transaction['total_amount']).toStringAsFixed(2)}',
                ),
                if (transaction['cleaning_requested'] == true) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Cleaning Fee: ₹${_parseToDouble(transaction['cleaning_fee']).toStringAsFixed(2)}',
                  ),
                  const Text(
                    'Container Cleaning: Requested',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
                const SizedBox(height: 5),
                Text(
                  'Receipt Number: ${transaction['receipt_number'] ?? 'N/A'}',
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
