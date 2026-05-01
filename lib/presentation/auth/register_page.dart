import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tap_n_match/application/register_user.dart';
import 'package:tap_n_match/core/soundmanager.dart';
import 'package:tap_n_match/repository/auth_repository.dart';

class RegisterPage extends StatefulWidget {
  final AuthRepository authRepository;
  final RegisterUser? registerUser;

  RegisterPage({super.key, AuthRepository? authRepository, RegisterUser? registerUser})
      : authRepository = authRepository ?? AuthRepository(),
        registerUser = registerUser ?? RegisterUser(authRepository ?? AuthRepository());

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _codeController;
  
  int _currentStep = 1;
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

  // --- LOGIC ---
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
      setState(() => _currentStep = 2);
    } else {
      _showMsg("Failed to send code or Server Offline", isError: true);
    }
    
    if (mounted) setState(() => _isSendingCode = false);
  }

  Future<void> _handleRegister() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final code = _codeController.text.trim();

    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty || code.isEmpty) {
      _showMsg("Fill in all fields", isError: true);
      return;
    }

    if (password != confirmPassword) {
      _showMsg("Passwords do not match", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final response = await widget.registerUser!.execute(
      username: username,
      email: email,
      password: password,
      code: code,
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

  Widget _buildStepContainer(List<Widget> children, {bool showBack = true, bool isLast = false, VoidCallback? onNext}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...children,
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showBack)
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
                  if (onNext != null) onNext();
                },
                child: Text(isLast ? 'FINISH' : 'NEXT', 
                  style: GoogleFonts.pixelifySans(color: Colors.white, fontSize: 13)),
              ),
            ),
          ],
        ),
      ],
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
                        'Step $_currentStep of 4',
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
                            Navigator.pop(context);
                          },
                          child: Text(
                            "Already have an account?",
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
      case 1: return 'Enter Gmail';
      case 2: return 'Verify Code';
      case 3: return 'Username';
      case 4: return 'Security';
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
      case 4:
        return _buildStep4();
      default:
        return Container();
    }
  }

  Widget _buildStep1() {
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
          : SizedBox(
              width: 200,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  soundManager.playTap();
                  _sendCode();
                },
                child: Text('SEND CODE', style: GoogleFonts.pixelifySans(color: Colors.white)),
              ),
            ),
      ],
    );
  }

  Widget _buildStep2() {
    return _buildStepContainer(
      [
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
      ],
      onNext: () {
        if (_codeController.text.length == 6) {
          setState(() => _currentStep = 3);
        } else {
          _showMsg("Enter 6-digit code", isError: true);
        }
      },
    );
  }

  Widget _buildStep3() {
    return _buildStepContainer(
      [
        TextField(
          controller: _usernameController, 
          decoration: _pixelInput('CoolPlayer123'),
        ),
      ],
      onNext: () {
        if (_usernameController.text.isNotEmpty) {
          setState(() => _currentStep = 4);
        } else {
          _showMsg("Please enter a username", isError: true);
        }
      },
    );
  }

  Widget _buildStep4() {
    return Column(
      children: [
        TextField(controller: _passwordController, obscureText: true, decoration: _pixelInput('Password')),
        const SizedBox(height: 8),
        TextField(controller: _confirmPasswordController, obscureText: true, decoration: _pixelInput('Confirm Password')),
        const SizedBox(height: 20),
        _isLoading 
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
                      setState(() => _currentStep = 3);
                    },
                    child: Text('BACK', style: GoogleFonts.pixelifySans(color: Colors.black, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 160, 
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () {
                      soundManager.playTap();
                      _handleRegister();
                    },
                    child: Text('VERIFY & SIGN UP', 
                      style: GoogleFonts.pixelifySans(color: Colors.white, fontSize: 13)),
                  ),
                ),
              ],
            ),
      ],
    );
  }
}
