
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../helpers/available_distributors_screen.dart';
import '../helpers/FarmerStatisticsScreen.dart';
import '../helpers/milk_collection_screen.dart';
import '../helpers/distributor_prices_screen.dart';
import '../helpers/farmer_scheduled_pickups_screen.dart';

class DashboardPage extends StatefulWidget {
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final int unreadNotifications = 3;
  bool _isLoading = true;
  String _farmerName = "Farmer";
  double _totalEarnings = 0;
  double _totalMilkSold = 0;
  
  @override
  void initState() {
    super.initState();
    _loadFarmerData();
    _loadStatistics();
  }
  
  Future<void> _loadFarmerData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
            
        if (userDoc.exists) {
          setState(() {
            _farmerName = userDoc.data()?['name'] ?? "Farmer";
          });
        }
      }
    } catch (e) {
      print('Error loading farmer data: $e');
    }
  }
  
  Future<void> _loadStatistics() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get all transactions to calculate totals
        final querySnapshot = await FirebaseFirestore.instance
            .collection('transactions')
            .where('farmer_id', isEqualTo: user.uid)
            .get();
            
        double totalMilk = 0;
        double totalEarned = 0;
        
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          totalMilk += _parseToDouble(data['quantity']);
          totalEarned += _parseToDouble(data['total_amount']);
        }
        
        setState(() {
          _totalMilkSold = totalMilk;
          _totalEarnings = totalEarned;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading statistics: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.green))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting and Summary Card
                _buildGreetingCard(context),
                const SizedBox(height: 24),
                
                // Features Section
                Text(
                  'Features',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 12),
                _buildFeaturesGrid(context),
                const SizedBox(height: 24),
                
                // Notifications
                _buildNotificationsCard(context),
              ],
            ),
          );
  }
  
  Widget _buildGreetingCard(BuildContext context) {
    final now = DateTime.now();
    String greeting;
    
    if (now.hour < 12) {
      greeting = 'Good Morning';
    } else if (now.hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.green.shade100,
                  child: Text(
                    _farmerName.isNotEmpty ? _farmerName[0].toUpperCase() : 'F',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting,',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green.shade800,
                        ),
                      ),
                      Text(
                        _farmerName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  context,
                  icon: Icons.water_drop,
                  title: 'Total Milk',
                  value: '${_totalMilkSold.toStringAsFixed(1)} L',
                ),
                Container(height: 40, width: 1, color: Colors.grey.shade300),
                _buildSummaryItem(
                  context,
                  icon: Icons.currency_rupee,
                  title: 'Total Earnings',
                  value: '₹${_totalEarnings.toStringAsFixed(0)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.green.shade700, size: 28),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
          ),
        ),
      ],
    );
  }
  
  Widget _buildFeaturesGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildFeatureCard(
          context,
          icon: Icons.store,
          title: 'Milk Suppliers',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DistributorPricesScreen(),
              ),
            );
          },
        ),
        _buildFeatureCard(
          context,
          icon: Icons.analytics,
          title: 'My Statistics',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FarmerStatisticsScreen(),
              ),
            );
          },
        ),
        _buildFeatureCard(
          context,
          icon: Icons.calendar_today,
          title: 'Pickup Schedule',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FarmerScheduledPickupsScreen(),
              ),
            );
          },
        ),
        _buildFeatureCard(
          context,
          icon: Icons.receipt_long,
          title: 'Transactions',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FarmerStatisticsScreen(),
              ),
            );
          },
        ),
        _buildFeatureCard(
          context,
          icon: Icons.support_agent,
          title: 'Support',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Support coming soon!')),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.green.shade700),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNotificationsCard(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Stack(
          children: [
            const Icon(Icons.notifications, color: Colors.amber, size: 28),
            if (unreadNotifications > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$unreadNotifications',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: const Text('Notifications'),
        subtitle: Text(
          unreadNotifications > 0
              ? 'You have $unreadNotifications unread notifications'
              : 'No new notifications',
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Notifications coming soon!")),
          );
        },
      ),
    );
  }
}
