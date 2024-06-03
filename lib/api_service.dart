import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:5000';

  //Basic API calls

  static Future<http.Response> register(Map<String, dynamic> data) async {    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      
      return response;
    } catch (e) {
      rethrow; // Rethrow the exception to propagate it upwards
    }
  }

  static Future<http.Response> login(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    return response;
  }

  //Profile API calls

   static Future<http.Response> fetchProfile(String token) async {
    return await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
    );
  }

  static Future<http.Response> fetchChildren(String token) async {
    return await http.get(
      Uri.parse('$baseUrl/children'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
    );
  }

  static Future<http.Response> fetchChildrenWithoutDriver(String token) async {
    return await http.get(
      Uri.parse('$baseUrl/children/without_driver'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
    );
  }

  static Future<http.Response> addChild(Map<String, dynamic> data, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/children'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: json.encode(data),
    );
    return response;
  }

  static Future<http.Response> removeChild(int childId, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/children'),
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
      body: json.encode({'child_id': childId}),
    );
    return response;
  }

  //Driver API calls
    static Future<http.Response> fetchDriverProfile(String token) async {
    return await http.get(
      Uri.parse('$baseUrl/driver/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
    );
  }

  static Future<http.Response> fetchDriverChildren(String token) async {
    return await http.get(
      Uri.parse('$baseUrl/driver/children'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
    );
  }

  static Future<http.Response> fetchDriverSchools(String token) async {
    return await http.get(
      Uri.parse('$baseUrl/driver/schools'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
    );
  }

  static Future<http.Response> linkSchool(String schoolName, String token) {
    return http.post(
      Uri.parse('$baseUrl/link_school'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token, 
      },
      body: jsonEncode({'school_name': schoolName}),
    );
  }

    static Future<http.Response> addSchool(String schoolName, String schoolAddress, String token) {
    return http.post(
      Uri.parse('$baseUrl/add_school'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token, 
      },
      body: jsonEncode({'school_name': schoolName, 'school_address': schoolAddress}),
    );
  }

  static Future<http.Response> fetchAllSchools(String token) {
    return http.get(
      Uri.parse('$baseUrl/schools'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token
        },
    );
  }

  static Future<http.Response> fetchAllDriversInASchool(String schoolName, String token) {
    return http.post(
      Uri.parse('$baseUrl/school/drivers'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: jsonEncode({'school_name': schoolName}),
    );
  }

  static Future<http.Response> sendNotification(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    return response;
  }

  static Future<http.Response> fetchNotifications(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
    );
    return response;
  }

  static Future<http.Response> sendContractNotification(String driverID, String childID, String schoolName, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/contract_notification'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: json.encode({'driver_id': driverID, 'child_id': childID, 'school_name': schoolName}),
    );
    return response;
  }

  static Future<http.Response> acceptContract(String token, String notificationId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/accept_contract'),
      headers: {'Authorization': token},
      body: {'notification_id': notificationId},
    );
    return response;
  }

  static Future<http.Response> rejectContract(String token, String notificationId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reject_contract'),
      headers: {'Authorization': token},
      body: {'notification_id': notificationId},
    );
    return response;
  }

  static Future<http.Response> acknowledgeNotification(String token, String notificationId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/acknowledge_notification'),
      headers: {'Authorization': token},
      body: {'notification_id': notificationId},
    );
    return response;
  }

  static Future<http.Response> removeChildContract(String token, String childId) async {
  final response = await http.post(
    Uri.parse('$baseUrl/remove_child_contract'),
    headers: {
      'Authorization': token,
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'child_id': childId}),
  );
  return response;
}

  static Future<http.Response> markChildAsAbsent(int childID, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notify_absence'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: json.encode({'child_id': childID}),
    );
    return response;
  }

}