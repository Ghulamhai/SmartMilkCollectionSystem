import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DistributorStatisticsScreen extends StatefulWidget {
  final String distributorId;

  const DistributorStatisticsScreen({
    Key? key,
    required this.distributorId,
  }) : super(key: key);

  @override
  State<DistributorStatisticsScreen> createState() => _DistributorStatisticsScreenState();
}

class _DistributorStatisticsScreenState extends State<DistributorStatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _distributorData;
  String _selectedTimeFilter = 'all';
  
  // Statistics
  double _totalMilk = 0;
  double _totalSpent = 0;
  int _transactionCount = 0;
  Map<String, Map<String, dynamic>> _farmerStats = {};
  List<Map<String, dynamic>> _transactions = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDistributorData();
    _loadTransactions();
  }
  
  Future<void> _loadDistributorData() async {
    try {
      final distributorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.distributorId)
          .get();
          
      if (distributorDoc.exists) {
        setState(() {
          _distributorData = distributorDoc.data();
        });
      }
    } catch (e) {
      print('Error loading distributor data: $e');
    }
  }
  
  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('distributorId', isEqualTo: widget.distributorId)
          .get();
          
      List<Map<String, dynamic>> transactions = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        transactions.add(data);
      }
      
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
      
      _filterTransactionsByTime();
    } catch (e) {
      print('Error loading transactions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _filterTransactionsByTime() {
    final now = DateTime.now();
    List<Map<String, dynamic>> filtered = List.from(_transactions);
    
    if (_selectedTimeFilter == 'week') {
      final weekAgo = now.subtract(const Duration(days: 7));
      filtered = _transactions.where((t) {
        final timestamp = t['timestamp'] as Timestamp?;
        if (timestamp == null) return false;
        return timestamp.toDate().isAfter(weekAgo);
      }).toList();
    } else if (_selectedTimeFilter == 'month') {
      final monthAgo = DateTime(now.year, now.month - 1, now.day);
      filtered = _transactions.where((t) {
        final timestamp = t['timestamp'] as Timestamp?;
        if (timestamp == null) return false;
        return timestamp.toDate().isAfter(monthAgo);
      }).toList();
    } else if (_selectedTimeFilter == 'year') {
      final yearAgo = DateTime(now.year - 1, now.month, now.day);
      filtered = _transactions.where((t) {
        final timestamp = t['timestamp'] as Timestamp?;
        if (timestamp == null) return false;
        return timestamp.toDate().isAfter(yearAgo);
      }).toList();
    }
    
    // Calculate statistics
    _totalMilk = 0;
    _totalSpent = 0;
    _transactionCount = filtered.length;
    _farmerStats = {};
    
    for (var transaction in filtered) {
      final farmerId = transaction['farmerId'] as String;
      final milkInLitres = transaction['milkInLitres'] as double;
      final totalPrice = transaction['totalPrice'] as double;

      _totalMilk += milkInLitres;
      _totalSpent += totalPrice;

      // Aggregate by farmer
      if (!_farmerStats.containsKey(farmerId)) {
        _farmerStats[farmerId] = {
          'milk': 0.0,
          'spent': 0.0,
          'transactions': 0,
        };
      }
      
      _farmerStats[farmerId]!['milk'] += milkInLitres;
      _farmerStats[farmerId]!['spent'] += totalPrice;
      _farmerStats[farmerId]!['transactions'] += 1;
    }
    
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_distributorData != null 
            ? '${_distributorData!['name']} Statistics' 
            : 'Distributor Statistics'),
        backgroundColor: Colors.blue,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Transactions'),
          ],
        ),
      ),
      body: _isLoading 
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
                  children: [
                    _buildSummaryTab(),
                    _buildTransactionsTab(),
                  ],
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
          FilterChip(
            label: const Text('This Week'),
            selected: _selectedTimeFilter == 'week',
            onSelected: (selected) {
              setState(() {
                _selectedTimeFilter = 'week';
                _filterTransactionsByTime();
              });
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('This Month'),
            selected: _selectedTimeFilter == 'month',
            onSelected: (selected) {
              setState(() {
                _selectedTimeFilter = 'month';
                _filterTransactionsByTime();
              });
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('This Year'),
            selected: _selectedTimeFilter == 'year',
            onSelected: (selected) {
              setState(() {
                _selectedTimeFilter = 'year';
                _filterTransactionsByTime();
              });
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('All Time'),
            selected: _selectedTimeFilter == 'all',
            onSelected: (selected) {
              setState(() {
                _selectedTimeFilter = 'all';
                _filterTransactionsByTime();
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    if (_transactions.isEmpty) {
      return const Center(child: Text('No transactions found for the selected period.'));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDistributorInfoCard(),
          const SizedBox(height: 20),
          _buildSummaryCard(),
          const SizedBox(height: 20),
          const Text(
            'Farmer Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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
  
  Widget _buildDistributorInfoCard() {
    if (_distributorData == null) {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distributor Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildInfoRow(Icons.person, 'Name', _distributorData!['name'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, 'Phone', _distributorData!['phone'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.email, 'Email', _distributorData!['email'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.directions_car, 'Vehicle ID', _distributorData!['vehicleId'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.route, 'Route', _distributorData!['route'] ?? 'N/A'),
          ],
        ),
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 10),
            _buildStatRow(Icons.water_drop, 'Total Milk Collected', '${_totalMilk.toStringAsFixed(2)} Litres'),
            const SizedBox(height: 10),
            _buildStatRow(Icons.currency_rupee, 'Total Amount Paid', '₹${_totalSpent.toStringAsFixed(2)}'),
            const SizedBox(height: 10),
            _buildStatRow(Icons.receipt_long, 'Total Transactions', '$_transactionCount'),
            const SizedBox(height: 10),
            _buildStatRow(Icons.calculate, 'Average Price Paid', '₹${avgPrice.toStringAsFixed(2)}/L'),
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
      final farmerDoc = await FirebaseFirestore.instance
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
            _buildStatRow(Icons.water_drop, 'Milk Collected', '${farmer['milk'].toStringAsFixed(2)} Litres'),
            const SizedBox(height: 6),
            _buildStatRow(Icons.currency_rupee, 'Total Paid', '₹${farmer['spent'].toStringAsFixed(2)}'),
            const SizedBox(height: 6),
            _buildStatRow(Icons.receipt_long, 'Transactions', '${farmer['transactions']}'),
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
                    child: const Icon(Icons.person, size: 40, color: Colors.blue),
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
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.phone, 'Phone', farmer['phone']),
              _buildDetailRow(Icons.location_on, 'Location', farmer['location']),
              const SizedBox(height: 20),
              const Text(
                'Transaction Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.water_drop, 'Total Milk Collected', '${farmer['milk'].toStringAsFixed(2)} Litres'),
              _buildDetailRow(Icons.currency_rupee, 'Total Amount Paid', '₹${farmer['spent'].toStringAsFixed(2)}'),
              _buildDetailRow(Icons.receipt_long, 'Number of Transactions', '${farmer['transactions']}'),
              _buildDetailRow(Icons.calculate, 'Average Price Paid', 
                  '₹${(farmer['spent'] / farmer['milk']).toStringAsFixed(2)}/L'),
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
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
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('transactions')
                      .where('distributorId', isEqualTo: widget.distributorId)
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
                      return const Center(child: Text('No transactions found.'));
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        
                        final timestamp = data['timestamp'] as Timestamp?;
                        final dateString = timestamp != null 
                            ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate())
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.water_drop, color: Colors.blue),
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
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                  ),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade700),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsTab() {
    if (_transactions.isEmpty) {
      return const Center(child: Text('No transactions found for the selected period.'));
    }
    
    // Sort transactions by timestamp (newest first)
    _transactions.sort((a, b) {
      final timestampA = a['timestamp'] as Timestamp?;
      final timestampB = b['timestamp'] as Timestamp?;
      if (timestampA == null || timestampB == null) return 0;
      return timestampB.compareTo(timestampA);
    });
    
    return ListView.builder(
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        
        final timestamp = transaction['timestamp'] as Timestamp?;
        final dateString = timestamp != null 
            ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate())
            : 'Date not available';
        
        final farmerId = transaction['farmerId'] as String;
        
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(farmerId)
              .get(),
          builder: (context, farmerSnapshot) {
            String farmerName = 'Loading...';
            
            if (farmerSnapshot.hasData && farmerSnapshot.data!.exists) {
              final farmerData = farmerSnapshot.data!.data() as Map<String, dynamic>;
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
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.water_drop, color: Colors.blue),
                ),
                title: Text(
                  '${transaction['milkInLitres'].toStringAsFixed(2)} Litres at ₹${transaction['pricePerLitre'].toStringAsFixed(2)}/L',
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
                  '₹${transaction['totalPrice'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                isThreeLine: true,
                onTap: () {
                  if (farmerSnapshot.hasData && farmerSnapshot.data!.exists) {
                    final farmerData = farmerSnapshot.data!.data() as Map<String, dynamic>;
                    _showTransactionDetails(transaction, farmerData, transaction['id'], dateString);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
  
  void _showTransactionDetails(Map<String, dynamic> transaction, Map<String, dynamic> farmerData, 
      String transactionId, String dateString) {
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
                Text('Milk Quantity: ${transaction['milkInLitres'].toStringAsFixed(2)} Litres'),
                Text('Price per Litre: ₹${transaction['pricePerLitre'].toStringAsFixed(2)}'),
                Text('Total Amount: ₹${transaction['totalPrice'].toStringAsFixed(2)}'),
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
