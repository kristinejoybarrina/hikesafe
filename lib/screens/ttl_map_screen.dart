import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TTLMapScreen extends StatefulWidget {
  const TTLMapScreen({super.key});

  @override
  State<TTLMapScreen> createState() => _TTLMapScreenState();
}

class _TTLMapScreenState extends State<TTLMapScreen> {
  Set<Marker> _ttlMarkers = {};

  @override
  void initState() {
    super.initState();
    _loadTTLMarkers();
  }

  void _loadTTLMarkers() {
    // Example TTL-based locations
    final List<Map<String, dynamic>> ttlNodes = [
      {'lat': 14.5896, 'lng': 121.0566, 'ttl': 1},
      {'lat': 14.5900, 'lng': 121.0575, 'ttl': 2},
    ];

    Set<Marker> markers = {};
    for (var node in ttlNodes) {
      final LatLng pos = LatLng(node['lat'], node['lng']);
      final ttl = node['ttl'];

      markers.add(
        Marker(
          markerId: MarkerId('$pos'),
          position: pos,
          infoWindow: InfoWindow(title: 'Mesh Node (TTL $ttl)'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            200.0 - ttl * 40, // Fades as TTL increases
          ),
        ),
      );
    }

    setState(() {
      _ttlMarkers = markers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mesh Map View')),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(14.5896, 121.0566),
          zoom: 15,
        ),
        markers: _ttlMarkers,
      ),
    );
  }
}
