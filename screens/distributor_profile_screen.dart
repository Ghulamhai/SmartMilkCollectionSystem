// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// import './login_screen.dart';
// import './edit_distributor_profile_screen.dart';

// class DistributorProfileScreen extends StatefulWidget {
//   const DistributorProfileScreen({Key? key}) : super(key: key);

//   @override
//   State<DistributorProfileScreen> createState() =>
//       _DistributorProfileScreenState();
// }

// class _DistributorProfileScreenState extends State<DistributorProfileScreen> {
//   Map<String, dynamic>? distributorData;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadDistributorData();
//   }

//   Future<void> _loadDistributorData() async {
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) return;

//     try {
//       final doc =
//           await FirebaseFirestore.instance.collection('users').doc(uid).get();
//       if (doc.exists) {
//         setState(() {
//           distributorData = doc.data();
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       print('Error loading distributor profile: $e');
//       setState(() => _isLoading = false);
//     }
//   }

//   void _logout(BuildContext context) async {
//     try {
//       await FirebaseAuth.instance.signOut(); // <-- Actually sign out
//       Navigator.of(context).pushAndRemoveUntil(
//         MaterialPageRoute(builder: (context) => const SignInPage()),
//         (Route<dynamic> route) => false,
//       );
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Logged out successfully!"),
//           duration: Duration(seconds: 2),
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Error during logout: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('My Profile'),
//         backgroundColor: Colors.green,
//         elevation: 1,
//       ),
//       body:
//           _isLoading
//               ? const Center(child: CircularProgressIndicator())
//               : distributorData == null
//               ? const Center(child: Text("No profile data found."))
//               : SingleChildScrollView(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Column(
//                   children: [
//                     CircleAvatar(
//                       radius: 50,
//                       backgroundColor: Colors.green.shade100,
//                       child: const Icon(
//                         Icons.person,
//                         size: 50,
//                         color: Colors.green,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       distributorData!['name'] ?? 'Distributor',
//                       style: const TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     const Text(
//                       'Milk Distributor',
//                       style: TextStyle(fontSize: 16, color: Colors.grey),
//                     ),
//                     const SizedBox(height: 24),

//                     _buildInfoTile(
//                       Icons.phone,
//                       'Phone',
//                       distributorData!['phone'] ?? '',
//                     ),

//                     // _buildInfoTile(Icons.map, 'Assigned Route', distributorData!['route'] ?? ''),
//                     // _buildInfoTile(
//                     //      Icons.delivery_dining,
//                     //     'Total Milk Collected Today',
//                     //     '${distributorData!['milkCollected'] ?? 0} Liters'),
//                     // _buildInfoTile(Icons.local_shipping, 'Vehicle ID', distributorData!['vehicleId'] ?? ''),
//                     const SizedBox(height: 24),
//                     ElevatedButton.icon(
//                       onPressed: () async {
//                         await Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder:
//                                 (_) => const EditDistributorProfileScreen(),
//                           ),
//                         );
//                         _loadDistributorData(); // Refresh on return
//                       },
//                       icon: const Icon(Icons.edit),
//                       label: const Text('Edit Profile'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green.shade700,
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         minimumSize: const Size.fromHeight(50),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     ElevatedButton.icon(
//                       onPressed: () => _logout(context),
//                       icon: const Icon(Icons.logout),
//                       label: const Text('Logout'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.red,
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         minimumSize: const Size.fromHeight(50),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//     );
//   }

//   Widget _buildInfoTile(IconData icon, String label, String value) {
//     return ListTile(
//       contentPadding: const EdgeInsets.symmetric(vertical: 6),
//       leading: Icon(icon, color: Colors.green),
//       title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
//       subtitle: Text(value),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import './login_screen.dart';
import './edit_distributor_profile_screen.dart';

class DistributorProfileScreen extends StatefulWidget {
  const DistributorProfileScreen({Key? key}) : super(key: key);

  @override
  State<DistributorProfileScreen> createState() =>
      _DistributorProfileScreenState();
}

class _DistributorProfileScreenState extends State<DistributorProfileScreen> {
  Map<String, dynamic>? distributorData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDistributorData();
  }

  Future<void> _loadDistributorData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        setState(() {
          distributorData = doc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading distributor profile: $e');
      setState(() => _isLoading = false);
    }
  }

  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SignInPage()),
        (Route<dynamic> route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Logged out successfully!"),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error during logout: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_outlined, color: Colors.white),
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EditDistributorProfileScreen(),
                ),
              );
              _loadDistributorData();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2E7D32),
                strokeWidth: 3,
              ),
            )
          : distributorData == null
              ? _buildEmptyState()
              : Stack(
                  children: [
                    // Top background gradient - made shorter
                    Container(
                      height: MediaQuery.of(context).size.height * 0.28,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF2E7D32),
                            Color(0xFF388E3C),
                            Color(0xFF43A047),
                          ],
                        ),
                      ),
                    ),
                    
                    // Decorative circles
                    Positioned(
                      top: -50,
                      right: -20,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 60,
                      left: -40,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    
                    // Main content
                    SafeArea(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            
                            // Profile avatar section
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 15,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 55,
                                      backgroundColor: Colors.white,
                                      child: CircleAvatar(
                                        radius: 52,
                                        backgroundColor: Colors.green.shade100,
                                        child: Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 30),
                            
                            // Main card with profile details - moved up to overlap with background
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Name and role at the top of the card
                                        Center(
                                          child: Column(
                                            children: [
                                              Text(
                                                distributorData!['name'] ?? 'Distributor',
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF2E7D32),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: const Text(
                                                  'Milk Distributor',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF2E7D32),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 30),
                                        
                                        const Text(
                                          'Personal Information',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2E7D32),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        
                                        // Phone info
                                        _buildProfileInfoItem(
                                          icon: Icons.phone_android_rounded,
                                          title: 'Phone Number',
                                          value: distributorData!['phone'] ?? 'Not provided',
                                        ),
                                        
                                        const SizedBox(height: 30),
                                        
                                        // Action buttons section
                                        const Text(
                                          'Account Actions',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2E7D32),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        
                                        // Edit profile button
                                        _buildActionButton(
                                          icon: Icons.edit_outlined,
                                          label: 'Edit Profile',
                                          color: const Color(0xFF2E7D32),
                                          onPressed: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => const EditDistributorProfileScreen(),
                                              ),
                                            );
                                            _loadDistributorData();
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        
                                        // Logout button
                                        _buildActionButton(
                                          icon: Icons.logout_rounded,
                                          label: 'Logout',
                                          color: Colors.redAccent,
                                          onPressed: () => _logout(context),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_off_outlined,
              size: 70,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No profile data found",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Please try again later or contact support",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2E7D32),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
