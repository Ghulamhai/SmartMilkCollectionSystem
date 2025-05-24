import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'DistributorStatisticsScreen.dart'; // Make sure to import DistributorStatisticsScreen

class AvailableDistributorsScreen extends StatelessWidget {
  const AvailableDistributorsScreen({Key? key}) : super(key: key);

  void _showTransactionDialog(BuildContext context, String distributorId) {
    final TextEditingController milkController = TextEditingController();
    final TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Milk Transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: milkController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Milk (litres)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price per litre (₹)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final String milkText = milkController.text.trim();
                final String priceText = priceController.text.trim();

                final double? milkInLitres = double.tryParse(milkText);
                final double? pricePerLitre = double.tryParse(priceText);

                if (milkInLitres == null ||
                    milkInLitres <= 0 ||
                    pricePerLitre == null ||
                    pricePerLitre <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter valid values')),
                  );
                  return;
                }

                final totalPrice = milkInLitres * pricePerLitre;
                final currentUser = FirebaseAuth.instance.currentUser;

                if (currentUser != null) {
                  // Record transaction
                  await FirebaseFirestore.instance
                      .collection('transactions')
                      .add({
                        'distributorId': distributorId,
                        'farmerId': currentUser.uid,
                        'milkInLitres': milkInLitres,
                        'pricePerLitre': pricePerLitre,
                        'totalPrice': totalPrice,
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                  // Update milk collected in distributor's profile
                  final distributorDoc = FirebaseFirestore.instance
                      .collection('users')
                      .doc(distributorId);

                  final distributorSnapshot = await distributorDoc.get();
                  if (distributorSnapshot.exists) {
                    final distributorData = distributorSnapshot.data()!;
                    final currentMilkCollected =
                        distributorData['milkCollected'] ?? 0;
                    await distributorDoc.update({
                      'milkCollected': currentMilkCollected + milkInLitres,
                    });
                  }

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaction recorded')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> distributorsStream =
        FirebaseFirestore.instance
            .collection('users')
            .where('userType', isEqualTo: 'Distributor')
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Distributors'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: distributorsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No distributors found.'));
          }

          final distributors = snapshot.data!.docs;

          return ListView.builder(
            itemCount: distributors.length,
            itemBuilder: (context, index) {
              final doc = distributors[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.local_shipping,
                    color: Colors.green,
                  ),
                  title: Text(data['name'] ?? 'No Name'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Phone: ${data['phone'] ?? 'N/A'}'),
                      Text('Email: ${data['email'] ?? 'N/A'}'),
                      Text('Vehicle ID: ${data['vehicleId'] ?? 'N/A'}'),
                      Text('Route: ${data['route'] ?? 'N/A'}'),
                      Text(
                        'Milk Collected: ${data['milkCollected']?.toString() ?? '0'} Litres',
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: ElevatedButton(
                    onPressed: () {
                      _showTransactionDialog(context, doc.id);
                    },
                    child: const Text('Transact'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                  onTap: () {
                    // Navigate to the DistributorStatisticsScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => DistributorStatisticsScreen(
                              distributorId: doc.id,
                            ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}


