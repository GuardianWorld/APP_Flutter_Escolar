import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:g_app/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = "...";
  String cpf = "...";
  List<Map<String, String>> children = [];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _fetchChildren();
  }

  Future<void> _fetchProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('session_token');
    String? role = prefs.getString('user_type');
    print(role);

    if (token != null) {
      final response = await ApiService.fetchProfile(token);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userName = data['name'];
          cpf = data['cpf'];
        });
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Um erro ocorreu: ${response.statusCode}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
    if(role == 'driver'){
      _startLocationUpdates();
    }
  }

  Future<void> _fetchChildren() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('session_token');

    if (token != null) {
      final response = await ApiService.fetchChildren(token);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          children = List<Map<String, String>>.from(
            (data['children'] as List).map((child) => {
              'id': child['id'].toString(),
              'name': child['name'].toString(),
              'driver_name': child['driver_name'].toString(),
              'driver_id': child['driver_id'].toString(),
              'school': child['school'].toString(),
              'address': child['address'].toString(),
            })
          );
        });
      }else{
          showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Um erro ocorreu: ${response.statusCode}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _addChild(String name, String school, String address) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('session_token');

    if (token != null) {
      final response = await ApiService.addChild({
        'name': name,
        'school': school,
        'address': address
      }, token);

      if (response.statusCode == 200) {
        _fetchChildren();
      }
    }
  }

    Future<void> _confirmRemoveChild(int childId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Remoção'),
          content: const Text('Você tem certeza que quer remover?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Remover'),
              onPressed: () {
                Navigator.of(context).pop();
                _removeChild(childId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeChild(int childId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('session_token');

    if (token != null) {
      final response = await ApiService.removeChild(childId, token);

      if (response.statusCode == 200) {
        _fetchChildren();
      }
    }
  }
  
  Future<void> _markChildAsAbsent(int childId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('session_token');

    if (token != null) {
      final response = await ApiService.markChildAsAbsent(childId, token);

      if (response.statusCode != 200) {
       showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Um erro ocorreu: ${response.statusCode}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      else{
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sucesso'),
            content: const Text('Motorista notificado com sucesso!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
  
  void _showAddChildDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController schoolController = TextEditingController();
    final TextEditingController addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar Filho'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: schoolController,
                decoration: const InputDecoration(labelText: 'Escola'),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Endereço'),
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
              onPressed: () {
                _addChild(
                  nameController.text,
                  schoolController.text,
                  addressController.text
                );
                Navigator.pop(context);
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }
  
  void _startLocationUpdates() async {
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
  }
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView (
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nome: $userName', style: const TextStyle(fontSize: 18)),
          Text('CPF: $cpf', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          const Text('Filhos:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...children.map((child) {
            return ListTile(
              title: Text(child['name']!),
              subtitle: Text(
                'Escola: ${child['school']} \n'
                'Nome do Motorista: ${child['driver_name']} \n' 
                'Endereço: ${child['address']}'
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (child['driver_id'] != null && child['driver_id'] != 'null')
                  IconButton(
                    icon: const Icon(Icons.warning),
                    onPressed: () => _markChildAsAbsent(int.parse(child['id']!)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _confirmRemoveChild(int.parse(child['id']!)),
                  ),
                ],
              ),
            );
          }).toList(),
          ElevatedButton(
            onPressed: () => _showAddChildDialog(),
            child: const Text('Adicionar Filho'),
          ),
        ],
      ),
    );
  }

  
}
