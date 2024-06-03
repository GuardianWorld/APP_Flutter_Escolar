import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:g_app/api_service.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class ServiceAreaPage extends StatefulWidget {
  @override
  _ServiceAreaPageState createState() => _ServiceAreaPageState();
}

class _ServiceAreaPageState extends State<ServiceAreaPage> {
  TextEditingController _schoolController = TextEditingController();
  List<String> allSchools = [];
  List<Map<String, String>> drivers = [];
  List<Map<String, String>> childrenWithoutDriver = [];
  String? selectedChildId;
  String? selectedSchoolName;

  @override
  void initState() {
    super.initState();
    _fetchAllSchools();
  }

  Future<void> _fetchAllSchools() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('session_token');

    if (token != null) {
      final response = await ApiService.fetchAllSchools(token);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          allSchools = List<String>.from(data['schools']);
        });
      } else {
        _showErrorDialog('Um erro ocorreu: ${response.statusCode}');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchDrivers(String schoolName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('session_token');

    if (token != null) {
      final response = await ApiService.fetchAllDriversInASchool(schoolName, token);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            selectedSchoolName = schoolName;
            drivers = List<Map<String, String>>.from(
              (data['drivers'] as List).map((driver) => {
                'id': driver['id'].toString(),
                'name': driver['name'].toString()
              })
            );
          });
        } else {
          _showErrorDialog(data['message'] ?? 'Unknown error occurred');
        }
      } else {
        _showErrorDialog('Um erro ocorreu: ${response.statusCode}');
      }
    }
  }

  Future<void> _fetchChildrenWithoutDriver() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('session_token');

    if (token != null) {
      final response = await ApiService.fetchChildrenWithoutDriver(token);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          childrenWithoutDriver = List<Map<String, String>>.from(
            (data['children'] as List).map((child) => {
              'id': child['id'].toString(),
              'name': child['name'].toString()
            })
          );
        });
      } else {
        _showErrorDialog('Um erro ocorreu: ${response.statusCode}');
      }
    }
  }

void _showContractDialog(String driverId, String driverName, String schoolID) async {
  await _fetchChildrenWithoutDriver();

  showDialog(
    context: context,
    builder: (context) {
      // Wrap the dialog content in a StatefulBuilder
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Contratar Motorista: $driverName'),
            content: DropdownButton<String>(
              hint: const Text('Selecionar Criança'),
              value: selectedChildId,
              onChanged: (newValue) {
                setState(() {
                  selectedChildId = newValue;
                });
              },
              items: childrenWithoutDriver.map((child) {
                return DropdownMenuItem(
                  value: child['id'],
                  child: Text(child['name']!),
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  _contractDriverToChild(driverId, selectedChildId!, schoolID);
                  Navigator.pop(context);
                },
                child: const Text('Confirmar'),
              ),
            ],
          );
        },
      );
    },
  );
}

  Future<void> _contractDriverToChild(String driverId, String childId, String schoolName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('session_token');

    if (token != null) {
      final response = await ApiService.sendContractNotification(driverId, childId, schoolName, token);

      if (response.statusCode == 200) {
        // Handle success, maybe show a success message or update the state
      } else {
        _showErrorDialog('Um erro ocorreu: ${response.statusCode}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TypeAheadField<String>(
            textFieldConfiguration: TextFieldConfiguration(
              controller: _schoolController,
              decoration: const InputDecoration(
                labelText: 'Procurar pelo nome da escola',
                border: OutlineInputBorder(),
              ),
            ),
            suggestionsCallback: (pattern) {
              return allSchools.where((school) => school.toLowerCase().contains(pattern.toLowerCase()));
            },
            itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion),
                );
            },
            onSuggestionSelected: (suggestion) {
              _schoolController.text = suggestion;
              _fetchDrivers(suggestion);
            },
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: drivers.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(drivers[index]['name']!),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _showContractDialog(drivers[index]['id']!, drivers[index]['name']!, selectedSchoolName!);
                    },
                    child: const Text('Contratar'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
