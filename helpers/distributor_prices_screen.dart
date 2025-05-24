// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'package:geocoding/geocoding.dart';
// import 'dart:ui' as ui;

// class DistributorPricesScreen extends StatefulWidget {
//   const DistributorPricesScreen({Key? key}) : super(key: key);

//   @override
//   State<DistributorPricesScreen> createState() =>
//       _DistributorPricesScreenState();
// }

// class _DistributorPricesScreenState extends State<DistributorPricesScreen> {
//   bool _isLoading = true;
//   List<Map<String, dynamic>> _distributors = [];
//   Map<String, dynamic> _farmerDetails = {};
//   String _formattedAddress = "";

//   @override
//   void initState() {
//     super.initState();
//     _loadFarmerDetails();
//     _loadDistributors();
//   }

//   Future<void> _loadFarmerDetails() async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         final farmerDoc = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(user.uid)
//             .get();

//         if (farmerDoc.exists) {
//           final farmerData = farmerDoc.data() ?? {};
//           setState(() {
//             _farmerDetails = farmerData;
//           });

//           // If location coordinates are available, try to get a readable address
//           if (farmerData.containsKey('location') &&
//               farmerData['location'] != null &&
//               farmerData['location'].toString().isNotEmpty) {
//             _getAddressFromCoordinates(farmerData['location']);
//           }
//         }
//       }
//     } catch (e) {
//       print('Error loading farmer details: $e');
//     }
//   }

//   Future<void> _getAddressFromCoordinates(String locationString) async {
//     try {
//       // Parse the location string to get latitude and longitude
//       final locationParts = locationString.split(',');
//       if (locationParts.length == 2) {
//         final latitude = double.tryParse(locationParts[0].trim());
//         final longitude = double.tryParse(locationParts[1].trim());

//         if (latitude != null && longitude != null) {
//           // Use the geocoding package to get a readable address
//           List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
//           if (placemarks.isNotEmpty) {
//             Placemark place = placemarks[0];
//             setState(() {
//               _formattedAddress = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
//             });
//           }
//         }
//       }
//     } catch (e) {
//       print('Error getting address from coordinates: $e');
//     }
//   }

//   Future<void> _loadDistributors() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // Get all distributors who have set milk prices
//       final querySnapshot =
//           await FirebaseFirestore.instance.collection('milk_prices').get();

//       final distributors = await Future.wait(
//         querySnapshot.docs.map((doc) async {
//           final data = doc.data();
//           final distributorId = data['distributor_id'] ?? '';

//           // Ensure we get the actual distributor name
//           String distributorName = data['distributor_name'] ?? '';

//           // If distributor_name is empty or not available, try to get it from users collection
//           if (distributorName.isEmpty ||
//               distributorName == 'Unknown Distributor') {
//             try {
//               final distributorDoc =
//                   await FirebaseFirestore.instance
//                       .collection('users')
//                       .doc(distributorId)
//                       .get();

//               if (distributorDoc.exists) {
//                 final distributorData = distributorDoc.data();
//                 distributorName =
//                     distributorData?['name'] ?? 'Unknown Distributor';

//                 // Update the milk_prices document with the correct name if needed
//                 if (distributorName != 'Unknown Distributor' &&
//                     distributorName != data['distributor_name']) {
//                   await FirebaseFirestore.instance
//                       .collection('milk_prices')
//                       .doc(doc.id)
//                       .update({'distributor_name': distributorName});
//                 }
//               }
//             } catch (e) {
//               // Fallback to default if error occurs
//               distributorName =
//                   distributorName.isEmpty
//                       ? 'Unknown Distributor'
//                       : distributorName;
//             }
//           }

//           final basePrice = (data['base_price'] ?? 0.0).toDouble();
//           DateTime updatedAt = DateTime.now();

//           // Handle the Timestamp null issue
//           if (data['updated_at'] != null) {
//             updatedAt = (data['updated_at'] as Timestamp).toDate();
//           }

//           // Get distributor profile info if available
//           String location = '';
//           String phoneNumber = '';

//           try {
//             final distributorDoc =
//                 await FirebaseFirestore.instance
//                     .collection('users')
//                     .doc(distributorId)
//                     .get();

