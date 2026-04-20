import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tap_n_match/repository/auth_repository.dart';

class RegisterPage extends StatefulWidget {
  final AuthRepository authRepository;

  RegisterPage({super.key, AuthRepository? authRepository})
      : authRepository = authRepository ?? AuthRepository();

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _codeController;
  
  bool _isLoading = false;
  bool _isSendingCode = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
    
    final success = await widget.authRepository.sendVerificationCode(_emailController.text);
    
    if (success) {
      _showMsg("Code sent to Gmail!", isError: false);
    } else {
      _showMsg("Failed to send code or Server Offline", isError: true);
    }
    
    if (mounted) setState(() => _isSendingCode = false);
  }

  Future<void> _handleRegister() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty || _codeController.text.isEmpty) {
      _showMsg("Fill in all fields", isError: true);
      return;
    }
    setState(() => _isLoading = true);

    final response = await widget.authRepository.register(
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      code: _codeController.text,
    );

    if (response.status == AuthStatus.success) {
      _showMsg("Account Verified! Going to Login...", isError: false);
      if (mounted) Navigator.of(context).pop();
    } else {
      _showMsg(response.errorMessage ?? "Error creating account", isError: true);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showMsg(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.pixelifySans()),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --- UI HELPERS ---
  InputDecoration _pixelInput(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.pixelifySans(color: Colors.grey.shade600, fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFD9D9D9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                constraints: const BoxConstraints(maxWidth: 420), 
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
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Gmail + Send Button Row
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _emailController, decoration: _pixelInput('Gmail'))),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _isSendingCode ? null : _sendCode,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _isSendingCode ? Colors.grey : const Color(0xFF4A90E2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: Text(_isSendingCode ? '...' : 'Send',
                              style: GoogleFonts.pixelifySans(color: Colors.white, fontSize: 11)),
                          ),
                        ),                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Verification Code
                    TextField(
                      controller: _codeController,
                      textAlign: TextAlign.center,
                      decoration: _pixelInput('Enter 6-digit Code'),
                    ),
                    const SizedBox(height: 8),
                    
                    // Side-by-Side Username and Password
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _usernameController, decoration: _pixelInput('Username'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: _passwordController, obscureText: true, decoration: _pixelInput('Password'))),
                      ],
                    ),
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
                            onPressed: _handleRegister,
                            child: Text('VERIFY & SIGN UP', 
                              style: GoogleFonts.pixelifySans(color: Colors.white, fontSize: 14)),
                          ),
                        ),
                    
                    const SizedBox(height: 5),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Already have an account?",
                        style: GoogleFonts.pixelifySans(color: Colors.black, fontSize: 12),
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
