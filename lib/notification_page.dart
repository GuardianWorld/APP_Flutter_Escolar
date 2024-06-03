import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:g_app/api_service.dart';
import 'package:g_app/notification.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<NotificationMessage> notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('session_token');

    if (token != null) {
      try {
        final response = await ApiService.fetchNotifications(token);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          //Make each notification a NotificationMessage object
          
          List<NotificationMessage> fetchedNotifications = [];
          for (var notification in data['notifications']) {
            fetchedNotifications.add(NotificationMessage(
              id: notification['id'].toString(),
              message: notification['message'],
              type: notification['type'],
            ));
          }

          setState(() {
            notifications = fetchedNotifications;
          });
        } else {
          _showErrorDialog('Um erro ocorreu: ${response.statusCode}');
        }
      } catch (e) {
        _showErrorDialog('Um erro ocorreu ao buscar as notificações');
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

  void _acceptContract(String notificationId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('session_token');

    if (token != null) {
      try {
        final response = await ApiService.acceptContract(token, notificationId);
        if (response.statusCode == 200) {
          // Update UI or fetch notifications again to refresh the list
          _fetchNotifications();
        } else {
          _showErrorDialog('Erro ao aceitar o contrato: ${response.statusCode}');
        }
      } catch (e) {
        _showErrorDialog('Erro ao aceitar o contrato');
      }
    }
  }

  void _rejectContract(String notificationId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('session_token');

    if (token != null) {
      try {
        final response = await ApiService.rejectContract(token, notificationId);
        if (response.statusCode == 200) {
          // Update UI or fetch notifications again to refresh the list
          _fetchNotifications();
        } else {
          _showErrorDialog('Erro ao rejeitar o contrato: ${response.statusCode}');
        }
      } catch (e) {
        _showErrorDialog('Erro ao rejeitar o contrato');
      }
    }
  }

  void _acknowledgeNotification(String notificationId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('session_token');

    if (token != null) {
      try {
        final response = await ApiService.acknowledgeNotification(token, notificationId);
        if (response.statusCode == 200) {
          // Update UI or fetch notifications again to refresh the list
          _fetchNotifications();
        } else {
          _showErrorDialog('Erro ao reconhecer a notificação: ${response.statusCode}');
        }
      } catch (e) {
        _showErrorDialog('Erro ao reconhecer a notificação');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];

          return ListTile(
            title: Text(notification.message),
            subtitle: notification.type == 'contract'
                ? Text('Contrato')
                : Text('Notificação'),
            trailing: notification.type == 'contract'
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _acceptContract(notification.id);
                        },
                        child: const Text('Accept'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          _rejectContract(notification.id);
                        },
                        child: const Text('Reject'),
                      ),
                    ],
                  )
                : ElevatedButton(
                    onPressed: () {
                      _acknowledgeNotification(notification.id);
                    },
                    child: const Text('OK'),
                  ),
          );
        },
      ),
    );
  }
}
