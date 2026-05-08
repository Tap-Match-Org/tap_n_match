import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tap_n_match/core/persistence_service.dart';
import 'package:tap_n_match/core/soundmanager.dart';
import 'package:tap_n_match/repository/auth_repository.dart';
import 'package:tap_n_match/infrastructure/firebase_auth_repository.dart';

class LoginPage extends StatefulWidget {
  final AuthRepository authRepository;
  final FirebaseAuthRepository firebaseAuthRepository;

  LoginPage({
    super.key,
    AuthRepository? authRepository,
    FirebaseAuthRepository? firebaseAuthRepository,
  })  : authRepository = authRepository ?? AuthRepository(),
        firebaseAuthRepository = firebaseAuthRepository ?? FirebaseAuthRepository();

  @override
  State<LoginPage> createState() => _LoginPageState();
}

enum LoginMethod { traditional, gmail }

class _LoginPageState extends State<LoginPage> {
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _emailController;
  late TextEditingController _codeController;
  
  int _currentStep = 1;
  LoginMethod _selectedMethod = LoginMethod.traditional;
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
  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMsg("Please enter a valid Gmail address", isError: true);
      return;
    }
    setState(() => _isSendingCode = true);
    
    // In Hybrid Mode, we still notify the backend about the email to get a code
    final success = await widget.authRepository.sendVerificationCode(email);
    
    if (success) {
      _showMsg("Verification code sent to Gmail!", isError: false);
      setState(() => _currentStep = 3); // Move to code entry
    } else {
      _showMsg("Failed to connect to Server", isError: true);
    }
    
    if (mounted) setState(() => _isSendingCode = false);
  }

  Future<void> _handleLogin() async {
    AuthResponse response;
    setState(() => _isLoading = true);

    if (_selectedMethod == LoginMethod.traditional) {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      // --- GUEST ACCOUNT BYPASS ---
      if (username == 'Guest' && password == 'kazuya143') {
        const guestId = 9999;
        await PersistenceService.saveUserId(guestId);
        await PersistenceService.saveUsername('Guest');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            '/menu',
            arguments: {'user_id': guestId},
          );
        }
        return;
      }

      response = await widget.authRepository.login(username, password);
    } else {
      // GMAIL LOGIN VIA CUSTOM CODE (For recovery/forgot password)
      final email = _emailController.text.trim();
      final code = _codeController.text.trim();
      
      try {
        // We skip Firebase Auth here because the user might have forgotten their password.
        // The identity is verified via the 6-digit code sent to their Gmail.
        response = await widget.authRepository.loginWithCode(
          email, 
          code,
        );
      } catch (e) {
        response = AuthResponse.error("Login Error: $e");
      }
    }

    if (response.status == AuthStatus.success) {
      // Only save and navigate on a successful login where userId/username are present
      if (response.userId != null && response.username != null) {
        await PersistenceService.saveUserId(response.userId!);
        await PersistenceService.saveUsername(response.username!);
      }

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/menu',
          arguments: {'user_id': response.userId},
        );
      }
    } else if (response.status == AuthStatus.banned) {
      // Show a clear message for banned accounts and do not navigate or save null values
      _showMsg(response.errorMessage ?? 'Account banned', isError: true);
    } else {
      _showMsg(response.errorMessage ?? 'An error occurred', isError: true);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showMsg(String msg, {required bool isError}) {
    if (!mounted) return;
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
      hintStyle: GoogleFonts.pixelifySans(color: Colors.grey.shade600, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFD9D9D9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: Container(
                  key: ValueKey(_currentStep),
                  constraints: const BoxConstraints(maxWidth: 400), 
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
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
                        'Step $_currentStep of 3',
                        style: GoogleFonts.pixelifySans(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStepTitle(),
                        style: GoogleFonts.pixelifySans(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      _buildCurrentStep(),
                      if (_currentStep == 1) ...[
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: () {
                            soundManager.playTap();
                            Navigator.of(context).pushNamed('/register');
                          },
                          child: Text(
                            "Don't have an account?",
                            style: GoogleFonts.pixelifySans(color: Colors.black, fontSize: 11),
                          ),
                        )
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
      case 1: return 'Login Method';
      case 2: return _selectedMethod == LoginMethod.traditional ? 'Enter Username' : 'Enter Gmail';
      case 3: return _selectedMethod == LoginMethod.traditional ? 'Enter Password' : 'Verify Code';
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
        _buildMethodButton(
          title: 'Standard Login',
          subtitle: 'Username & Password',
          icon: Icons.person_outline,
          onTap: () {
            soundManager.playTap();
            setState(() {
              _selectedMethod = LoginMethod.traditional;
              _currentStep = 2;
            });
          },
        ),
        const SizedBox(height: 12),
        _buildMethodButton(
          title: 'Gmail Login',
          subtitle: 'Verification Code',
          icon: Icons.mail_outline,
          onTap: () {
            soundManager.playTap();
            setState(() {
              _selectedMethod = LoginMethod.gmail;
              _currentStep = 2;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMethodButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.pixelifySans(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(subtitle, style: GoogleFonts.pixelifySans(fontSize: 12, color: Colors.black54)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    if (_selectedMethod == LoginMethod.traditional) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController, 
            decoration: _pixelInput('Username'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 100,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () {
                      soundManager.playTap();
                      setState(() => _currentStep--);
                    },
                    child: Text('BACK', style: GoogleFonts.pixelifySans(color: Colors.black, fontSize: 13)),
                  ),
                ),
              ),
              SizedBox(
                width: 140,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {
                    soundManager.playTap();
                    if (_usernameController.text.isNotEmpty) {
                      setState(() => _currentStep = 3);
                    } else {
                      _showMsg("Please enter your username", isError: true);
                    }
                  },
                  child: Text('NEXT', style: GoogleFonts.pixelifySans(color: Colors.white, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          TextField(
            controller: _emailController, 
            decoration: _pixelInput('your.email@gmail.com'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _isSendingCode 
            ? const CircularProgressIndicator(color: Colors.black)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () {
                        soundManager.playTap();
                        setState(() => _currentStep = 1);
                      },
                      child: Text('BACK', style: GoogleFonts.pixelifySans(color: Colors.black, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 140,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        soundManager.playTap();
                        _sendCode();
                      },
                      child: Text('SEND CODE', style: GoogleFonts.pixelifySans(color: Colors.white, fontSize: 13)),
                    ),
                  ),
                ],
              ),
        ],
      );
    }
  }

  Widget _buildStep3() {
    if (_selectedMethod == LoginMethod.traditional) {
      return Column(
        children: [
          TextField(
            controller: _passwordController, 
            obscureText: true, 
            decoration: _pixelInput('Password'),
            onSubmitted: (_) => _handleLogin(),
          ),
          const SizedBox(height: 20),
          _isLoading 
            ? const CircularProgressIndicator(color: Colors.black)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () {
                        soundManager.playTap();
                        setState(() => _currentStep = 2);
                      },
                      child: Text('BACK', style: GoogleFonts.pixelifySans(color: Colors.black, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        soundManager.playTap();
                        _handleLogin();
                      },
                      child: Text('LOGIN', style: GoogleFonts.pixelifySans(color: Colors.white, fontSize: 13)),
                    ),
                  ),
                ],
              ),
        ],
      );
    } else {
      return Column(
        children: [
          Text(
            'We sent a code to ${_emailController.text}',
            style: GoogleFonts.pixelifySans(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            textAlign: TextAlign.center,
            maxLength: 6,
            keyboardType: TextInputType.number,
            style: GoogleFonts.pixelifySans(fontSize: 18, letterSpacing: 4),
            decoration: _pixelInput('000000'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () {
                    soundManager.playTap();
                    setState(() => _currentStep = 2);
                  },
                  child: Text('BACK', style: GoogleFonts.pixelifySans(color: Colors.black, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Colors.black))
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        soundManager.playTap();
                        if (_codeController.text.length == 6) {
                          _handleLogin();
                        } else {
                          _showMsg("Enter 6-digit code", isError: true);
                        }
                      },
                      child: Text('LOGIN', style: GoogleFonts.pixelifySans(color: Colors.white, fontSize: 13)),
                    ),
              ),
            ],
          ),
        ],
      );
    }
  }
}