//             if (distributorDoc.exists) {
//               final distributorData = distributorDoc.data();
//               location = distributorData?['address'] ?? '';
//               phoneNumber = distributorData?['phone'] ?? '';
//             }
//           } catch (e) {
//             // Ignore errors fetching additional info
//           }

//           return {
//             'id': distributorId,
//             'name': distributorName,
//             'base_price': basePrice,
//             'updated_at': updatedAt,
//             'location': location,
//             'phone': phoneNumber,
//           };
//         }).toList(),
//       );

//       setState(() {
//         _distributors = distributors;
//         _isLoading = false;
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error loading distributors: $e')));
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   void _showSchedulePickupDialog(Map<String, dynamic> distributor) {
//     final TextEditingController quantityController = TextEditingController();
//     DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
//     TimeOfDay selectedTime = TimeOfDay.now();
//     bool cleaningRequested = false;

//     showDialog(
//       context: context,
//       builder:
//           (context) => StatefulBuilder(
//             builder: (context, setState) {
//               return AlertDialog(
//                 title: Text('Schedule Pickup with ${distributor['name']}'),
//                 content: SingleChildScrollView(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Current Price: ₹${distributor['base_price'].toStringAsFixed(2)} per liter',
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: Colors.green,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       TextFormField(
//                         controller: quantityController,
//                         decoration: const InputDecoration(
//                           labelText: 'Milk Quantity (liters)',
//                           border: OutlineInputBorder(),
//                           prefixIcon: Icon(Icons.water_drop),
//                         ),
//                         keyboardType: TextInputType.number,
//                       ),
//                       const SizedBox(height: 16),
//                       if (_farmerDetails.containsKey('location') &&
//                           _farmerDetails['location'] != null &&
//                           _farmerDetails['location'].toString().isNotEmpty)
//                         Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.blue.shade50,
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(color: Colors.blue.shade200),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text(
//                                 'Your location will be shared with the distributor:',
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 14,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Row(
//                                 children: [
//                                   Icon(Icons.location_on, color: Colors.blue.shade700, size: 16),
//                                   const SizedBox(width: 4),
//                                   Expanded(
//                                     child: Text(
//                                       _formattedAddress.isNotEmpty
//                                           ? _formattedAddress
//                                           : _farmerDetails['location'],
//                                       style: const TextStyle(fontSize: 14),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         )
//                       else
//                         Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.red.shade50,
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(color: Colors.red.shade200),
//                           ),
//                           child: const Row(
//                             children: [
//                               Icon(Icons.warning, color: Colors.red, size: 16),
//                               SizedBox(width: 8),
//                               Expanded(
//                                 child: Text(
//                                   'No location found in your profile. The distributor may not be able to locate you.',
//                                   style: TextStyle(
//                                     color: Colors.red,
//                                     fontSize: 14,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       const SizedBox(height: 16),
//                       const Text(
//                         'Pickup Date:',
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       ListTile(
//                         title: Text(
//                           DateFormat('dd MMM yyyy').format(selectedDate),
//                         ),
//                         trailing: const Icon(Icons.calendar_today),
//                         onTap: () async {
//                           final DateTime? pickedDate = await showDatePicker(
//                             context: context,
//                             initialDate: selectedDate,
//                             firstDate: DateTime.now(),
//                             lastDate: DateTime.now().add(
//                               const Duration(days: 14),
//                             ),
//                           );
//                           if (pickedDate != null &&
//                               pickedDate != selectedDate) {
//                             setState(() {
//                               selectedDate = pickedDate;
//                             });
//                           }
//                         },
//                       ),
//                       const SizedBox(height: 8),
//                       const Text(
//                         'Pickup Time:',
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       ListTile(
//                         title: Text(selectedTime.format(context)),
//                         trailing: const Icon(Icons.access_time),
//                         onTap: () async {
//                           final TimeOfDay? pickedTime = await showTimePicker(
//                             context: context,
//                             initialTime: selectedTime,
//                           );
//                           if (pickedTime != null &&
//                               pickedTime != selectedTime) {
//                             setState(() {
//                               selectedTime = pickedTime;
//                             });
//                           }
//                         },
//                       ),

//                       const SizedBox(height: 16),
//                       CheckboxListTile(
//                         title: const Text('Request container cleaning'),
//                         subtitle: const Text('Additional charges may apply'),
//                         value: cleaningRequested,
//                         activeColor: Colors.green,
//                         onChanged: (bool? value) {
//                           setState(() {
//                             cleaningRequested = value ?? false;
//                           });
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//                 actions: [
//                   TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     child: const Text('Cancel'),
//                   ),
//                   ElevatedButton(
//                     onPressed: () {
//                       if (quantityController.text.isEmpty) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(
//                             content: Text('Please enter milk quantity'),
//                           ),
//                         );
//                         return;
//                       }

//                       _schedulePickup(
//                         distributor,
//                         double.parse(quantityController.text),
//                         selectedDate,
//                         selectedTime,
//                         cleaningRequested,
//                       );

//                       Navigator.pop(context);
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                     ),
//                     child: const Text('Schedule Pickup'),
//                   ),
//                 ],
//               );
//             },
//           ),
//     );
//   }

//   Future<void> _schedulePickup(
//     Map<String, dynamic> distributor,
//     double quantity,
//     DateTime date,
//     TimeOfDay time,
//     bool cleaningRequested,
//   ) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('You must be logged in to schedule a pickup'),
//           ),
//         );
//         return;
//       }

//       // Get farmer details from _farmerDetails or fetch again if needed
//       String farmerName = _farmerDetails['name'] ?? 'Farmer';
//       String farmerPhone = _farmerDetails['phone'] ?? '';
//       String farmerEmail = _farmerDetails['email'] ?? '';
//       String farmerLocation = _farmerDetails['location'] ?? '';

//       // If _farmerDetails is empty, try to fetch again
//       if (_farmerDetails.isEmpty) {
//         final farmerDoc = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(user.uid)
//             .get();

//         if (farmerDoc.exists) {
//           final farmerData = farmerDoc.data() ?? {};
//           farmerName = farmerData['name'] ?? user.displayName ?? 'Farmer';
//           farmerPhone = farmerData['phone'] ?? '';
//           farmerEmail = farmerData['email'] ?? '';
//           farmerLocation = farmerData['location'] ?? '';
//         }
//       }

//       // Combine date and time
//       final pickupDateTime = DateTime(
//         date.year,
//         date.month,
//         date.day,
//         time.hour,
//         time.minute,
//       );

//       // Calculate total amount (potentially including cleaning fee)
//       double cleaningFee = cleaningRequested ? 20.0 : 0.0; // Example fee of ₹20
//       double totalAmount = (quantity * distributor['base_price']) + cleaningFee;

//       // Create pickup request with location details from farmer's registration
//       await FirebaseFirestore.instance.collection('milk_pickups').add({
//         'distributor_id': distributor['id'],
//         'distributor_name': distributor['name'],
//         'farmer_id': user.uid,
//         'farmer_name': farmerName,
//         'farmer_phone': farmerPhone,
//         'farmer_email': farmerEmail,
//         'farmer_location': farmerLocation,
//         'formatted_address': _formattedAddress,
//         'quantity': quantity,
//         'base_price': distributor['base_price'],
//         'total_amount': totalAmount,
//         'pickup_date': Timestamp.fromDate(pickupDateTime),
//         'status': 'scheduled',
//         'cleaning_requested': cleaningRequested,
//         'cleaning_fee': cleaningFee,
//         'created_at': FieldValue.serverTimestamp(),
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Pickup scheduled with ${distributor['name']}'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error scheduling pickup: $e')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Available Milk Suppliers'),
//         backgroundColor: Colors.green,
//       ),
//       body:
//           _isLoading
//               ? const Center(child: CircularProgressIndicator())
//               : _distributors.isEmpty
//               ? Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.search_off,
//                       size: 64,
//                       color: Colors.grey.shade400,
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       'No suppliers found',
//                       style: TextStyle(
//                         fontSize: 18,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Check back later for available milk suppliers',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey.shade500,
//                       ),
//                     ),
//                   ],
//                 ),
//               )
//               : Column(
//                   children: [
//                     if (_farmerDetails.containsKey('location') &&
//                         _farmerDetails['location'] != null &&
//                         _farmerDetails['location'].toString().isNotEmpty)
//                       Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Card(
//                           elevation: 2,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.all(12.0),
//                             child: Row(
//                               children: [
//                                 Icon(Icons.location_on, color: Colors.green),
//                                 const SizedBox(width: 8),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       const Text(
//                                         'Your registered location:',
//                                         style: TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 14,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 4),
//                                       Text(
//                                         _formattedAddress.isNotEmpty
//                                             ? _formattedAddress
//                                             : _farmerDetails['location'],
//                                         style: TextStyle(
//                                           fontSize: 13,
//                                           color: Colors.grey.shade700,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     Expanded(
//                       child: RefreshIndicator(
//                         onRefresh: _loadDistributors,
//                         child: ListView.builder(
//                           padding: const EdgeInsets.all(16.0),
//                           itemCount: _distributors.length,
//                           itemBuilder: (context, index) {
//                             final distributor = _distributors[index];
//                             return Card(
//                               elevation: 4,
//                               margin: const EdgeInsets.only(bottom: 16),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Padding(
//                                 padding: const EdgeInsets.all(16.0),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Row(
//                                       children: [
//                                         CircleAvatar(
//                                           backgroundColor: Colors.green.shade100,
//                                           child: Text(
//                                             distributor['name'].isNotEmpty
//                                                 ? distributor['name'][0].toUpperCase()
//                                                 : 'D',
//                                             style: TextStyle(
//                                               color: Colors.green.shade700,
//                                               fontWeight: FontWeight.bold,
//                                             ),
//                                           ),
//                                         ),
//                                         const SizedBox(width: 12),
//                                         Expanded(
//                                           child: Column(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.start,
//                                             children: [
//                                               Text(
//                                                 distributor['name'],
//                                                 style: const TextStyle(
//                                                   fontSize: 18,
//                                                   fontWeight: FontWeight.bold,
//                                                 ),
//                                               ),
//                                               if (distributor['location'].isNotEmpty)
//                                                 Text(
//                                                   distributor['location'],
//                                                   style: TextStyle(
//                                                     color: Colors.grey.shade600,
//                                                   ),
//                                                 ),
//                                             ],
//                                           ),
//                                         ),
//                                         if (distributor['phone'].isNotEmpty)
//                                           IconButton(
//                                             icon: Icon(
//                                               Icons.phone,
//                                               color: Colors.green.shade700,
//                                             ),
//                                             onPressed: () {
//                                               // Implement phone call functionality
//                                             },
//                                           ),
//                                       ],
//                                     ),
//                                     const SizedBox(height: 16),
//                                     Container(
//                                       padding: const EdgeInsets.all(12),
//                                       decoration: BoxDecoration(
//                                         color: Colors.green.shade50,
//                                         borderRadius: BorderRadius.circular(8),
//                                         border: Border.all(
//                                           color: Colors.green.shade200,
//                                         ),
//                                       ),
//                                       child: Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceBetween,
//                                         children: [
//                                           const Text(
//                                             'Current Milk Price:',
//                                             style: TextStyle(
//                                               fontWeight: FontWeight.w500,
//                                             ),
//                                           ),
//                                           Text(
//                                             '₹${distributor['base_price'].toStringAsFixed(2)} per liter',
//                                             style: const TextStyle(
//                                               fontSize: 16,
//                                               fontWeight: FontWeight.bold,
//                                               color: Colors.green,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                     const SizedBox(height: 8),
//                                     Text(
//                                       'Last Updated: ${DateFormat('dd MMM yyyy, hh:mm a').format(distributor['updated_at'])}',
//                                       style: TextStyle(
//                                         fontSize: 12,
//                                         color: Colors.grey.shade600,
//                                         fontStyle: FontStyle.italic,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 16),
//                                     Row(
//                                       children: [
//                                         Expanded(
//                                           child: ElevatedButton.icon(
//                                             onPressed:
//                                                 () => _showSchedulePickupDialog(
//                                                   distributor,
//                                                 ),
//                                             icon: const Icon(Icons.schedule),
//                                             label: Text(
//                                               'Schedule Pickup with ${distributor['name']}',
//                                             ),
//                                             style: ElevatedButton.styleFrom(
//                                               backgroundColor: Colors.green,
//                                               padding: const EdgeInsets.symmetric(
//                                                 vertical: 12,
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' as intl;
import 'package:geocoding/geocoding.dart';

class DistributorPricesScreen extends StatefulWidget {
  const DistributorPricesScreen({Key? key}) : super(key: key);

  @override
  State<DistributorPricesScreen> createState() =>
      _DistributorPricesScreenState();
}

class _DistributorPricesScreenState extends State<DistributorPricesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _distributors = [];
  Map<String, dynamic> _farmerDetails = {};
  String _formattedAddress = "";

  @override
  void initState() {
    super.initState();
    _loadFarmerDetails();
    _loadDistributors();
  }

  Future<void> _loadFarmerDetails() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final farmerDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (farmerDoc.exists) {
          final farmerData = farmerDoc.data() ?? {};
          setState(() {
            _farmerDetails = farmerData;
          });

          // If location coordinates are available, try to get a readable address
          if (farmerData.containsKey('location') &&
              farmerData['location'] != null &&
              farmerData['location'].toString().isNotEmpty) {
            _getAddressFromCoordinates(farmerData['location']);
          }
        }
      }
    } catch (e) {
      print('Error loading farmer details: $e');
    }
  }

  Future<void> _getAddressFromCoordinates(String locationString) async {
    try {
      // Parse the location string to get latitude and longitude
      final locationParts = locationString.split(',');
      if (locationParts.length == 2) {
        final latitude = double.tryParse(locationParts[0].trim());
        final longitude = double.tryParse(locationParts[1].trim());

        if (latitude != null && longitude != null) {
          // Use the geocoding package to get a readable address
          List<Placemark> placemarks = await placemarkFromCoordinates(
            latitude,
            longitude,
          );
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            setState(() {
              _formattedAddress =
                  '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
            });
          }
        }
      }
    } catch (e) {
      print('Error getting address from coordinates: $e');
    }
  }

  Future<void> _loadDistributors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all distributors who have set milk prices
      final querySnapshot =
          await FirebaseFirestore.instance.collection('milk_prices').get();

      final distributors = await Future.wait(
        querySnapshot.docs.map((doc) async {
          final data = doc.data();
          final distributorId = data['distributor_id'] ?? '';

          // Ensure we get the actual distributor name
          String distributorName = data['distributor_name'] ?? '';

          // If distributor_name is empty or not available, try to get it from users collection
          if (distributorName.isEmpty ||
              distributorName == 'Unknown Distributor') {
            try {
              final distributorDoc =
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(distributorId)
                      .get();

              if (distributorDoc.exists) {
                final distributorData = distributorDoc.data();
                distributorName =
                    distributorData?['name'] ?? 'Unknown Distributor';

                // Update the milk_prices document with the correct name if needed
                if (distributorName != 'Unknown Distributor' &&
                    distributorName != data['distributor_name']) {
                  await FirebaseFirestore.instance
                      .collection('milk_prices')
                      .doc(doc.id)
                      .update({'distributor_name': distributorName});
                }
              }
            } catch (e) {
              // Fallback to default if error occurs
              distributorName =
                  distributorName.isEmpty
                      ? 'Unknown Distributor'
                      : distributorName;
            }
          }

          final basePrice = (data['base_price'] ?? 0.0).toDouble();
          DateTime updatedAt = DateTime.now();

          // Handle the Timestamp null issue
          if (data['updated_at'] != null) {
            updatedAt = (data['updated_at'] as Timestamp).toDate();
          }

          // Get distributor profile info if available
          String location = '';
          String phoneNumber = '';

          try {
            final distributorDoc =
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(distributorId)
                    .get();

            if (distributorDoc.exists) {
              final distributorData = distributorDoc.data();
              location = distributorData?['address'] ?? '';
              phoneNumber = distributorData?['phone'] ?? '';
            }
          } catch (e) {
            // Ignore errors fetching additional info
          }

          return {
            'id': distributorId,
            'name': distributorName,
            'base_price': basePrice,
            'updated_at': updatedAt,
            'location': location,
            'phone': phoneNumber,
          };
        }).toList(),
      );

      setState(() {
        _distributors = distributors;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading distributors: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSchedulePickupDialog(Map<String, dynamic> distributor) {
    final TextEditingController quantityController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(
      hour: 6,
      minute: 0,
    ); // Default to 6 AM
    bool cleaningRequested = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Schedule Pickup with ${distributor['name']}'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Price: ₹${distributor['base_price'].toStringAsFixed(2)} per liter',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Milk Quantity (liters)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.water_drop),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      if (_farmerDetails.containsKey('location') &&
                          _farmerDetails['location'] != null &&
                          _farmerDetails['location'].toString().isNotEmpty)
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
                              const Text(
                                'Your location will be shared with the distributor:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.blue.shade700,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _formattedAddress.isNotEmpty
                                          ? _formattedAddress
                                          : _farmerDetails['location'],
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No location found in your profile. The distributor may not be able to locate you.',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      const Text(
                        'Pickup Date:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ListTile(
                        title: Text(
                          intl.DateFormat('dd MMM yyyy').format(selectedDate),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 14),
                            ),
                          );
                          if (pickedDate != null &&
                              pickedDate != selectedDate) {
                            setState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pickup Time:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ListTile(
                        title: Text(selectedTime.format(context)),
                        trailing: const Icon(Icons.access_time),
                        onTap: () {
                          _showRestrictedTimePickerDialog(
                            context,
                            selectedTime,
                            (newTime) {
                              setState(() {
                                selectedTime = newTime;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('Request container cleaning'),
                        subtitle: const Text('Additional charges may apply'),
                        value: cleaningRequested,
                        activeColor: Colors.green,
                        onChanged: (bool? value) {
                          setState(() {
                            cleaningRequested = value ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (quantityController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter milk quantity'),
                          ),
                        );
                        return;
                      }

                      _schedulePickup(
                        distributor,
                        double.parse(quantityController.text),
                        selectedDate,
                        selectedTime,
                        cleaningRequested,
                      );

                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Schedule Pickup'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showRestrictedTimePickerDialog(
    BuildContext context,
    TimeOfDay currentTime,
    Function(TimeOfDay) onTimeSelected,
  ) {
    // Create lists of allowed times
    final List<TimeOfDay> morningTimes = [
      const TimeOfDay(hour: 6, minute: 0),
      const TimeOfDay(hour: 6, minute: 30),
      const TimeOfDay(hour: 7, minute: 0),
      const TimeOfDay(hour: 7, minute: 30),
      const TimeOfDay(hour: 8, minute: 0),
      const TimeOfDay(hour: 8, minute: 30),
      const TimeOfDay(hour: 9, minute: 0),
      const TimeOfDay(hour: 9, minute: 30),
      const TimeOfDay(hour: 10, minute: 0),
    ];

    final List<TimeOfDay> eveningTimes = [
      const TimeOfDay(hour: 16, minute: 0), // 4 PM
      const TimeOfDay(hour: 16, minute: 30),
      const TimeOfDay(hour: 17, minute: 0),
      const TimeOfDay(hour: 17, minute: 30),
      const TimeOfDay(hour: 18, minute: 0),
      const TimeOfDay(hour: 18, minute: 30),
      const TimeOfDay(hour: 19, minute: 0), // 7 PM
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Pickup Time'),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Morning (6 AM - 10 AM)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        morningTimes.map((time) {
                          final isSelected =
                              time.hour == currentTime.hour &&
                              time.minute == currentTime.minute;
                          return ElevatedButton(
                            onPressed: () {
                              onTimeSelected(time);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected ? Colors.green : null,
                              foregroundColor: isSelected ? Colors.white : null,
                            ),
                            child: Text(time.format(context)),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Evening (4 PM - 7 PM)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        eveningTimes.map((time) {
                          final isSelected =
                              time.hour == currentTime.hour &&
                              time.minute == currentTime.minute;
                          return ElevatedButton(
                            onPressed: () {
                              onTimeSelected(time);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected ? Colors.green : null,
                              foregroundColor: isSelected ? Colors.white : null,
                            ),
                            child: Text(time.format(context)),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _schedulePickup(
    Map<String, dynamic> distributor,
    double quantity,
    DateTime date,
    TimeOfDay time,
    bool cleaningRequested,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to schedule a pickup'),
          ),
        );
        return;
      }

      // Get farmer details from _farmerDetails or fetch again if needed
      String farmerName = _farmerDetails['name'] ?? 'Farmer';
      String farmerPhone = _farmerDetails['phone'] ?? '';
      String farmerEmail = _farmerDetails['email'] ?? '';
      String farmerLocation = _farmerDetails['location'] ?? '';

      // If _farmerDetails is empty, try to fetch again
      if (_farmerDetails.isEmpty) {
        final farmerDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (farmerDoc.exists) {
          final farmerData = farmerDoc.data() ?? {};
          farmerName = farmerData['name'] ?? user.displayName ?? 'Farmer';
          farmerPhone = farmerData['phone'] ?? '';
          farmerEmail = farmerData['email'] ?? '';
          farmerLocation = farmerData['location'] ?? '';
        }
      }

      // Combine date and time
      final pickupDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      // Calculate total amount (potentially including cleaning fee)
      double cleaningFee = cleaningRequested ? 20.0 : 0.0; // Example fee of ₹20
      double totalAmount = (quantity * distributor['base_price']) + cleaningFee;

      // Create pickup request with location details from farmer's registration
      await FirebaseFirestore.instance.collection('milk_pickups').add({
        'distributor_id': distributor['id'],
        'distributor_name': distributor['name'],
        'farmer_id': user.uid,
        'farmer_name': farmerName,
        'farmer_phone': farmerPhone,
        'farmer_email': farmerEmail,
        'farmer_location': farmerLocation,
        'formatted_address': _formattedAddress,
        'quantity': quantity,
        'base_price': distributor['base_price'],
        'total_amount': totalAmount,
        'pickup_date': Timestamp.fromDate(pickupDateTime),
        'status': 'scheduled',
        'cleaning_requested': cleaningRequested,
        'cleaning_fee': cleaningFee,
        'created_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pickup scheduled with ${distributor['name']}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error scheduling pickup: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Milk Suppliers'),
        backgroundColor: Colors.green,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _distributors.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No suppliers found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for available milk suppliers',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  if (_farmerDetails.containsKey('location') &&
                      _farmerDetails['location'] != null &&
                      _farmerDetails['location'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Your registered location:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formattedAddress.isNotEmpty
                                          ? _formattedAddress
                                          : _farmerDetails['location'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadDistributors,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _distributors.length,
                        itemBuilder: (context, index) {
                          final distributor = _distributors[index];
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 16),
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
                                      CircleAvatar(
                                        backgroundColor: Colors.green.shade100,
                                        child: Text(
                                          distributor['name'].isNotEmpty
                                              ? distributor['name'][0]
                                                  .toUpperCase()
                                              : 'D',
                                          style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              distributor['name'],
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (distributor['location']
                                                .isNotEmpty)
                                              Text(
                                                distributor['location'],
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (distributor['phone'].isNotEmpty)
                                        IconButton(
                                          icon: Icon(
                                            Icons.phone,
                                            color: Colors.green.shade700,
                                          ),
                                          onPressed: () {
                                            // Implement phone call functionality
                                          },
                                        ),
                                    ],
                                  ),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Current Milk Price:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '₹${distributor['base_price'].toStringAsFixed(2)} per liter',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Last Updated: ${intl.DateFormat('dd MMM yyyy, hh:mm a').format(distributor['updated_at'])}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              () => _showSchedulePickupDialog(
                                                distributor,
                                              ),
                                          icon: const Icon(Icons.schedule),
                                          label: Text(
                                            'Schedule Pickup with ${distributor['name']}',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}



