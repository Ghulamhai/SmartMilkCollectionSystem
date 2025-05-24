import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart'; // path to where navigatorKey is defined
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import './distributor_profile_screen.dart'; // update path if needed
import '../helpers/distributorStatistics.dart';
import '../helpers/statsForDistributor.dart';
import '../helpers/milk_price_and_pickup_manager.dart'; // Import the new file
import '../helpers/path_optimization.dart';
import '../helpers/pickups.dart';

class HomeScreenDistributor extends StatefulWidget {
  const HomeScreenDistributor({Key? key}) : super(key: key);

  @override
  State<HomeScreenDistributor> createState() => _HomeScreenDistributorState();
}

class _HomeScreenDistributorState extends State<HomeScreenDistributor> {
  String userName1 = 'Loading...';
  final String userName = 'Yash'; // temp name
  File? _signatureImage;

  @override
  void initState() {
    super.initState();
    _loadUserName(); // Fetch user details when the widget is initialized
  }

  void _loadUserName() {
    final user = FirebaseAuth.instance.currentUser;

    // Check if the user is logged in and set the name or fallback to email if no name
    if (user != null) {
      setState(() {
        userName1 =
            user.displayName ??
            user.email?.split('@')[0] ??
            'User'; // Fallback if no displayName
      });
    } else {
      setState(() {
        userName1 = 'User'; // Fallback if no user is logged in
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.green.shade50,
          elevation: 0,
          titleSpacing: 20,
          title: Text(
            'Dairy Connect',
            style: TextStyle(
              color: Colors.green.shade800,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DistributorProfileScreen(),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.shade300, width: 2),
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      userName1.isNotEmpty ? userName1[0].toUpperCase() : 'D',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          iconTheme: IconThemeData(color: Colors.green.shade800),
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade600, Colors.green.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 30,
                      child: Text(
                        userName1.isNotEmpty ? userName1[0].toUpperCase() : 'D',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      userName1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Milk Distributor',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Main Navigation Section
              _buildDrawerItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                title: 'Dashboard',
                onTap: () {
                  Navigator.pop(context);
                },
                isActive: true,
              ),
              _buildDrawerItem(
                icon: Icons.route_outlined,
                activeIcon: Icons.route,
                title: 'My Route',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConfirmedPickupsScreen(),
                    ),
                  );
                },
              ),

              // Business Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'BUSINESS',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildDrawerItem(
                icon: Icons.monetization_on_outlined,
                activeIcon: Icons.monetization_on,
                title: 'Milk Pricing',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MilkPriceAndPickupManager(),
                    ),
                  );
                },
              ),
              _buildDrawerItem(
                icon: Icons.history_outlined,
                activeIcon: Icons.history,
                title: 'Collection History',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => const DistributorStatisticsScreen1(),
                    ),
                  );
                },
              ),
              _buildDrawerItem(
                icon: Icons.analytics_outlined,
                activeIcon: Icons.analytics,
                title: 'Statistics',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => const DistributorStatisticsScreen1(),
                    ),
                  );
                },
              ),

              const Divider(),

              // Settings Section
              _buildDrawerItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                title: 'Settings',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                icon: Icons.help_outline,
                activeIcon: Icons.help,
                title: 'Help & Support',
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              const Divider(),

              // Logout
              _buildDrawerItem(
                icon: Icons.logout,
                title: 'Logout',
                onTap: () async {
                  Navigator.pop(context);
                  final shouldLogout =
                      await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Logout'),
                              content: const Text(
                                'Are you sure you want to logout?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Logout'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                      ) ??
                      false;

                  if (shouldLogout) {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                textColor: Colors.red,
                iconColor: Colors.red,
              ),

              
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeBanner(),
              const SizedBox(height: 24),

              // Main feature cards - Updated to use GridView.builder with fixed height
              GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio:
                      0.85, // Adjust this value to control card height
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                itemBuilder: (context, index) {
                  // Define card data
                  final List<Map<String, dynamic>> cardData = [
                    {
                      'title': 'Milk Pricing',
                      'icon': Icons.monetization_on,
                      'color': Colors.green,
                      'description': 'Set prices and manage pickups',
                      'onTap': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const MilkPriceAndPickupManager(),
                          ),
                        );
                      },
                    },
                    {
                      'title': 'Statistics',
                      'icon': Icons.analytics,
                      'color': Colors.blue,
                      'description': 'View business analytics',
                      'onTap': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    const DistributorStatisticsScreen1(),
                          ),
                        );
                      },
                    },
                    {
                      'title': 'Collection History',
                      'icon': Icons.history,
                      'color': Colors.purple,
                      'description': 'Track milk collections',
                      'onTap': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    const DistributorStatisticsScreen1(),
                          ),
                        );
                      },
                    },
                    {
                        'title': 'My Route',
                        'icon': Icons.route,
                        'color': Colors.orange,
                        'description': 'Optimize pickup routes',
                        'onTap': () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConfirmedPickupsScreen(),
                            ),
                          );
                        },
                    },
                  ];

                  final card = cardData[index];
                  return _buildFeatureCard(
                    title: card['title'],
                    icon: card['icon'],
                    color: card['color'],
                    onTap: card['onTap'],
                    description: card['description'],
                  );
                },
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Quick Actions'),
              const SizedBox(height: 12),
              _buildQuickActionsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    IconData? activeIcon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        isActive ? (activeIcon ?? icon) : icon,
        color:
            iconColor ??
            (isActive ? Colors.green.shade700 : Colors.grey.shade700),
      ),
      title: Text(
        title,
        style: TextStyle(
          color:
              textColor ?? (isActive ? Colors.green.shade700 : Colors.black87),
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  Widget _buildWelcomeBanner() {
    final now = DateTime.now();
    String greeting;

    if (now.hour < 12) {
      greeting = 'Good Morning';
    } else if (now.hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting, $userName1 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Let\'s collect fresh milk and support our farmers today!',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy').format(DateTime.now()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  }

  // Updated feature card with better text overflow handling
  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String description,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: Icon(Icons.add, color: Colors.green.shade700),
              ),
              title: const Text('Add New Collection'),
              subtitle: const Text('Record a new milk collection'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Add collection feature coming soon!'),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Icon(Icons.update, color: Colors.blue.shade700),
              ),
              title: const Text('Update Milk Price'),
              subtitle: const Text('Change your current milk price'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MilkPriceAndPickupManager(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.purple.shade100,
                child: Icon(Icons.people, color: Colors.purple.shade700),
              ),
              title: const Text('View Farmers'),
              subtitle: const Text('See all registered farmers'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('View farmers feature coming soon!'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
