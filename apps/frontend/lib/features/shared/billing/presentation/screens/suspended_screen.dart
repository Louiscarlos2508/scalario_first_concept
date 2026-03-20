import 'package:flutter/material.dart';

class SuspendedScreen extends StatelessWidget {
  const SuspendedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 72, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Abonnement expiré',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Votre abonnement Scalario est suspendu. '
                  'Contactez votre administrateur pour régulariser votre situation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () {
                    // In Phase 3, this will open url_launcher
                    // For now, show a SnackBar with contact info
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contactez : support@scalario.app'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.mail_outline),
                  label: const Text('Contacter le support'),
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
