import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:5000';

  static Future<http.Response> register(Map<String, dynamic> data) async {
    print('Sending registration request with data: $data');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      print('Received registration response: ${response.statusCode} ${response.body}');
      
      return response;
    } catch (e) {
      print('Error sending registration request: $e');
      throw e; // Rethrow the exception to propagate it upwards
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

  static Future<http.Response> addChild(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/children'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    return response;
  }

  static Future<http.Response> sendNotification(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    return response;
  }
}