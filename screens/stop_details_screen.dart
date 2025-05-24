import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class StopDetailScreen extends StatefulWidget {
  final int stopNumber;

  const StopDetailScreen({Key? key, required this.stopNumber}) : super(key: key);

  @override
  State<StopDetailScreen> createState() => _StopDetailScreenState();
}

class _StopDetailScreenState extends State<StopDetailScreen> {
  File? _signatureImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _signatureImage = File(picked.path);
      });
    }
  }

  Future<void> _openMap() async {
    const url = 'https://www.google.com/maps/search/?api=1&query=18.5204,73.8567';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callFarmer() async {
    final Uri uri = Uri(scheme: 'tel', path: '+919999999999');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stop ${widget.stopNumber} Details'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Farmer Name: Ramesh Patil',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            ListTile(
              leading: const Icon(Icons.local_drink, color: Colors.blue),
              title: const Text('Milk Quantity'),
              subtitle: const Text('35 Liters'),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.orange),
              title: const Text('Status'),
              subtitle: const Text('Pending Collection'),
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.red),
              title: const Text('Location'),
              subtitle: const Text('Lat: 18.5204, Lng: 73.8567'),
              trailing: IconButton(
                icon: const Icon(Icons.map),
                onPressed: _openMap,
              ),
            ),

            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _callFarmer,
              icon: const Icon(Icons.phone),
              label: const Text('Call Farmer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade800,
                minimumSize: const Size.fromHeight(45),
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Upload Signature / Image for Verification',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _signatureImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_signatureImage!),
            )
                : OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Image'),
            ),

            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Marked as Collected')),
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark as Collected'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
