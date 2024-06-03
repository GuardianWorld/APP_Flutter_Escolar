import 'package:flutter/material.dart';
import 'package:g_app/socket_service.dart';
import 'package:g_app/api_service.dart';
class RegisterPage extends StatefulWidget {
  final SocketService socketService;

  const RegisterPage({super.key, required this.socketService});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  bool _isDriver = false;
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false; // Add a loading state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: SingleChildScrollView (
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
                    return 'CPF não pode estar vazio.';
                  }
                  if (value.length != 11) {
                    return 'CPF tem que ter 11 dígitos';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nome não pode estar vazio.';
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
                    return 'Senha tem que ter no mínimo 6 caracteres';
                  }
                  return null;
                },
              ),
              Row(
                children: [
                  const Text('Motorista?'),
                  Checkbox(
                    value: _isDriver,
                    onChanged: (bool? value) {
                      setState(() {
                        _isDriver = value ?? false;
                      });
                    },
                  ),
                ],
              ),
              if (_isDriver)
                Column(
                  children: [
                    TextFormField(
                      controller: _licenseController,
                      decoration: const InputDecoration(labelText: 'CNH'),
                      validator: (value) {
                        if (_isDriver && (value == null || value.isEmpty)) {
                          return 'CNH não pode ser vazia';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _plateController,
                      decoration: const InputDecoration(labelText: 'Placa do Veículo'),
                      validator: (value) {
                        if (_isDriver && (value == null || value.isEmpty)) {
                          return 'Placa do veículo não pode ser vazia';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator() // Show loading indicator if loading
              else
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      setState(() {
                        _isLoading = true; // Set loading state to true
                      });
                      try {
                        final response = await ApiService.register({
                          'cpf': _cpfController.text,
                          'name': _nameController.text,
                          'password': _passwordController.text,
                          'user_type': _isDriver ? 'driver' : 'user',
                          'license': _isDriver ? _licenseController.text : '',
                          'plate': _isDriver ? _plateController.text : '',
                        });
                        if (response.statusCode == 200) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Sucesso'),
                              content: const Text('Registrado com sucesso!'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Close the dialog
                                    Navigator.pop(context); // Go back to login page
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          // Handle registration error
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Error'),
                              content: Text('Falha no registro: ${response.body}'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      } catch (e) {
                        // Handle network error
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Error'),
                            content: Text('Um erro ocorreu: $e'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      } finally {
                        setState(() {
                          _isLoading = false; // Set loading state to false
                        });
                      }
                    }
                  },
                  child: const Text('Registrar'),
                ),
                const SizedBox(height: 20), // Additional spacing
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Go back to previous screen
                },
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}