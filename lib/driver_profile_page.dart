import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:g_app/api_service.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class DriverProfilePage extends StatefulWidget {
  @override
  _DriverProfilePageState createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  String carPlate = "...";
  String driverName = "...";
  //int totalChildren = 0;
  List<Map<String, String>> children = [];
  List<String> schools = [];
  List<String> allSchools = [];
  TextEditingController schoolController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDriverProfile();
    _fetchSchools();
    _fetchChildren();
  }

  Future<void> _fetchDriverProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('session_token');

    if (token != null) {
      final response = await ApiService.fetchDriverProfile(token);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          carPlate = data['plate'];
          driverName = data['name'];
        });
      } else {
        _showErrorDialog('Um erro ocorreu: ${response.statusCode}');
      }
    }
  }

  Future<void> _fetchChildren() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('session_token');

    if (token != null) {
      final response = await ApiService.fetchDriverChildren(token);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);
        setState(() {
          children = List<Map<String, String>>.from(
            (data['children'] as List).map((child) => {
              'id': child['id'].toString(),
              'name': child['name'].toString(),
              'school': child['school'].toString(),
              'address': child['address'].toString(),
            })
          );
        });
      } else if(response.statusCode == 404) {
        _showErrorDialog('Um erro ocorreu: ${response.statusCode}');
      }
    }
  }

  Future<void> _fetchSchools() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('session_token');

    if (token != null) {
      final response = await ApiService.fetchDriverSchools(token);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          schools = List<String>.from(data['schools'].map((school) => school['name']));
        });
      } else if(response.statusCode == 404) {
        _showErrorDialog('Um erro ocorreu: ${response.statusCode}');
      }
    }
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

  Future<void> _linkSchool(String schoolName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('session_token');

    if (token != null) {
      final response = await ApiService.linkSchool(schoolName, token);

      if (response.statusCode == 200) {
        _fetchSchools();
      } else {
        _showErrorDialog('Um erro ocorreu: ${response.statusCode}');
      }
    }
  }

  Future<void> _addSchool(String schoolName, String schoolAddress) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('session_token');

    if (token != null) {
      final response = await ApiService.addSchool(schoolName, schoolAddress, token);

      if (response.statusCode == 200) {
        _fetchSchools();
      } else if(response.statusCode == 404) {
        _showErrorDialog('Um erro ocorreu: ${response.statusCode}');
      }
    }
  }

  Future<void> _removeChildContract(String childId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('session_token');

  if (token != null) {
    final response = await ApiService.removeChildContract(token, childId);

    if (response.statusCode == 200) {
      setState(() {
        children.removeWhere((child) => child['id'] == childId);
      });
    } else {
      _showErrorDialog('Erro ao remover a criança: ${response.statusCode}');
    }
  }
}

 void _showAddSchoolDialog() {
  TextEditingController newSchoolController = TextEditingController();
  TextEditingController newSchoolAddressController = TextEditingController();
  
  _fetchAllSchools();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Adicionar Escola'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TypeAheadField<String>(
              textFieldConfiguration: TextFieldConfiguration(
                controller: newSchoolController,
                decoration: const InputDecoration(labelText: 'Nome da Escola'),
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
                newSchoolController.text = suggestion;
              },
            ),
            TextField(
              controller: newSchoolAddressController,
              decoration: const InputDecoration(labelText: 'Endereço da Escola'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await _addSchool(newSchoolController.text, newSchoolAddressController.text);
              await _linkSchool(newSchoolController.text);
              Navigator.pop(context);
            },
            child: const Text('Adicionar'),
          ),
        ],
      );
    },
  );
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

  Future<void> _confirmRemoveChild(String childId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Remoção'),
          content: Text('Você tem certeza que quer remover?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Remover'),
              onPressed: () {
                Navigator.of(context).pop();
                _removeChildContract(childId);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Perfil do Motorista', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('Nome: $driverName', style: const TextStyle(fontSize: 18)),
          Text('Placa do veiculo: $carPlate', style: const TextStyle(fontSize: 18)),
          //Text('Total matriculado: $totalChildren', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          const Text('Escolas:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...schools.map((school) => Text(school)).toList(),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _showAddSchoolDialog(),
            child: const Text('Adicionar Escolas'),
          ),
          const SizedBox(height: 20),
          const Text('Matriculados:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...children.map((child) {
            return ListTile(
              title: Text(child['name']!),
              subtitle: Text('Escola: ${child['school']}\nEndereço: ${child['address']}\n'),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle),
                onPressed: () => _confirmRemoveChild(child['id']!),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
