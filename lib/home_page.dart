import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:g_app/socket_service.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {
  final SocketService socketService;

  const HomePage({Key? key, required this.socketService}) : super(key: key);

  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_token');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(socketService: socketService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Bem vindo a pagina inicial!'),
            ElevatedButton(
              onPressed: () {
                // Example of sending location data
                socketService.sendLocation({
                  'latitude': 37.7749,
                  'longitude': -122.4194,
                });
              },
              child: const Text('Enviando Localização!'),
            ),
            const SizedBox(height: 20), // Add spacing
            ElevatedButton(
              onPressed: () => logout(context), // Call logout function
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}