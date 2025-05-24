import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditDistributorProfileScreen extends StatefulWidget {
  const EditDistributorProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditDistributorProfileScreen> createState() => _EditDistributorProfileScreenState();
}

class _EditDistributorProfileScreenState extends State<EditDistributorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _routeController = TextEditingController();
  final _milkCollectedController = TextEditingController();
  final _vehicleIdController = TextEditingController();

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
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _routeController.text = data['route'] ?? '';
        _milkCollectedController.text = data['milkCollected']?.toString() ?? '';
        _vehicleIdController.text = data['vehicleId'] ?? '';
      }
    } catch (e) {
      print('Error loading distributor profile: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'route': _routeController.text,
          'milkCollected': int.tryParse(_milkCollectedController.text) ?? 0,
          'vehicleId': _vehicleIdController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );

        Navigator.of(context).pop(); // Go back to profile screen
      } catch (e) {
        print('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _routeController.dispose();
    _milkCollectedController.dispose();
    _vehicleIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
                    ),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      validator: (value) => value == null || value.isEmpty ? 'Enter phone number' : null,
                      keyboardType: TextInputType.phone,
                    ),
                    TextFormField(
                      controller: _routeController,
                      decoration: const InputDecoration(labelText: 'Assigned Route'),
                      validator: (value) => value == null || value.isEmpty ? 'Enter route' : null,
                    ),
                    TextFormField(
                      controller: _milkCollectedController,
                      decoration: const InputDecoration(labelText: 'Milk Collected Today (Liters)'),
                      validator: (value) => value == null || value.isEmpty ? 'Enter milk collected' : null,
                      keyboardType: TextInputType.number,
                    ),
                    TextFormField(
                      controller: _vehicleIdController,
                      decoration: const InputDecoration(labelText: 'Vehicle ID'),
                      validator: (value) => value == null || value.isEmpty ? 'Enter vehicle ID' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
