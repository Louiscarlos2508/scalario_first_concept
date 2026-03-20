import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/create_tenant_dto.dart';
import '../../data/services/admin_api_service.dart';
import '../providers/admin_providers.dart';

class NewTenantForm extends ConsumerStatefulWidget {
  const NewTenantForm({super.key});

  @override
  ConsumerState<NewTenantForm> createState() => _NewTenantFormState();
}

class _NewTenantFormState extends ConsumerState<NewTenantForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _currency = 'XOF';
  String _timezone = 'Africa/Ouagadougou';
  String _billingStatus = 'trial';
  bool _loading = false;
  bool _obscure = true;

  static const _currencies = ['XOF', 'EUR', 'USD', 'MAD'];
  static const _timezones = [
    'Africa/Ouagadougou',
    'Africa/Abidjan',
    'Africa/Dakar',
    'Africa/Lagos',
    'Europe/Paris',
  ];

  String get _token {
    try {
      return Supabase.instance.client.auth.currentSession?.accessToken ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final dto = CreateTenantDto(
        name: _nameCtrl.text.trim(),
        ownerEmail: _emailCtrl.text.trim(),
        ownerPassword: _passwordCtrl.text,
        currency: _currency,
        timezone: _timezone,
        billingStatus: _billingStatus,
      );

      await ref
          .read(adminApiServiceProvider)
          .createTenant(dto, token: _token);

      ref.invalidate(adminTenantsProvider);

      messenger.showSnackBar(SnackBar(
        content: Text('Client ${dto.name} créé avec succès'),
        backgroundColor: Colors.green,
      ));
      nav.pop();
    } on AdminApiException catch (e) {
      if (!mounted) return;
      final msg = e.code == 'EMAIL_ALREADY_EXISTS'
          ? 'Cet email est déjà utilisé'
          : 'Erreur: ${e.code}';
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erreur de connexion — réessayez'),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau client')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nom boutique
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom boutique',
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Le nom est obligatoire'
                    : null,
              ),
              const SizedBox(height: 16),

              // Email owner
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email owner',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email invalide';
                  if (!v.contains('@') || !v.contains('.')) {
                    return 'Email invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Mot de passe
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Mot de passe owner',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => (v == null || v.length < 8)
                    ? 'Au moins 8 caractères requis'
                    : null,
              ),
              const SizedBox(height: 16),

              // Devise
              DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: const InputDecoration(
                  labelText: 'Devise',
                  border: OutlineInputBorder(),
                ),
                items: _currencies
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _currency = v ?? _currency),
              ),
              const SizedBox(height: 16),

              // Timezone
              DropdownButtonFormField<String>(
                initialValue: _timezone,
                decoration: const InputDecoration(
                  labelText: 'Timezone',
                  border: OutlineInputBorder(),
                ),
                items: _timezones
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _timezone = v ?? _timezone),
              ),
              const SizedBox(height: 16),

              // Statut de facturation
              DropdownButtonFormField<String>(
                initialValue: _billingStatus,
                decoration: const InputDecoration(
                  labelText: 'Statut de facturation',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'trial',
                    child: Text('Essai gratuit (30 jours)'),
                  ),
                  DropdownMenuItem(
                    value: 'active',
                    child: Text('Actif (client a déjà payé)'),
                  ),
                ],
                onChanged: (v) =>
                    setState(() => _billingStatus = v ?? _billingStatus),
              ),
              const SizedBox(height: 16),

              // Type métier (read-only — Retail only in MVP)
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Type métier',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  children: [
                    Icon(Icons.radio_button_checked,
                        color: Theme.of(context).disabledColor),
                    const SizedBox(width: 8),
                    Text('Retail',
                        style: TextStyle(
                            color: Theme.of(context).disabledColor)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Créer le client'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
