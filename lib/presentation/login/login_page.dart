import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http; // 1. Added HTTP import
import 'dart:convert'; // Needed for jsonEncode

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  
  // 2. Added a loading variable
  bool _isLoading = false;

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

  // 3. THE HTTP LOGIN FUNCTION
  Future<void> _loginUser() async {
    setState(() => _isLoading = true);

    try {
      // NOTE: Use 'http://10.0.2.2:8000/login' if using Android Emulator
      // Use 'http://127.0.0.1:8000/login' if using Chrome/Web
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/login'), 
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _emailController.text,
          "password": _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        // Success! Go to menu
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/menu');
        }
      } else {
        // Show error message if login fails
        final errorData = jsonDecode(response.body);
        _showError(errorData['detail'] ?? 'Login Failed');
      }
    } catch (e) {
      _showError("Can't connect to server. Is FastAPI running?");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.pixelifySans())),
    );
  }

  // --- Your UI Methods ---
  Widget _buildOutlinedTitle(String text) {
    return Stack(
      children: [
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
            colors: [Color(0xFFD8B4F8), Color(0xFF7B1FA2)],
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
                  TextField(
                    controller: _emailController,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.pixelifySans(fontSize: 18),
                    decoration: _pixelInput('Username'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.pixelifySans(fontSize: 18),
                    decoration: _pixelInput('Password'),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) => _loginUser(), // Trigger login on enter
                  ),
                  const SizedBox(height: 25),
                  
                  // Login Button with Loading Spinner
                  _isLoading 
                    ? const CircularProgressIndicator(color: Colors.black)
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        ),
                        onPressed: _loginUser, 
                        child: Text("LOGIN", style: GoogleFonts.pixelifySans(color: Colors.white)),
                      ),
                      
                  const SizedBox(height: 20),
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