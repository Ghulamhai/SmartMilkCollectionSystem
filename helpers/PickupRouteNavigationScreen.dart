import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PickupRouteNavigationScreen extends StatefulWidget {
  final List<Map<String, dynamic>> pickups;
  
  const PickupRouteNavigationScreen({
    Key? key, 
    required this.pickups,
  }) : super(key: key);

  @override
  State<PickupRouteNavigationScreen> createState() => _PickupRouteNavigationScreenState();
}

class _PickupRouteNavigationScreenState extends State<PickupRouteNavigationScreen> {
  List<latlng.LatLng> _polylinePoints = [];
  final MapController _mapController = MapController();
  String _errorMessage = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _optimizedPickups = [];
  latlng.LatLng? _currentLocation;
  
  // GraphHopper API credentials
  final String graphHopperApiKey = 'f14f8078-1422-457c-978c-67c9a9210fb7';
  final String optimizationUrl = 'https://graphhopper.com/api/1/vrp';
  final String routingUrl = 'https://graphhopper.com/api/1/route';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }
  
  Future<void> _getCurrentLocation() async {
    // For this example, we'll use a hardcoded location
    // In a real app, you would use a location package like geolocator
    // to get the actual current location
    
    // Hardcoded location near Punjab (simulating current location)
    _currentLocation = latlng.LatLng(30.971878, 76.473240);
    
    // Once we have the current location, get the optimized route
    _getOptimizedRoute();
  }

  Future<void> _getOptimizedRoute() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Extract locations from pickups
      List<latlng.LatLng> locations = [];
      
      // Add current location as the starting point
      if (_currentLocation != null) {
        locations.add(_currentLocation!);
      } else {
        throw Exception('Current location not available');
      }
      
      // Add pickup locations
      for (var pickup in widget.pickups) {
        if (pickup['farmer_location'] != null && pickup['farmer_location'].isNotEmpty) {
          List<String> coordinates = pickup['farmer_location'].split(',');
          if (coordinates.length == 2) {
            double? lat = double.tryParse(coordinates[0].trim());
            double? lng = double.tryParse(coordinates[1].trim());
            if (lat != null && lng != null) {
              locations.add(latlng.LatLng(lat, lng));
            }
          }
        }
      }
      
      if (locations.length <= 1) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Not enough valid locations to create a route';
        });
        return;
      }
      
      // Prepare the optimization request
      final body = {
        "vehicles": [
          {
            "vehicle_id": "driver_1",
            "start_address": {
              "location_id": "depot",
              "lat": locations[0].latitude,
              "lon": locations[0].longitude,
            },
            "end_address": {
              "location_id": "depot",
              "lat": locations[0].latitude,
              "lon": locations[0].longitude,
            },
          },
        ],
        "services": locations.sublist(1).asMap().entries.map((entry) {
          int idx = entry.key;
          latlng.LatLng loc = entry.value;
          return {
            "id": "location_${idx + 1}",
            "address": {
              "location_id": "loc_${idx + 1}",
              "lat": loc.latitude,
              "lon": loc.longitude,
            },
          };
        }).toList(),
      };

      // Call the optimization API
      final optimizationResponse = await http.post(
        Uri.parse('$optimizationUrl?key=$graphHopperApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (optimizationResponse.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Optimization API error: ${optimizationResponse.statusCode}';
        });
        return;
      }

      // Process the optimization response
      final optimizationData = jsonDecode(optimizationResponse.body);
      final activities = optimizationData['solution']?['routes']?[0]?['activities'] ?? [];

      // Get the optimized order of waypoints
      List<int> waypointOrder = activities
          .where((activity) => activity['type'] == 'service')
          .map<int>((activity) => int.parse(activity['id'].split('_')[1]) - 1)
          .toList();

      // Reorder pickups based on the optimized route
      List<Map<String, dynamic>> optimizedPickups = [];
      for (int index in waypointOrder) {
        optimizedPickups.add(widget.pickups[index]);
      }
      
      // Create the optimized list of locations
      List<latlng.LatLng> optimizedLocations = [locations[0]];
      for (int index in waypointOrder) {
        optimizedLocations.add(locations[index + 1]);
      }
      optimizedLocations.add(locations[0]); // Return to start

      // Get the route polyline for the optimized path
      List<latlng.LatLng> allPoints = [];
      PolylinePoints polylinePoints = PolylinePoints();

      for (int i = 0; i < optimizedLocations.length - 1; i++) {
        final start = optimizedLocations[i];
        final end = optimizedLocations[i + 1];
        String url = '$routingUrl?point=${start.latitude},${start.longitude}'
            '&point=${end.latitude},${end.longitude}&vehicle=car&type=json&points_encoded=true&key=$graphHopperApiKey';

        final routingResponse = await http.get(Uri.parse(url));

        if (routingResponse.statusCode == 200) {
          final routingData = jsonDecode(routingResponse.body);
          if (routingData['paths'] != null && routingData['paths'].isNotEmpty) {
            String encodedPolyline = routingData['paths'][0]['points'];
            List<PointLatLng> segmentPoints = polylinePoints.decodePolyline(encodedPolyline);
            List<latlng.LatLng> segmentLatLngs = segmentPoints
                .map((p) => latlng.LatLng(p.latitude, p.longitude))
                .toList();
            allPoints.addAll(segmentLatLngs);
          }
        }
      }

      setState(() {
        _polylinePoints = allPoints;
        _optimizedPickups = optimizedPickups;
        _isLoading = false;
        _errorMessage = allPoints.isEmpty ? 'No valid routes found.' : '';
        
        if (_polylinePoints.isNotEmpty) {
          final bounds = _calculateBounds(_polylinePoints);
          _mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
          );
        } else if (locations.isNotEmpty) {
          _mapController.move(locations[0], 13.0);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching route: $e';
      });
    }
  }

  LatLngBounds _calculateBounds(List<latlng.LatLng> points) {
    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLon = points[0].longitude;
    double maxLon = points[0].longitude;

    for (var point in points) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLon = point.longitude < minLon ? point.longitude : minLon;
      maxLon = point.longitude > maxLon ? point.longitude : maxLon;
    }

    return LatLngBounds(
      latlng.LatLng(minLat, minLon),
      latlng.LatLng(maxLat, maxLon),
    );
  }
  
  Future<void> _openLocationInMaps(String location) async {
    if (location.isEmpty) return;
    
    try {
      final locationParts = location.split(',');
      if (locationParts.length == 2) {
        final latitude = double.tryParse(locationParts[0].trim());
        final longitude = double.tryParse(locationParts[1].trim());
        
        if (latitude != null && longitude != null) {
          final url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open maps application')),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening location: $e')),
      );
    }
  }
  
  Future<void> _callFarmer(String phone) async {
    if (phone.isEmpty) return;
    
    try {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not make a call')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error making call: $e')),
      );
    }
  }
  
  Future<void> _markPickupAsCompleted(String pickupId, Map<String, dynamic> pickup) async {
    try {
      // Update pickup status
      await FirebaseFirestore.instance
          .collection('milk_pickups')
          .doc(pickupId)
          .update({
            'status': 'completed',
            'updated_at': FieldValue.serverTimestamp(),
          });
      
      // Create transaction record
      await FirebaseFirestore.instance.collection('transactions').add({
        'farmer_id': pickup['farmer_id'],
        'distributor_id': FirebaseAuth.instance.currentUser?.uid,
        'pickup_id': pickupId,
        'farmer_name': pickup['farmer_name'],
        'distributor_name': pickup['distributor_name'] ?? '', 
        'quantity': pickup['quantity'],
        'price_per_liter': pickup['base_price'],
        'cleaning_fee': pickup['cleaning_requested'] == true ? (pickup['cleaning_fee'] ?? 20.0) : 0.0,
        'total_amount': pickup['total_amount'],
        'transaction_date': FieldValue.serverTimestamp(),
        'payment_status': 'paid',
        'payment_method': 'cash',
        'transaction_notes': '',
        'receipt_number': 'RCT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup completed and transaction recorded'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh the list
      setState(() {
        // Update the pickup in the optimized list
        for (int i = 0; i < _optimizedPickups.length; i++) {
          if (_optimizedPickups[i]['id'] == pickupId) {
            _optimizedPickups[i]['status'] = 'completed';
            break;
          }
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing pickup: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Route Navigation'),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getOptimizedRoute,
            tooltip: 'Refresh Route',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation ?? latlng.LatLng(30.971878, 76.473240),
                    initialZoom: 13.0,
                    minZoom: 10.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    if (_polylinePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _polylinePoints,
                            color: Colors.blue,
                            strokeWidth: 4.0,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        // Current location marker
                        if (_currentLocation != null)
                          Marker(
                            point: _currentLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.my_location, color: Colors.blue, size: 36),
                          ),
                        
                        // Pickup location markers
                        for (int i = 0; i < widget.pickups.length; i++)
                          if (widget.pickups[i]['farmer_location'] != null && 
                              widget.pickups[i]['farmer_location'].isNotEmpty)
                            Marker(
                              point: _getLatLngFromString(widget.pickups[i]['farmer_location']),
                              width: 40,
                              height: 40,
                              child: Stack(
                                children: [
                                  const Icon(Icons.location_pin, color: Colors.red, size: 36),
                                  Positioned(
                                    top: 3,
                                    left: 0,
                                    right: 0,
                                    child: Text(
                                      '${i + 1}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ],
                    ),
                  ],
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (_errorMessage.isNotEmpty)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        color: Colors.red.withOpacity(0.7),
                        padding: const EdgeInsets.all(8),
                        child: Text(_errorMessage, style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey.shade100,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.green.shade700,
                    child: Row(
                      children: [
                        const Icon(Icons.route, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Optimized Pickup Route (${_optimizedPickups.length} stops)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _optimizedPickups.isEmpty
                            ? const Center(child: Text('No pickups to display'))
                            : ListView.builder(
                                itemCount: _optimizedPickups.length,
                                itemBuilder: (context, index) {
                                  final pickup = _optimizedPickups[index];
                                  final pickupTime = pickup['pickup_date'] as DateTime;
                                  final status = pickup['status'] as String;
                                  final isCompleted = status == 'completed';
                                  
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.green.shade100,
                                        child: Text('${index + 1}'),
                                      ),
                                      title: Text(
                                        pickup['farmer_name'],
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            DateFormat('hh:mm a, EEE, MMM d').format(pickupTime),
                                            style: TextStyle(color: Colors.grey.shade700),
                                          ),
                                          Text(
                                            '${pickup['quantity']} liters - ₹${pickup['total_amount'].toStringAsFixed(2)}',
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (!isCompleted)
                                            IconButton(
                                              icon: const Icon(Icons.check_circle, color: Colors.green),
                                              onPressed: () => _markPickupAsCompleted(pickup['id'], pickup),
                                              tooltip: 'Complete',
                                            ),
                                          IconButton(
                                            icon: const Icon(Icons.phone, color: Colors.blue),
                                            onPressed: () => _callFarmer(pickup['farmer_phone']),
                                            tooltip: 'Call',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.directions, color: Colors.orange),
                                            onPressed: () => _openLocationInMaps(pickup['farmer_location']),
                                            tooltip: 'Directions',
                                          ),
                                        ],
                                      ),
                                      isThreeLine: true,
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  latlng.LatLng _getLatLngFromString(String locationString) {
    try {
      List<String> coordinates = locationString.split(',');
      if (coordinates.length == 2) {
        double? lat = double.tryParse(coordinates[0].trim());
        double? lng = double.tryParse(coordinates[1].trim());
        if (lat != null && lng != null) {
          return latlng.LatLng(lat, lng);
        }
      }
    } catch (e) {
      // Handle parsing errors
    }
    // Return a default location if parsing fails
    return latlng.LatLng(30.971878, 76.473240);
  }
}
