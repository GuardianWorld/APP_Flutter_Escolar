import 'package:flutter/material.dart';
import 'package:g_app/home_page.dart';
import 'package:g_app/register_page.dart';
import 'package:g_app/socket_service.dart';
import 'package:g_app/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LoginPage extends StatefulWidget {
  final SocketService socketService;

  LoginPage({super.key, required this.socketService});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _cpfController,
                decoration: const InputDecoration(labelText: 'CPF'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'CPF não pode ser vazio.';
                  }
                  if (value.length != 11) {
                    return 'CPF tem que ter 11 digitos';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Senha'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Senha não pode ser vazia';
                  }
                  if (value.length < 6) {
                    return 'Senha tem que ser de no mínimo 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    final response = await ApiService.login({
                      'cpf': _cpfController.text,
                      'password': _passwordController.text,
                    });

                    if (response.statusCode == 200) {
                      final responseData = jsonDecode(response.body);
                      final token = responseData['token'];
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                       await prefs.setString('session_token', token);
                       await prefs.setString('user_type', responseData['user_type']);
                      // Login successful, navigate to home page
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomePage(socketService: widget.socketService),
                        ),
                      );
                    } else {
                      // Handle login error
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Error'),
                          content: const Text('Login falhou. Tente novamente.'),
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
                },
                child: const Text('Login'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegisterPage(socketService: widget.socketService),
                    ),
                  );
                },
                child: const Text('Registrar'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                },
                child: const Text('Sair'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
