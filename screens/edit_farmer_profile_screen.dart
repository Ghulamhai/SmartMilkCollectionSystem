import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditFarmerProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const EditFarmerProfileScreen({Key? key, required this.profileData}) : super(key: key);

  @override
  State<EditFarmerProfileScreen> createState() => _EditFarmerProfileScreenState();
}

class _EditFarmerProfileScreenState extends State<EditFarmerProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController locationController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.profileData['name']);
    phoneController = TextEditingController(text: widget.profileData['phone']);
    locationController = TextEditingController(text: widget.profileData['location']);
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    locationController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    // Update Firebase Firestore with new values
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'name': nameController.text,
      'phone': phoneController.text,
      'location': locationController.text,
    });

    Navigator.of(context).pop(); // Go back to the profile screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            TextFormField(
              controller: locationController,
              decoration: const InputDecoration(labelText: 'Village'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Save Changes'),
            )
          ],
        ),
      ),
    );
  }
}
