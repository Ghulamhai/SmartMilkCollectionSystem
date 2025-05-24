import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MilkCollectionScreen extends StatefulWidget {
  final String userRole; // 'farmer' or 'distributor'

  MilkCollectionScreen({required this.userRole});

  @override
  _MilkCollectionScreenState createState() => _MilkCollectionScreenState();
}

class _MilkCollectionScreenState extends State<MilkCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
        _isLoading = false;
      });
    } else {
      // Wait for user to be available (fallback)
      await Future.delayed(Duration(seconds: 1));
      _loadUser();
    }
  }

  Future<void> _scheduleCollection() async {
    if (_formKey.currentState!.validate()) {
      await _firestore.collection('milk_collections').add({
        'farmerId': _currentUserId,
        'distributorId': 'distributor_abc', // Replace this with actual logic later
        'scheduledDate': _dateController.text,
        'scheduledTime': _timeController.text,
        'quantity': int.parse(_quantityController.text),
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _dateController.clear();
      _timeController.clear();
      _quantityController.clear();
    }
  }

  Future<void> _markAsDone(String docId) async {
    await _firestore.collection('milk_collections').doc(docId).update({
      'status': 'Done',
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Milk Collection"),
      ),
      body: Column(
        children: [
          if (widget.userRole == 'farmer')
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text("Schedule New Collection", style: TextStyle(fontSize: 18)),
                    TextFormField(
                      controller: _dateController,
                      decoration: InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                      validator: (value) => value!.isEmpty ? 'Enter date' : null,
                    ),
                    TextFormField(
                      controller: _timeController,
                      decoration: InputDecoration(labelText: 'Time (HH:MM)'),
                      validator: (value) => value!.isEmpty ? 'Enter time' : null,
                    ),
                    TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(labelText: 'Quantity (litres)'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Enter quantity' : null,
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _scheduleCollection,
                      child: Text("Schedule"),
                    ),
                  ],
                ),
              ),
            ),
          Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('milk_collections')
                  .where(
                    widget.userRole == 'farmer' ? 'farmerId' : 'distributorId',
                    isEqualTo: _currentUserId,
                  )
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error loading collections"));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(child: Text("No scheduled collections."));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text("Date: ${data['scheduledDate']} | Time: ${data['scheduledTime']}"),
                        subtitle: Text("Quantity: ${data['quantity']} L | Status: ${data['status']}"),
                        trailing: widget.userRole == 'distributor' && data['status'] == 'Pending'
                            ? ElevatedButton(
                                onPressed: () => _markAsDone(doc.id),
                                child: Text("Mark as Done"),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
