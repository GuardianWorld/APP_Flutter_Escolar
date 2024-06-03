import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:g_app/socket_service.dart';
import 'login_page.dart';
import 'package:g_app/profile_page.dart';
import 'package:g_app/driver_profile_page.dart';
import 'package:g_app/service_page.dart';
import 'package:g_app/notification_page.dart';

class HomePage extends StatefulWidget {
  final SocketService socketService;

  const HomePage({Key? key, required this.socketService}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool isDriver = false;
  late List<Widget> _pages;

  @override
  void initState(){
    super.initState();
    _loadUserType();
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_token');
    await prefs.remove('user_type');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(socketService: widget.socketService),
      ),
    );
  }

  Future<void> _loadUserType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userType = prefs.getString('user_type');

    setState(() {
      isDriver = userType == 'driver';
      _initializePages();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

   void _initializePages() {
    _pages = [
      ProfilePage(),
      if (isDriver) DriverProfilePage(),
      ServiceAreaPage(),
      NotificationPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('APP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
          if(isDriver)
            const BottomNavigationBarItem(
              icon: Icon(Icons.drive_eta),
              label: 'Perfil do Motorista',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Area de Serviço',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notificações',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}