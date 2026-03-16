import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pos_providers.dart';
import '../../data/models/pos_session.dart';
import 'package:frontend/core/auth/auth_state.dart';

class SessionGuard extends ConsumerWidget {
  final Widget child;

  const SessionGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            body: Center(
              child: Text('User profile not found. Please log in again.'),
            ),
          );
        }

        return sessionAsync.when(
          data: (session) {
            if (session == null) {
              return OpenSessionScreen(profile: profile);
            }
            return child;
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (err, stack) => Scaffold(
            body: Center(child: Text('Error loading session: $err')),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) =>
          Scaffold(body: Center(child: Text('Error loading profile: $err'))),
    );
  }
}

class OpenSessionScreen extends ConsumerStatefulWidget {
  final dynamic profile; // Using dynamic or importing UserProfile

  const OpenSessionScreen({super.key, required this.profile});

  @override
  ConsumerState<OpenSessionScreen> createState() => _OpenSessionScreenState();
}

class _OpenSessionScreenState extends ConsumerState<OpenSessionScreen> {
  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.store, size: 64, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Ouvrir la caisse',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Entrez le fond de caisse du jour.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Fond de caisse',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(_amountController.text) ?? 0;
                    final session = PosSession()
                      ..userId = widget.profile.id
                      ..tenantId = widget.profile.tenantId
                      ..status = 'OPEN'
                      ..openingBalance = amount
                      ..openedAt = DateTime.now();

                    ref.read(sessionProvider.notifier).openSession(session);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Ouvrir la caisse'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
