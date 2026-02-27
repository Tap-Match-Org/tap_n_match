import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Helper for the White Outlined Titles
  Widget _buildOutlinedTitle(String text) {
    return Stack(
      children: [
        Text(
          text,
          style: GoogleFonts.pixelifySans(
            fontSize: 40,
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
            fontSize: 40,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Helper for consistent Pixel-style TextFields
  InputDecoration _pixelInput(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.pixelifySans(color: Colors.grey.shade600, fontSize: 18),
      filled: true,
      fillColor: const Color(0xFFD9D9D9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          // Radial Gradient background: Light to Dark Purple
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFFD8B4F8), // Light Purple
              Color(0xFF7B1FA2), // Dark Purple
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 35),
              decoration: BoxDecoration(
                // Blue box gradient
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
                  // Title on the side
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildOutlinedTitle('Create New Account'),
                  ),
                  const SizedBox(height: 25),

                  // Gmail Field + Send Code Button Row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _emailController,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.pixelifySans(),
                          decoration: _pixelInput('Gmail'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          // TODO: Implement Firebase Auth Send Code
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            // Blue gradient for the button
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF64B5F6), Color(0xFF1976D2)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black, width: 2.5),
                          ),
                          child: Stack(
                            children: [
                              // Text Outline
                              Text(
                                'Send Code',
                                style: GoogleFonts.pixelifySans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  foreground: Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = 2.5
                                    ..color = Colors.black,
                                ),
                              ),
                              // Text Fill
                              Text(
                                'Send Code',
                                style: GoogleFonts.pixelifySans(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Username Field
                  TextField(
                    controller: _usernameController,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.pixelifySans(),
                    decoration: _pixelInput('Username'),
                  ),
                  const SizedBox(height: 12),

                  // Password Field
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.pixelifySans(),
                    decoration: _pixelInput('Password'),
                  ),
                  const SizedBox(height: 25),

                  // Footer Link
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      "Already Have An Account?",
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