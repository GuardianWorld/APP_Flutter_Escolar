import 'package:flutter/material.dart';
import 'package:g_app/login_page.dart';
import 'package:g_app/socket_service.dart';
import 'package:g_app/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SocketService socketService = SocketService();
  String? _sessionToken;

  @override
  void initState() {
    super.initState();
    _loadSession();
    socketService.connect();
  }

  _loadSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _sessionToken = prefs.getString('session_token');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: _sessionToken == null
          ? LoginPage(socketService: socketService)
          : HomePage(socketService: socketService),
    );
  }
}