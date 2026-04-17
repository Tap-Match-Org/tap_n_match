import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:tap_n_match/core/api_config.dart';
import 'package:tap_n_match/core/theme_background.dart';

class ReportPlayerPage extends StatefulWidget {
  final int userId;
  final String selectedTheme;

  const ReportPlayerPage({
    super.key,
    required this.userId,
    required this.selectedTheme,
  });

  @override
  State<ReportPlayerPage> createState() => _ReportPlayerPageState();
}

class _ReportPlayerPageState extends State<ReportPlayerPage> {
  late TextEditingController _playerIdController;
  late TextEditingController _reasonController;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _playerIdController = TextEditingController();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _playerIdController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_playerIdController.text.isEmpty || _reasonController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        ApiConfig.getUri('/reports'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reporter_id': widget.userId,
          'reported_id': int.parse(_playerIdController.text),
          'reason': _reasonController.text,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _successMessage = 'Report submitted successfully!';
          _playerIdController.clear();
          _reasonController.clear();
          _errorMessage = null;
        });
        Future.delayed(const Duration(seconds: 2), () => Navigator.pop(context));
      } else {
        setState(() => _errorMessage = 'Failed to submit report');
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
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Report Player',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.pixelifySans(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
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
                      Text(
                        'Enter the Player ID of the player you want to report',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.pixelifySans(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _playerIdController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Player ID',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _reasonController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Reason for Report',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLoading ? Colors.grey : Colors.red.shade400,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                'Submit Report',
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
