import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Military Map',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final List<_IconMarker> _iconMarkers = [];
  final List<LatLng> _explosionMarkers = [];
  final List<Polyline> _polylines = [];
  LatLng? _selectedPosition;

  void _addIconMarker(LatLng position, String iconPath) {
    setState(() {
      _iconMarkers.add(_IconMarker(position, iconPath));
    });
  }

  Future<void> _showIconSelectionDialog(LatLng position) async {
    final String? selectedIcon = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Icon'),
          content: Container(
            width: double.minPositive,
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              children: [
                'assets/tank.png',
                'assets/60 MM_motor.png',
                'assets/120MM_motor.png',
                'assets/122.png',
                'assets/missile.png',
                'assets/supply_force.png',
                'assets/su30.png',
                'assets/attack_helicopter.png',
                'assets/MI-39_ jet_fighter.png',
                'assets/y-12_aircraft.png',
                'assets/section.png',
                'assets/platoon.png',
                'assets/company.png',
                'assets/battalion.png',
                'assets/corps.png',
                'assets/enemy.png',
                // Add more icon paths here
              ].map((iconPath) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context, iconPath);
                  },
                  child: Image.asset(iconPath),
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    if (selectedIcon != null) {
      _addIconMarker(position, selectedIcon);
    }
  }

  Future<void> _showFireTestDialog(_IconMarker marker) async {
    if (marker.iconPath == 'assets/enemy.png') {
      return;
    }

    double selectedMill = 0;
    final TextEditingController distanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Fire Test Options'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Select Mill'),
                  Slider(
                    value: selectedMill,
                    min: 0,
                    max: 6399,
                    divisions: 6399,
                    label: selectedMill.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        selectedMill = value;
                      });
                    },
                  ),
                  TextField(
                    controller: distanceController,
                    decoration: InputDecoration(labelText: 'Enter Distance'),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      double distance =
                          double.tryParse(distanceController.text) ?? 0.0;
                      LatLng explosionPosition = _calculateTargetPosition(
                          marker.position, selectedMill, distance);

                      setState(() {
                        _explosionMarkers.add(explosionPosition);
                        _polylines.add(Polyline(
                          points: [marker.position, explosionPosition],
                          strokeWidth: 5.0,
                          gradientColors: [
                            Color.fromARGB(255, 1, 7, 92),
                            Color.fromARGB(255, 8, 208, 235)
                          ],
                        ));
                      });

                      Navigator.of(context).pop();
                    },
                    child: Text('Fire Test'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  LatLng _calculateTargetPosition(LatLng start, double mill, double distance) {
    // Convert mill to radians
    final double angle = mill * (2 * pi / 6400);

    // Calculate the target position
    final double deltaLat = distance * 0.000009 * cos(angle);
    final double deltaLng = distance * 0.000009 * sin(angle);

    return LatLng(start.latitude + deltaLat, start.longitude + deltaLng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Military Map')),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(51.5, -0.09),
          zoom: 13.0,
          onTap: (_, position) {
            _showIconSelectionDialog(position);
          },
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          PolylineLayer(
            polylines: _polylines,
          ),
          MarkerLayer(
            markers: _iconMarkers.map((marker) {
              return Marker(
                width: 40.0,
                height: 40.0,
                point: marker.position,
                builder: (ctx) => GestureDetector(
                  onTap: () => _showFireTestDialog(marker),
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(marker.iconPath),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          MarkerLayer(
            markers: _explosionMarkers.map((position) {
              return Marker(
                width: 40.0,
                height: 40.0,
                point: position,
                builder: (ctx) => Icon(
                  Icons.adjust_rounded,
                  color: Colors.red,
                  size: 40,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _IconMarker {
  final LatLng position;
  final String iconPath;

  _IconMarker(this.position, this.iconPath);
}
