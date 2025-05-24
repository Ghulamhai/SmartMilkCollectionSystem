// // 30.971878, 76.473240 - college gate
// // 30.961715, 76.507586 - one location
// // 30.958810, 76.531694 - another location
// // 30.933178, 76.538471



// //  OPENSTREET AND FOR OPTIMIZATION GRAPHHOPPER

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapRouteWidget extends StatefulWidget {
  const MapRouteWidget({super.key});

  @override
  State<MapRouteWidget> createState() => _MapRouteWidgetState();
}

class _MapRouteWidgetState extends State<MapRouteWidget> {
  List<latlng.LatLng> _polylinePoints = [];
  final MapController _mapController = MapController();
  String _errorMessage = '';

  // Hardcoded locations
  final List<latlng.LatLng> _locations = [
    latlng.LatLng(30.971878, 76.473240), // College gate
    latlng.LatLng(30.961715, 76.507586), // Location 1
    latlng.LatLng(30.958810, 76.531694), // Location 2
    latlng.LatLng(30.933178, 76.538471), // Location 3
  ];

  final String graphHopperApiKey = 'f14f8078-1422-457c-978c-67c9a9210fb7';
  final String optimizationUrl = 'https://graphhopper.com/api/1/vrp';
  final String routingUrl = 'https://graphhopper.com/api/1/route';

  @override
  void initState() {
    super.initState();
    _getOptimizedRoute();
  }

  Future<void> _getOptimizedRoute() async {
    try {
      final body = {
        "vehicles": [
          {
            "vehicle_id": "driver_1",
            "start_address": {
              "location_id": "depot",
              "lat": _locations[0].latitude,
              "lon": _locations[0].longitude,
            },
            "end_address": {
              "location_id": "depot",
              "lat": _locations[0].latitude,
              "lon": _locations[0].longitude,
            },
          },
        ],
        "services": _locations.sublist(1).asMap().entries.map((entry) {
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

      final optimizationResponse = await http.post(
        Uri.parse('$optimizationUrl?key=$graphHopperApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (optimizationResponse.statusCode != 200) {
        setState(() {
          _errorMessage = 'Optimization API error: ${optimizationResponse.statusCode}';
        });
        return;
      }

      final optimizationData = jsonDecode(optimizationResponse.body);
      final activities = optimizationData['solution']?['routes']?[0]?['activities'] ?? [];

      List<int> waypointOrder = activities
          .where((activity) => activity['type'] == 'service')
          .map<int>((activity) => int.parse(activity['id'].split('_')[1]) - 1)
          .toList();

      List<latlng.LatLng> optimizedLocations = [_locations[0]];
      for (int index in waypointOrder) {
        optimizedLocations.add(_locations[index + 1]);
      }
      optimizedLocations.add(_locations[0]);

      List<latlng.LatLng> allPoints = [];
      PolylinePoints polylinePoints = PolylinePoints();

      for (int i = 0; i < optimizedLocations.length - 1; i++) {
        final start = optimizedLocations[i];
        final end = optimizedLocations[i + 1];
        String url = '$routingUrl?point=${start.latitude},${start.longitude}'
            '&point=${end.latitude},${end.longitude}&type=json&points_encoded=true&key=$graphHopperApiKey';

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
        _errorMessage = allPoints.isEmpty ? 'No valid routes found.' : '';
        if (_polylinePoints.isNotEmpty) {
          final bounds = _calculateBounds(_polylinePoints);
          _mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: EdgeInsets.all(50)),
          );
        } else {
          _mapController.move(_locations[0], 13.0);
        }
      });
    } catch (e) {
      setState(() {
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _locations[0],
            initialZoom: 13.0,
            minZoom: 10.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: ['a', 'b', 'c'],
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
              markers: _locations.map((loc) {
                return Marker(
                  point: loc,
                  width: 40,
                  height: 40,
                  child: Icon(Icons.location_pin, color: Colors.red, size: 36),
                );
              }).toList(),
            ),
          ],
        ),
        if (_errorMessage.isNotEmpty)
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                color: Colors.red.withOpacity(0.7),
                padding: const EdgeInsets.all(8),
                child: Text(_errorMessage, style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
      ],
    );
  }
}



// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart' as latlng;
// import 'package:http/http.dart' as http;
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';


// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(home: MapScreen());
//   }
// }

// class MapScreen extends StatefulWidget {
//   @override
//   _MapScreenState createState() => _MapScreenState();
// }

// class _MapScreenState extends State<MapScreen> {
//   List<latlng.LatLng> _polylinePoints = [];
//   final MapController _mapController = MapController();
//   String _errorMessage = '';

