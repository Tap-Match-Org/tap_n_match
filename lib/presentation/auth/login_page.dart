import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tap_n_match/core/persistence_service.dart';
import 'package:tap_n_match/repository/auth_repository.dart';

class LoginPage extends StatefulWidget {
  final AuthRepository authRepository;

  LoginPage({super.key, AuthRepository? authRepository})
      : authRepository = authRepository ?? AuthRepository();

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _emailController;
  late TextEditingController _codeController;
  
  int _currentStep = 1; // 1: Standard Login, 2: Enter Gmail, 3: Verify Code
  bool _isLoading = false;
  bool _isSendingCode = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _emailController = TextEditingController();
    _codeController = TextEditingController();
    _loadSavedUsername();
  }

  Future<void> _loadSavedUsername() async {
    final savedUsername = await PersistenceService.getUsername();
    if (savedUsername != null && mounted) {
      setState(() {
        _usernameController.text = savedUsername;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // --- LOGIC ---

  Future<void> _loginStandard() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showMsg('Please enter username and password', isError: true);
      return;
    }

    // --- GUEST ACCOUNT BYPASS FOR PHONE TESTING ---
    if (username == 'Guest' && password == 'kazuya143') {
      _handleLoginSuccess(9999, 'Guest');
      return;
    }

    setState(() => _isLoading = true);
    final response = await widget.authRepository.login(username, password);
    _processAuthResponse(response);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMsg("Please enter a valid Gmail address", isError: true);
      return;
    }
    setState(() => _isSendingCode = true);
    
    final success = await widget.authRepository.sendVerificationCode(email);
    
    if (success) {
      _showMsg("Code sent to Gmail!", isError: false);
      setState(() => _currentStep = 3);
    } else {
      _showMsg("Failed to send code or Server Offline", isError: true);
    }
    
    if (mounted) setState(() => _isSendingCode = false);
  }

  Future<void> _loginWithCode() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();

    if (code.length != 6) {
      _showMsg("Enter 6-digit code", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final response = await widget.authRepository.loginWithCode(email, code);
    _processAuthResponse(response);
    if (mounted) setState(() => _isLoading = false);
  }

  void _processAuthResponse(AuthResponse response) {
    if (response.status == AuthStatus.success) {
      _handleLoginSuccess(response.userId!, response.username!);
    } else if (response.status == AuthStatus.banned) {
      if (mounted) {
        Navigator.of(context).pushNamed(
          '/banned',
          arguments: {'reason': response.banReason},
        );
      }
    } else {
      _showMsg(response.errorMessage ?? 'An error occurred', isError: true);
    }
  }

  Future<void> _handleLoginSuccess(int userId, String username) async {
    await PersistenceService.saveUserId(userId);
    await PersistenceService.saveUsername(username);
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(
        '/menu',
        arguments: {'user_id': userId},
      );
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

  Widget _buildOutlinedTitle(String text) {
    return Stack(
      children: [
        Text(
          text,
          style: GoogleFonts.pixelifySans(
            fontSize: 28,
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
            fontSize: 28,
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: Container(
                  key: ValueKey(_currentStep),
                  constraints: const BoxConstraints(maxWidth: 360),
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
                        child: _buildOutlinedTitle(_getStepTitle()),
                      ),
                      const SizedBox(height: 20),
                      _buildCurrentStep(),
                      if (_currentStep == 1) ...[
                        const SizedBox(height: 5),
                        TextButton(
                          onPressed: () => Navigator.of(context).pushNamed('/register'),
                          child: Text(
                            "Don't Have An Account?",
                            style: GoogleFonts.pixelifySans(color: Colors.black, fontSize: 12),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => setState(() => _currentStep = 1),
                          child: Text(
                            "Back to Standard Login",
                            style: GoogleFonts.pixelifySans(color: Colors.black, fontSize: 12),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1: return 'Login';
      case 2: return 'Enter Gmail';
      case 3: return 'Verify Code';
      default: return '';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      default:
        return Container();
    }
  }

  Widget _buildStep1() {
    return Column(
      children: [
        TextField(
          controller: _usernameController,
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
          onSubmitted: (value) => _loginStandard(),
        ),
        const SizedBox(height: 15),
        _isLoading 
          ? const CircularProgressIndicator(color: Colors.black)
          : Column(
              children: [
                SizedBox(
                  width: 180, 
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: _loginStandard,
                    child: Text(
                      'LOGIN', 
                      style: GoogleFonts.pixelifySans(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => _currentStep = 2),
                  child: Text(
                    "Try Another Method",
                    style: GoogleFonts.pixelifySans(
                      color: Colors.black87, 
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        Text(
          "We'll send a code to your registered Gmail account.",
          style: GoogleFonts.pixelifySans(fontSize: 13, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController, 
          textAlign: TextAlign.center,
          decoration: _pixelInput('your.email@gmail.com'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        _isSendingCode 
          ? const CircularProgressIndicator(color: Colors.black)
          : SizedBox(
              width: 200,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: _sendCode,
                child: Text('SEND CODE', style: GoogleFonts.pixelifySans(color: Colors.white)),
              ),
            ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      children: [
        Text(
          'Enter the 6-digit code sent to ${_emailController.text}',
          style: GoogleFonts.pixelifySans(fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _codeController,
          textAlign: TextAlign.center,
          maxLength: 6,
          keyboardType: TextInputType.number,
          style: GoogleFonts.pixelifySans(fontSize: 18, letterSpacing: 4),
          decoration: _pixelInput('000000'),
          onSubmitted: (value) => _loginWithCode(),
        ),
        const SizedBox(height: 10),
        _isLoading 
          ? const CircularProgressIndicator(color: Colors.black)
          : SizedBox(
              width: 200,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: _loginWithCode,
                child: Text('VERIFY & LOGIN', style: GoogleFonts.pixelifySans(color: Colors.white)),
              ),
            ),
      ],
    );
  }
}
