import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:tap_n_match/core/api_config.dart';
import 'package:tap_n_match/core/theme_background.dart';

class BugReportPage extends StatefulWidget {
  final int userId;
  final String selectedTheme;

  const BugReportPage({
    super.key,
    required this.userId,
    required this.selectedTheme,
  });

  @override
  State<BugReportPage> createState() => _BugReportPageState();
}

class _BugReportPageState extends State<BugReportPage> {
  late TextEditingController _descriptionController;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      final file = result?.files.single;
      final bytes = file?.bytes;

      if (file != null && bytes != null && bytes.isNotEmpty) {
        const maxBytes = 2 * 1024 * 1024;
        if (bytes.lengthInBytes > maxBytes) {
          setState(() => _errorMessage = 'Pick an image smaller than 2 MB.');
          return;
        }

        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = file.name;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error picking file: ${e.toString()}');
    }
  }

  Future<void> _submitBugReport() async {
    if (_descriptionController.text.isEmpty) {
      setState(() => _errorMessage = 'Please describe the bug');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        ApiConfig.getUri('/support/tickets'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'type': 'bug',
          'message': _descriptionController.text.trim(),
          'screenshot_base64': _selectedImageBytes == null ? null : base64Encode(_selectedImageBytes!),
          'screenshot_filename': _selectedImageName,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _successMessage = 'Bug report submitted successfully!';
          _descriptionController.clear();
          _selectedImageBytes = null;
          _selectedImageName = null;
          _errorMessage = null;
        });
        Future.delayed(const Duration(seconds: 2), () { if (mounted) Navigator.pop(context); });
      } else {
        setState(() => _errorMessage = 'Failed to submit bug report');
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
                        'Bug Report',
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
                      Text(
                        'Help us fix bugs by providing detailed information and screenshots',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.pixelifySans(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Bug Description',
                          hintText: 'Describe the bug in detail...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _pickFile,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue, width: 2, style: BorderStyle.solid),
                            image: _selectedImageBytes == null
                                ? null
                                : DecorationImage(
                                    image: MemoryImage(_selectedImageBytes!),
                                    fit: BoxFit.cover,
                                    opacity: 0.3,
                                  ),
                          ),
                          child: _selectedImageBytes == null
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.image, size: 40, color: Colors.blue),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to select screenshot',
                                      style: GoogleFonts.pixelifySans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle, size: 40, color: Colors.green),
                                    const SizedBox(height: 8),
                                    Text(
                                      _selectedImageName ?? 'Screenshot selected',
                                      style: GoogleFonts.pixelifySans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitBugReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLoading ? Colors.grey : Colors.orange.shade400,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                'Submit Bug Report',
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