//   // Hardcoded locations (latitude, longitude) in San Francisco
//   final List<latlng.LatLng> _locations = [
//     latlng.LatLng(30.971878, 76.473240), // Depot: San Francisco
//     latlng.LatLng(30.961715, 76.507586), // Point 1
//     latlng.LatLng(30.958810, 76.531694), // Point 2
//     latlng.LatLng(30.933178, 76.538471), // Point 3
//   ];

//   // GraphHopper API Key (replace with your own from graphhopper.com if rate-limited)
//   final String graphHopperApiKey = 'f14f8078-1422-457c-978c-67c9a9210fb7';
//   final String optimizationUrl = 'https://graphhopper.com/api/1/vrp';
//   final String routingUrl = 'https://graphhopper.com/api/1/route';

//   @override
//   void initState() {
//     super.initState();
//     _getOptimizedRoute();
//   }

//   Future<void> _getOptimizedRoute() async {
//     try {
//       // Step 1: Get optimized order from Route Optimization API
//       final body = {
//         "vehicles": [
//           {
//             "vehicle_id": "driver_1",
//             "start_address": {
//               "location_id": "depot",
//               "lat": _locations[0].latitude,
//               "lon": _locations[0].longitude,
//             },
//             "end_address": {
//               "location_id": "depot",
//               "lat": _locations[0].latitude,
//               "lon": _locations[0].longitude,
//             },
//           },
//         ],
//         "services":
//             _locations.sublist(1).asMap().entries.map((entry) {
//               int idx = entry.key;
//               latlng.LatLng loc = entry.value;
//               return {
//                 "id": "location_${idx + 1}",
//                 "address": {
//                   "location_id": "loc_${idx + 1}",
//                   "lat": loc.latitude,
//                   "lon": loc.longitude,
//                 },
//               };
//             }).toList(),
//       };

//       print('Requesting optimized order from GraphHopper...');
//       print('Optimization request body: ${jsonEncode(body)}');
//       final optimizationResponse = await http.post(
//         Uri.parse('$optimizationUrl?key=$graphHopperApiKey'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode(body),
//       );

//       print('Optimization response status: ${optimizationResponse.statusCode}');
//       print('Optimization response body: ${optimizationResponse.body}');
//       if (optimizationResponse.statusCode != 200) {
//         setState(() {
//           _errorMessage =
//               'Optimization API error: ${optimizationResponse.statusCode}. Check API key or rate limits.';
//         });
//         print('Optimization API error: ${optimizationResponse.body}');
//         return;
//       }

//       final optimizationData = jsonDecode(optimizationResponse.body);
//       if (optimizationData['solution'] == null) {
//         setState(() {
//           _errorMessage =
//               'No route found. Check API key, locations, or rate limits.';
//         });
//         print('No solution found in optimization response: $optimizationData');
//         return;
//       }

//       // Get optimized order of locations
//       final activities =
//           optimizationData['solution']['routes'][0]['activities'];
//       print('Activities: $activities');
//       List<int> waypointOrder =
//           activities
//               .where((activity) => activity['type'] == 'service')
//               .map<int>((activity) {
//                 final index = int.parse(activity['id'].split('_')[1]) - 1;
//                 print('Parsed index from ${activity['id']}: $index');
//                 return index;
//               })
//               .toList();

//       if (waypointOrder.isEmpty) {
//         setState(() {
//           _errorMessage =
//               'No service activities found in optimization response.';
//         });
//         print('Error: No service activities in activities list.');
//         return;
//       }

//       List<latlng.LatLng> optimizedLocations = [
//         _locations[0],
//       ]; // Start at depot
//       for (int index in waypointOrder) {
//         if (index + 1 < _locations.length) {
//           optimizedLocations.add(_locations[index + 1]);
//         } else {
//           print('Warning: Invalid index $index for locations list.');
//         }
//       }
//       optimizedLocations.add(_locations[0]); // Return to depot

//       // Print optimized order
//       print('Optimized location order:');
//       for (int i = 0; i < optimizedLocations.length; i++) {
//         print(
//           'Location ${i + 1}: (${optimizedLocations[i].latitude}, ${optimizedLocations[i].longitude})',
//         );
//       }

//       // Step 2: Fetch road-based routes for each segment
//       List<latlng.LatLng> allPoints = [];
//       PolylinePoints polylinePoints = PolylinePoints();

//       print('Fetching road-based routes for each segment...');
//       for (int i = 0; i < optimizedLocations.length - 1; i++) {
//         // Format coordinates as separate point parameters
//         final start = optimizedLocations[i];
//         final end = optimizedLocations[i + 1];
//         String point1 = '${start.latitude},${start.longitude}';
//         String point2 = '${end.latitude},${end.longitude}';
//         print('Segment ${i + 1} point1: $point1');
//         print('Segment ${i + 1} point2: $point2');

//         // Use separate point parameters
//         String url =
//             '$routingUrl?point=$point1&point=$point2&type=json&points_encoded=true&key=$graphHopperApiKey';
//         print('Routing request ${i + 1}: $url');

