// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import './farmer_main_screen.dart';
// import './farmer_profile_screen.dart';
// import '/screens/login_screen.dart';
// import '../services/auth_service.dart';
// import '../dummy/available_distributors_screen.dart';
// import '../dummy/FarmerStatisticsScreen.dart';
// import '../dummy/milk_collection_screen.dart';
// import '../dummy/distributor_prices_screen.dart';
// import '../dummy/farmer_scheduled_pickups_screen.dart';

// class HomeScreenFarmer extends StatefulWidget {
//   const HomeScreenFarmer({Key? key}) : super(key: key);

//   @override
//   State<HomeScreenFarmer> createState() => _HomeScreenFarmerState();
// }

// class _HomeScreenFarmerState extends State<HomeScreenFarmer> {
//   int _selectedIndex = 0;

//   // Simplified pages list with only Dashboard and Profile
//   static final List<Widget> _pages = <Widget>[
//     DashboardPage(),
//     FarmerProfileScreen(),
//   ];

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Dairy Connect',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: Colors.green,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications_outlined),
//             onPressed: () {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text("Notifications coming soon!")),
//               );
//             },
//           ),
//         ],
//       ),
//       drawer: _buildBeautifulDrawer(context),
//       body: _pages[_selectedIndex],
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 10,
//               offset: const Offset(0, -5),
//             ),
//           ],
//         ),
//         child: ClipRRect(
//           borderRadius: const BorderRadius.only(
//             topLeft: Radius.circular(20),
//             topRight: Radius.circular(20),
//           ),
//           child: BottomNavigationBar(
//             items: const <BottomNavigationBarItem>[
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.dashboard_outlined),
//                 activeIcon: Icon(Icons.dashboard),
//                 label: 'Dashboard',
//               ),
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.person_outline),
//                 activeIcon: Icon(Icons.person),
//                 label: 'Profile',
//               ),
//             ],
//             currentIndex: _selectedIndex,
//             selectedItemColor: Colors.green,
//             unselectedItemColor: Colors.grey,
//             selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
//             elevation: 0,
//             backgroundColor: Colors.white,
//             onTap: _onItemTapped,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildBeautifulDrawer(BuildContext context) {
//     return Drawer(
//       child: Container(
//         color: Colors.white,
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             DrawerHeader(
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Colors.green, Color(0xFF388E3C)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const CircleAvatar(
//                     radius: 30,
//                     backgroundColor: Colors.white,
//                     child: Icon(Icons.person, size: 40, color: Colors.green),
//                   ),
//                   const SizedBox(height: 10),
//                   const Text(
//                     'Welcome, Farmer',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Text(
//                     'Manage your dairy business',
//                     style: TextStyle(
//                       color: Colors.white.withOpacity(0.8),
//                       fontSize: 14,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             _buildDrawerItem(
//               context,
//               icon: Icons.dashboard,
//               title: 'Dashboard',
//               onTap: () => _onItemTapped(0),
//             ),
//             _buildDrawerItem(
//               context,
//               icon: Icons.person,
//               title: 'Profile',
//               onTap: () => _onItemTapped(1),
//             ),
//             const Divider(),
//             const Padding(
//               padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               child: Text(
//                 'MILK MANAGEMENT',
//                 style: TextStyle(
//                   color: Colors.grey,
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             _buildDrawerItem(
//               context,
//               icon: Icons.analytics,
//               title: 'My Statistics',
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const FarmerStatisticsScreen(),
//                   ),
//                 );
//               },
//             ),
//             _buildDrawerItem(
//               context,
//               icon: Icons.store,
//               title: 'View Distributors',
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const DistributorPricesScreen(),
//                   ),
//                 );
//               },
//             ),
//             _buildDrawerItem(
//               context,
//               icon: Icons.calendar_today,
//               title: 'My Scheduled Pickups',
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const FarmerScheduledPickupsScreen(),
//                   ),
//                 );
//               },
//             ),
//             _buildDrawerItem(
//               context,
//               icon: Icons.local_shipping,
//               title: 'Schedule Collection',
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder:
//                         (context) => MilkCollectionScreen(userRole: 'farmer'),
//                   ),
//                 );
//               },
//             ),
//             const Divider(),
//             const Padding(
//               padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               child: Text(
//                 'ACCOUNT',
//                 style: TextStyle(
//                   color: Colors.grey,
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             _buildDrawerItem(
//               context,
//               icon: Icons.help_outline,
//               title: 'Help & Support',
//               onTap: () {
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text("Support coming soon!")),
//                 );
//               },
//             ),
//             _buildDrawerItem(
//               context,
//               icon: Icons.logout,
//               title: 'Logout',
//               onTap: () async {
//                 Navigator.pop(context);
//                 try {
//                   await AuthService().signOut();
//                   Navigator.of(context).pushAndRemoveUntil(
//                     MaterialPageRoute(builder: (context) => const SignInPage()),
//                     (Route<dynamic> route) => false,
//                   );
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("Logged out successfully!")),
//                   );
//                 } catch (e) {
//                   ScaffoldMessenger.of(
//                     context,
//                   ).showSnackBar(SnackBar(content: Text("Logout failed: $e")));
//                 }
//               },
//               textColor: Colors.red,
//               iconColor: Colors.red,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDrawerItem(
//     BuildContext context, {
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//     Color? textColor,
//     Color? iconColor,
//   }) {
//     return ListTile(
//       leading: Icon(icon, color: iconColor ?? Colors.green),
//       title: Text(
//         title,
//         style: TextStyle(
//           color: textColor ?? Colors.black87,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       onTap: onTap,
//       contentPadding: const EdgeInsets.symmetric(horizontal: 24),
//       dense: true,
//     );
//   }
// }

// class DashboardPage extends StatefulWidget {
//   @override
//   _DashboardPageState createState() => _DashboardPageState();
// }

// class _DashboardPageState extends State<DashboardPage> {
//   String farmerName = 'Farmer';
//   String totalMilk = '0';
//   String currentPrice = '₹35';
//   List<Map<String, dynamic>> recentTransactions = [];
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadFarmerData();
//   }

//   Future<void> _loadFarmerData() async {
//     setState(() {
//       isLoading = true;
//     });

//     try {
//       // Get current user
//       final user = FirebaseAuth.instance.currentUser;

//       if (user != null) {
//         // Fetch farmer profile from Firestore
//         final farmerDoc =
//             await FirebaseFirestore.instance
//                 .collection('farmers')
//                 .doc(user.uid)
//                 .get();

//         if (farmerDoc.exists) {
//           final data = farmerDoc.data();

//           // Fetch milk collection statistics
//           final milkStats =
//               await FirebaseFirestore.instance
//                   .collection('milk_collections')
//                   .where('farmerId', isEqualTo: user.uid)
//                   .get();

//           double totalMilkLiters = 0;
//           for (var doc in milkStats.docs) {
//             totalMilkLiters += (doc.data()['quantity'] ?? 0).toDouble();
//           }

//           // Fetch recent transactions
//           final transactions =
//               await FirebaseFirestore.instance
//                   .collection('transactions')
//                   .where('farmerId', isEqualTo: user.uid)
//                   .orderBy('date', descending: true)
//                   .limit(3)
//                   .get();

//           List<Map<String, dynamic>> transactionsList = [];
//           for (var doc in transactions.docs) {
//             transactionsList.add({
//               'id': doc.id,
//               'date': doc.data()['date'],
//               'title': doc.data()['type'] ?? 'Milk Collection',
//               'subtitle':
//                   '${doc.data()['quantity'] ?? 0} liters @ ₹${doc.data()['pricePerLiter'] ?? 0}/L',
//               'amount': doc.data()['amount'] ?? 0,
//             });
//           }

//           // Get current milk price
//           final priceDoc =
//               await FirebaseFirestore.instance
//                   .collection('milk_prices')
//                   .orderBy('effectiveDate', descending: true)
//                   .limit(1)
//                   .get();

//           double currentPriceValue = 35.0; // Default value
//           if (priceDoc.docs.isNotEmpty) {
//             currentPriceValue =
//                 (priceDoc.docs.first.data()['pricePerLiter'] ?? 35.0)
//                     .toDouble();
//           }

//           setState(() {
//             farmerName = data?['firstName'] ?? user.displayName ?? 'Farmer';
//             totalMilk = totalMilkLiters.toStringAsFixed(1);
//             currentPrice = '₹${currentPriceValue.toStringAsFixed(2)}';
//             recentTransactions = transactionsList;
//             isLoading = false;
//           });
//         } else {
//           // If farmer document doesn't exist, use auth display name
//           setState(() {
//             farmerName = user.displayName ?? 'Farmer';
//             isLoading = false;
//           });
//         }
//       } else {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       print('Error loading farmer data: $e');

//       // If there's an error, use dummy data for demonstration
//       setState(() {
//         farmerName = 'Rajesh Kumar';
//         totalMilk = '245.5';
//         currentPrice = '₹35.00';
//         recentTransactions = [
//           {
//             'id': '1',
//             'date': Timestamp.now(),
//             'title': 'Milk Collection',
//             'subtitle': '25 liters @ ₹35/L',
//             'amount': 875,
//           },
//           {
//             'id': '2',
//             'date': Timestamp.fromDate(
//               DateTime.now().subtract(Duration(days: 1)),
//             ),
//             'title': 'Payment Received',
//             'subtitle': '₹850 for 25 liters @ ₹34/L',
//             'amount': 850,
//           },
//           {
//             'id': '3',
//             'date': Timestamp.fromDate(
//               DateTime.now().subtract(Duration(days: 2)),
//             ),
//             'title': 'Milk Collection',
//             'subtitle': '22 liters @ ₹35/L',
//             'amount': 770,
//           },
//         ];
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Current date - using the provided date
//     final now = DateTime(2025, 4, 22, 12, 33);
//     final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(now);
//     final formattedTime = DateFormat('h:mm a').format(now);

//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildWelcomeBanner(formattedDate, formattedTime),
//             const SizedBox(height: 20),
//             _buildSectionTitle('Quick Actions'),
//             const SizedBox(height: 10),

//             // Responsive GridView using GridView.extent
//             Container(
//               // This container helps constrain the grid
//               constraints: BoxConstraints(
//                 maxWidth: MediaQuery.of(context).size.width,
//               ),
//               child: GridView.extent(
//                 maxCrossAxisExtent: 200, // Maximum width for each grid item
//                 childAspectRatio: 0.85, // Adjust aspect ratio as needed
//                 crossAxisSpacing: 16,
//                 mainAxisSpacing: 16,
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 children: [
//                   _buildFeatureCard(
//                     title: 'My Statistics',
//                     icon: Icons.analytics,
//                     color: Colors.blue,
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const FarmerStatisticsScreen(),
//                         ),
//                       );
//                     },
//                     description: 'View your milk production data',
//                   ),
//                   _buildFeatureCard(
//                     title: 'View Distributors',
//                     icon: Icons.store,
//                     color: Colors.green,
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const DistributorPricesScreen(),
//                         ),
//                       );
//                     },
//                     description: 'See available milk distributors',
//                   ),
//                   _buildFeatureCard(
//                     title: 'Scheduled Pickups',
//                     icon: Icons.calendar_today,
//                     color: Colors.orange,
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder:
//                               (context) => const FarmerScheduledPickupsScreen(),
//                         ),
//                       );
//                     },
//                     description: 'View your upcoming pickups',
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 20),
//             _buildSectionTitle('Recent Activity'),
//             const SizedBox(height: 10),
//             isLoading
//                 ? Center(child: CircularProgressIndicator(color: Colors.green))
//                 : _buildRecentActivityCard(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildWelcomeBanner(String formattedDate, String formattedTime) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.green, Colors.green.shade800],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.green.withOpacity(0.3),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Welcome back, $farmerName!',
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 22,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             '$formattedDate, $formattedTime IST',
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.9),
//               fontSize: 14,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               _buildStatCard('Total Milk Given', '$totalMilk L'),
//               const SizedBox(width: 16),
//               _buildStatCard('Current Price', currentPrice),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatCard(String title, String value) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.2),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               title,
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.8),
//                 fontSize: 12,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               value,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Row(
//       children: [
//         Container(
//           width: 4,
//           height: 20,
//           decoration: BoxDecoration(
//             color: Colors.green,
//             borderRadius: BorderRadius.circular(4),
//           ),
//         ),
//         const SizedBox(width: 8),
//         Text(
//           title,
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.black87,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildFeatureCard({
//     required String title,
//     required IconData icon,
//     required Color color,
//     required VoidCallback onTap,
//     required String description,
//   }) {
//     return Container(
//       constraints: const BoxConstraints(minWidth: 0),
//       child: Card(
//         elevation: 2,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         child: InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(16),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: color.withOpacity(0.1),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(icon, color: color, size: 32),
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   textAlign: TextAlign.center,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   description,
//                   style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//                   textAlign: TextAlign.center,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildRecentActivityCard() {
//     if (recentTransactions.isEmpty) {
//       return Card(
//         elevation: 2,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Center(
//             child: Column(
//               children: [
//                 Icon(Icons.history, color: Colors.grey, size: 48),
//                 SizedBox(height: 8),
//                 Text(
//                   'No transactions yet',
//                   style: TextStyle(color: Colors.grey.shade600),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }

//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children:
//               recentTransactions.asMap().entries.map((entry) {
//                 final transaction = entry.value;
//                 final index = entry.key;

//                 final date =
//                     transaction['date'] != null
//                         ? DateFormat(
//                           'MMM dd, yyyy',
//                         ).format((transaction['date'] as Timestamp).toDate())
//                         : 'Apr 22, 2025';

//                 final Widget item = _buildActivityItem(
//                   date: date,
//                   title: transaction['title'] ?? 'Milk Collection',
//                   subtitle: transaction['subtitle'] ?? '',
//                   icon:
//                       transaction['title'] == 'Payment Received'
//                           ? Icons.payment
//                           : Icons.local_shipping,
//                   color:
//                       transaction['title'] == 'Payment Received'
//                           ? Colors.blue
//                           : Colors.green,
//                 );

//                 return index < recentTransactions.length - 1
//                     ? Column(children: [item, const Divider()])
//                     : item;
//               }).toList(),
//         ),
//       ),
//     );
//   }

//   Widget _buildActivityItem({
//     required String date,
//     required String title,
//     required String subtitle,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, color: color, size: 24),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//                 Text(
//                   subtitle,
//                   style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
//                 ),
//               ],
//             ),
//           ),
//           Text(
//             date,
//             style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
//           ),
//         ],
//       ),
//     );
//   }
// }





// // ------------------------------------//

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import './farmer_main_screen.dart';
import './farmer_profile_screen.dart';
import '/screens/login_screen.dart';
import '../services/auth_service.dart';
import '../helpers/available_distributors_screen.dart';
import '../helpers/FarmerStatisticsScreen.dart';
import '../helpers/milk_collection_screen.dart';
import '../helpers/distributor_prices_screen.dart';
import '../helpers/farmer_scheduled_pickups_screen.dart';

// Constants for maintainability
const double _gridMaxCrossAxisExtent = 200.0;
const String _appName = 'Dairy Connect';

class HomeScreenFarmer extends StatefulWidget {
  const HomeScreenFarmer({Key? key}) : super(key: key);

  @override
  State<HomeScreenFarmer> createState() => _HomeScreenFarmerState();
}

class _HomeScreenFarmerState extends State<HomeScreenFarmer> {
  int _selectedIndex = 0;

  // Updated pages list with Dashboard, Profile, and Scheduled Pickups
  static final List<Widget> _pages = <Widget>[
    DashboardPage(),
    FarmerProfileScreen(),
    FarmerScheduledPickupsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          _appName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: _buildBeautifulDrawer(context),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today),
                label: 'Pickups',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            elevation: 0,
            backgroundColor: Colors.white,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }

  Widget _buildBeautifulDrawer(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;

    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Color(0xFF388E3C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null
                        ? const Icon(Icons.person, size: 40, color: Colors.green)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Welcome, Farmer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Manage your dairy business',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.dashboard,
              title: 'Dashboard',
              onTap: () => _onItemTapped(0),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.person,
              title: 'Profile',
              onTap: () => _onItemTapped(1),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.calendar_today,
              title: 'Scheduled Pickups',
              onTap: () => _onItemTapped(2),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'MILK MANAGEMENT',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.analytics,
              title: 'My Statistics',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FarmerStatisticsScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.store,
              title: 'View Distributors',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DistributorPricesScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.local_shipping,
              title: 'Schedule Collection',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MilkCollectionScreen(userRole: 'farmer'),
                  ),
                );
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'ACCOUNT',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Support coming soon!")),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.logout,
              title: 'Logout',
              onTap: () async {
                Navigator.pop(context);
                try {
                  await AuthService().signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const SignInPage()),
                    (Route<dynamic> route) => false,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Logged out successfully!")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Logout failed: $e")),
                  );
                }
              },
              textColor: Colors.red,
              iconColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Semantics(
      label: title,
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.green),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        dense: true,
      ),
    );
  }
}

