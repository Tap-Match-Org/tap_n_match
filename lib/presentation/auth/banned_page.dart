import 'package:flutter/material.dart';

class BannedPage extends StatelessWidget {
  final String? reason;
  
  const BannedPage({super.key, this.reason});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.gavel_rounded,
                color: Colors.redAccent,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                "ACCESS DENIED",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Your account has been suspended for violating our terms of service.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
              if (reason != null && reason!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withAlpha(50)),
                  ),
                  child: Text(
                    "Reason: $reason",
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text("Submit an Appeal"),
                      content: const Text(
                        "Our support team will review your appeal within 48 hours. Please provide details about why you believe this suspension was made in error.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Navigate to appeal submission form
                            Navigator.of(context).pushNamed('/appeal');
                          },
                          child: const Text("Submit Appeal"),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text("Appeal Suspension"),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                   Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                },
                child: const Text(
                  "Return to Login",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
