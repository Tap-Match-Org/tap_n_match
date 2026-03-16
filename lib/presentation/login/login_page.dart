import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter username and password')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userId = data['user_id'];
        
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            '/menu',
            arguments: {'user_id': userId},
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid username or password')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $e')),
        );
      }
    }
  }

  Widget _buildOutlinedTitle(String text) {
    return Stack(
      children: [
        // The Black Outline
        Text(
          text,
          style: GoogleFonts.pixelifySans(
            fontSize: 39,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5.0
              ..color = Colors.black,
          ),
        ),
        // The White Fill
        Text(
          text,
          style: GoogleFonts.pixelifySans(
            fontSize: 39,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  InputDecoration _pixelInput(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.pixelifySans(color: Colors.grey.shade600, fontSize: 18),
      filled: true,
      fillColor: const Color(0xFFD9D9D9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.black, width: 3),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.black, width: 3),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFFD8B4F8),
              Color(0xFF7B1FA2),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFAED9E0), Color(0xFF89AFCF)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.black, width: 4),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildOutlinedTitle('Login to Continue'),
                  ),
                  const SizedBox(height: 30),
                  // USERNAME FIELD
                  TextField(
                    controller: _emailController,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.pixelifySans(fontSize: 18),
                    decoration: _pixelInput('Username'),
                    textInputAction: TextInputAction.next, // Moves focus to next field
                  ),
                  const SizedBox(height: 15),
                  // PASSWORD FIELD
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.pixelifySans(fontSize: 18),
                    decoration: _pixelInput('Password'),
                    textInputAction: TextInputAction.done, // Shows "Done" or "Enter"
                    onSubmitted: (value) => _handleLogin(),
                  ),
                  const SizedBox(height: 15),
                  // LOGIN BUTTON
                  ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD8B4F8),
                      side: const BorderSide(color: Colors.black, width: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'CONNECT',
                      style: GoogleFonts.pixelifySans(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.black
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed('/register'),
                    child: Text(
                      "Don't Have An Account?",
                      style: GoogleFonts.pixelifySans(
                        fontSize: 18, 
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}