// Placeholder Notifications Screen
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text(
          'No notifications yet',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String farmerName = 'Farmer';
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFarmerData();
  }

  Future<void> _loadFarmerData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'No user is logged in. Please sign in again.';
        });
        return;
      }

      // Fetch farmer profile
      final farmerDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(user.uid)
          .get();

      String name = 'Farmer';
      if (farmerDoc.exists) {
        final data = farmerDoc.data() as Map<String, dynamic>?;
        name = data?['firstName'] ?? user.displayName ?? 'Farmer';
      } else {
        name = user.displayName ?? 'Farmer';
      }

      setState(() {
        farmerName = name;
        isLoading = false;
      });
    } catch (e) {
      String error;
      if (e.toString().contains('permission-denied')) {
        error = 'Permission denied. Please check your access rights.';
      } else if (e.toString().contains('network')) {
        error = 'Network error. Please check your internet connection.';
      } else {
        error = 'Failed to load profile: $e';
      }
      print('Error loading farmer data: $e');
      setState(() {
        farmerName = 'Farmer';
        isLoading = false;
        errorMessage = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(now);
    final formattedTime = DateFormat('h:mm a').format(now);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            errorMessage != null
                ? _buildErrorBanner(errorMessage!)
                : _buildWelcomeBanner(formattedDate, formattedTime),
            const SizedBox(height: 20),
            _buildSectionTitle('Quick Actions'),
            const SizedBox(height: 10),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width,
              ),
              child: GridView.extent(
                maxCrossAxisExtent: _gridMaxCrossAxisExtent,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildFeatureCard(
                    title: 'My Statistics',
                    icon: Icons.analytics,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FarmerStatisticsScreen(),
                        ),
                      );
                    },
                    description: 'View your milk production data',
                  ),
                  _buildFeatureCard(
                    title: 'View Distributors',
                    icon: Icons.store,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DistributorPricesScreen(),
                        ),
                      );
                    },
                    description: 'See available milk distributors',
                  ),
                  _buildFeatureCard(
                    title: 'Scheduled Pickups',
                    icon: Icons.calendar_today,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FarmerScheduledPickupsScreen(),
                        ),
                      );
                    },
                    description: 'View your upcoming pickups',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Recent Activity'),
            const SizedBox(height: 10),
            _buildRecentActivityCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(String formattedDate, String formattedTime) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green, Colors.green.shade800],
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
          Semantics(
            label: 'Welcome back, $farmerName',
            child: Text(
              'Welcome back, $farmerName!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Date and time: $formattedDate, $formattedTime IST',
            child: Text(
              '$formattedDate, $formattedTime IST',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Error',
            style: TextStyle(
              color: Colors.red,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.red.shade900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFarmerData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String description,
  }) {
    return Semantics(
      label: title,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minWidth: 0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
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
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.history, color: Colors.grey, size: 48),
              const SizedBox(height: 8),
              Text(
                'No transactions available',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}