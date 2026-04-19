import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tap_n_match/core/api_config.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _codeController;
  
  bool _isLoading = false;
  bool _isSendingCode = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // --- BACKEND LOGIC ---
  Future<void> _sendCode() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showMsg("Please enter a valid Gmail address", isError: true);
      return;
    }
    setState(() => _isSendingCode = true);
    try {
      final response = await http.post(
        ApiConfig.getUri('/send-code'), // localhost for Chrome
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": _emailController.text}),
      );
      if (response.statusCode == 200) {
        _showMsg("Code sent to Gmail!", isError: false);
      } else {
        _showMsg("Failed to send code.", isError: true);
      }
    } catch (e) {
      _showMsg("Server Offline - Check VS Code Terminal", isError: true);
    } finally {
      setState(() => _isSendingCode = false);
    }
  }

  Future<void> _handleRegister() async {
    if (_usernameController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _confirmPasswordController.text.isEmpty || 
        _codeController.text.isEmpty) {
      _showMsg("Fill in all fields", isError: true);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showMsg("Passwords do not match", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        ApiConfig.getUri('/register'), // localhost for Chrome
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _usernameController.text,
          "email": _emailController.text,
          "password": _passwordController.text,
          "code": _codeController.text,
        }),
      );
      if (response.statusCode == 200) {
        _showMsg("Account Verified! Going to Login...", isError: false);
        if (mounted) Navigator.of(context).pop();
      } else {
        final error = jsonDecode(response.body);
        _showMsg(error['detail'] ?? "Error creating account", isError: true);
      }
    } catch (e) {
      _showMsg("Server Error", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMsg(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.pixelifySans(fontSize: 12)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --- UI HELPERS ---
  InputDecoration _pixelInput(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.pixelifySans(color: Colors.grey.shade600, fontSize: 12),
      filled: true,
      fillColor: const Color(0xFFD9D9D9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      isDense: true,
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.black, width: 2),
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
      resizeToAvoidBottomInset: true, 
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400), 
                padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFAED9E0), Color(0xFF89AFCF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 3),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Create Account',
                      style: GoogleFonts.pixelifySans(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // Gmail + Send Button Row
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _emailController, decoration: _pixelInput('Gmail'))),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _isSendingCode ? null : _sendCode,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: _isSendingCode ? Colors.grey : const Color(0xFF4A90E2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: Text(_isSendingCode ? '...' : 'Send',
                              style: GoogleFonts.pixelifySans(color: Colors.white, fontSize: 10)),
                          ),
                        ),                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Verification Code
                    TextField(
                      controller: _codeController,
                      textAlign: TextAlign.center,
                      decoration: _pixelInput('Enter 6-digit Code'),
                    ),
                    const SizedBox(height: 6),
                    
                    // Username
                    TextField(controller: _usernameController, decoration: _pixelInput('Username')),
                    const SizedBox(height: 6),

                    // Password Row
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _passwordController, obscureText: true, decoration: _pixelInput('Password'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: _confirmPasswordController, obscureText: true, decoration: _pixelInput('Confirm Password'))),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _isLoading 
                      ? const CircularProgressIndicator(color: Colors.black)
                      : SizedBox(
                          width: 160, 
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            onPressed: _handleRegister,
                            child: Text('VERIFY & SIGN UP', 
                              style: GoogleFonts.pixelifySans(color: Colors.white, fontSize: 13)),
                          ),
                        ),
                    
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Already have an account?",
                        style: GoogleFonts.pixelifySans(color: Colors.black, fontSize: 11),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
