import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:tap_n_match/core/theme_background.dart';

class BanAppealPage extends StatefulWidget {
  final int userId;
  final String selectedTheme;

  const BanAppealPage({
    super.key,
    required this.userId,
    required this.selectedTheme,
  });

  @override
  State<BanAppealPage> createState() => _BanAppealPageState();
}

class _BanAppealPageState extends State<BanAppealPage> {
  late TextEditingController _appealController;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _appealController = TextEditingController();
  }

  @override
  void dispose() {
    _appealController.dispose();
    super.dispose();
  }

  Future<void> _submitAppeal() async {
    if (_appealController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter your appeal');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/appeals'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'appeal_text': _appealController.text,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _successMessage = 'Appeal submitted! Our team will review it within 48 hours.';
          _appealController.clear();
          _errorMessage = null;
        });
        Future.delayed(const Duration(seconds: 3), () => Navigator.pop(context));
      } else {
        setState(() => _errorMessage = 'Failed to submit appeal');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: buildThemeDecoration(widget.selectedTheme),
        child: Stack(
          children: [
            // Back Button
            Positioned(
              left: 20,
              top: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 22),
                ),
              ),
            ),
            // Main Content
            Center(
              child: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  constraints: const BoxConstraints(maxWidth: 450),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ban Appeal',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.pixelifySans(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_successMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade200,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green, width: 2),
                          ),
                          child: Text(
                            _successMessage!,
                            style: GoogleFonts.pixelifySans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade200,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red, width: 2),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.pixelifySans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Username: <Your Username>',
                              style: GoogleFonts.pixelifySans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Player ID: ${widget.userId}',
                              style: GoogleFonts.pixelifySans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Reason to Unban:',
                              style: GoogleFonts.pixelifySans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _appealController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          labelText: 'Your Appeal',
                          hintText: 'Please explain why you believe your ban should be lifted...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitAppeal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLoading ? Colors.grey : Colors.purple.shade400,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                'Submit Appeal',
                                style: GoogleFonts.pixelifySans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
