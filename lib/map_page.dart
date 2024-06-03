import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:g_app/api_service.dart';
import 'dart:async';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // ignore: unused_field
  late Timer _locationUpdateTimer;
  List<Map<String, String>> _markers = [];
  bool _isDriver = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _fetchDriversLocations();
  }

  void _checkUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('user_type');
    setState(() {
      _isDriver = role == 'driver';
      if(_isDriver){
        _startLocationUpdates();
      }
        //Initialize a empty MARKER with LOADING.
        _markers = [
          {
            'id': '0',
            'name': 'Carregando...',
            'latitude': '0',
            'longitude': '0',
            'street_name': 'Carregando...',
          }
        ];
    });
  }

  void _fetchDriversLocations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('session_token');

    if (token != null) {
      final response = await ApiService.getMapLocations(token);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _markers = List<Map<String, String>>.from(
            (data['drivers'] as List).map((driver) => {
              'id': driver['id'].toString(),
              'name': driver['name'].toString(),
              'latitude': driver['latitude'].toString(),
              'longitude': driver['longitude'].toString(),
              'street_name': driver['street_name'].toString(),
            })
          );
        });
      }
    }
  }

   void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      Position position = await Geolocator.getCurrentPosition();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('session_token');

      if (token != null) {
        Map<String, double> locationData = {
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
        await ApiService.updateLocation(locationData, token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Localização dos motoristas'),
      ),
      body: ListView.builder(
        itemCount: _markers.length,
        itemBuilder: (context, index) {
          final driver = _markers[index];
          return ListTile(
            title: Text(driver['name']!),
            subtitle: Text('Latitude: ${driver['latitude']}, Longitude: ${driver['longitude']}\n${driver['street_name']}'),
          );
        },
      ),
    );
  }
}
