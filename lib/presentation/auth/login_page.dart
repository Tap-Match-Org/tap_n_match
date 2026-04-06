import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tap_n_match/core/persistence_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _loadSavedUsername();
  }

  Future<void> _loadSavedUsername() async {
    final savedUsername = await PersistenceService.getUsername();
    if (savedUsername != null && mounted) {
      setState(() {
        _emailController.text = savedUsername;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    final username = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showError('Please enter username and password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userId = (data['user_id'] as num).toInt();
        final loggedInUsername = data['username'] as String;

        // Save session
        await PersistenceService.saveUserId(userId);
        await PersistenceService.saveUsername(loggedInUsername);
        
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            '/menu',
            arguments: {'user_id': userId},
          );
        }
      } else if (response.statusCode == 403) {
        final errorData = jsonDecode(response.body);
        final detail = errorData['detail'];
        String? reason;
        if (detail is Map) {
          reason = detail['reason'];
        }
        if (mounted) {
          Navigator.of(context).pushNamed(
            '/banned',
            arguments: {'reason': reason},
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showError(errorData['detail'] ?? 'Invalid username or password');
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

  Widget _buildOutlinedTitle(String text) {
    return Stack(
      children: [
        Text(
          text,
          style: GoogleFonts.pixelifySans(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4.0
              ..color = Colors.black,
          ),
        ),
        Text(
          text,
          style: GoogleFonts.pixelifySans(
            fontSize: 32,
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
      hintStyle: GoogleFonts.pixelifySans(color: Colors.grey.shade600, fontSize: 16),
      filled: true,
      fillColor: const Color(0xFFD9D9D9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 340),
              padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 23),
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
                  Center(
                    child: _buildOutlinedTitle('Login to Continue'),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.pixelifySans(fontSize: 18),
                    decoration: _pixelInput('Username'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.pixelifySans(fontSize: 18),
                    decoration: _pixelInput('Password'),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) => _loginUser(),
                  ),
                  
                  // --- APPLIED NEW STYLE TO CONNECT BUTTON ---
                  const SizedBox(height: 15),
                  _isLoading 
                    ? const CircularProgressIndicator(color: Colors.black)
                    : SizedBox(
                        width: 180, 
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: _loginUser,
                          child: Text(
                            'LOGIN', 
                            style: GoogleFonts.pixelifySans(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ),
                  
                  // --- APPLIED NEW STYLE TO FOOTER LINK ---
                  const SizedBox(height: 5),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/register'),
                    child: Text(
                      "Don't Have An Account?",
                      style: GoogleFonts.pixelifySans(color: Colors.black, fontSize: 12),
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