//         final routingResponse = await http.get(Uri.parse(url));
//         print(
//           'Routing response status ${i + 1}: ${routingResponse.statusCode}',
//         );
//         print('Routing response body ${i + 1}: ${routingResponse.body}');
//         if (routingResponse.statusCode == 200) {
//           final routingData = jsonDecode(routingResponse.body);
//           if (routingData['paths'] != null && routingData['paths'].isNotEmpty) {
//             String encodedPolyline = routingData['paths'][0]['points'];
//             print('Encoded polyline for segment ${i + 1}: $encodedPolyline');
//             List<PointLatLng> segmentPoints = polylinePoints.decodePolyline(
//               encodedPolyline,
//             );
//             List<latlng.LatLng> segmentLatLngs =
//                 segmentPoints
//                     .map((p) => latlng.LatLng(p.latitude, p.longitude))
//                     .toList();

//             print('Segment ${i + 1}: ${segmentLatLngs.length} points');
//             if (segmentLatLngs.isNotEmpty) {
//               print(
//                 '  First point: (${segmentLatLngs.first.latitude}, ${segmentLatLngs.first.longitude})',
//               );
//               print(
//                 '  Last point: (${segmentLatLngs.last.latitude}, ${segmentLatLngs.last.longitude})',
//               );
//             } else {
//               print('  Warning: No points decoded for segment ${i + 1}.');
//             }

//             allPoints.addAll(segmentLatLngs);
//           } else {
//             print('No path found for segment ${i + 1}: $routingData');
//           }
//         } else {
//           print(
//             'Routing API error for segment ${i + 1}: ${routingResponse.body}',
//           );
//         }
//       }

//       setState(() {
//         _polylinePoints = allPoints;
//         _errorMessage =
//             allPoints.isEmpty
//                 ? 'No valid routes found. Check console for API errors.'
//                 : '';
//         print('Total polyline points: ${_polylinePoints.length}');
//         // Fit map to bounds only if points exist
//         if (_polylinePoints.isNotEmpty) {
//           final bounds = _calculateBounds(_polylinePoints);
//           _mapController.fitCamera(
//             CameraFit.bounds(bounds: bounds, padding: EdgeInsets.all(50)),
//           );
//         } else {
//           print('Skipping fitCamera: No polyline points available.');
//           // Fallback: Center map on depot
//           _mapController.move(_locations[0], 13.0);
//         }
//       });
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Error fetching route: $e';
//       });
//       print('Error: $e');
//     }
//   }

//   LatLngBounds _calculateBounds(List<latlng.LatLng> points) {
//     if (points.isEmpty) {
//       print(
//         'Warning: _calculateBounds called with empty points. Returning depot bounds.',
//       );
//       return LatLngBounds(_locations[0], _locations[0]);
//     }

//     double minLat = points[0].latitude;
//     double maxLat = points[0].latitude;
//     double minLon = points[0].longitude;
//     double maxLon = points[0].longitude;

//     for (var point in points) {
//       if (point.latitude < minLat) minLat = point.latitude;
//       if (point.latitude > maxLat) maxLat = point.latitude;
//       if (point.longitude < minLon) minLon = point.longitude;
//       if (point.longitude > maxLon) maxLon = point.longitude;
//     }

//     return LatLngBounds(
//       latlng.LatLng(minLat, minLon),
//       latlng.LatLng(maxLat, maxLon),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Milk Collection Route')),
//       body: Stack(
//         children: [
//           FlutterMap(
//             mapController: _mapController,
//             options: MapOptions(
//               initialCenter: _locations[0],
//               initialZoom: 13.0,
//               minZoom: 10.0,
//               maxZoom: 18.0,
//             ),
//             children: [
//               TileLayer(
//                 urlTemplate:
//                     'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
//                 subdomains: ['a', 'b', 'c'],
//               ),
//               MarkerLayer(
//                 markers:
//                     _locations.asMap().entries.map((entry) {
//                       int idx = entry.key;
//                       latlng.LatLng loc = entry.value;
//                       return Marker(
//                         point: loc,
//                         child: Icon(
//                           Icons.location_pin,
//                           color: idx == 0 ? Colors.blue : Colors.red,
//                           size: 40,
//                         ),
//                       );
//                     }).toList(),
//               ),
//               PolylineLayer(
//                 polylines: [
//                   Polyline(
//                     points: _polylinePoints,
//                     strokeWidth: 5.0,
//                     color: Colors.blue,
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           if (_errorMessage.isNotEmpty)
//             Positioned(
//               bottom: 20,
//               left: 20,
//               right: 20,
//               child: Container(
//                 padding: EdgeInsets.all(10),
//                 color: Colors.red.withOpacity(0.8),
//                 child: Text(
//                   _errorMessage,
//                   style: TextStyle(color: Colors.white),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
