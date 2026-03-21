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
  bool _trial = true;
  String _plan = 'standard';
  String _businessType = 'generaliste';
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
        billingStatus: _trial ? 'trial' : 'active',
        plan: _plan,
        businessType: _businessType,
      );

      await ref
          .read(adminApiServiceProvider)
          .createTenant(dto, token: _token);

      ref.invalidate(adminTenantsProvider);

      final extraMsg = dto.businessType != 'generaliste'
          ? ' — catégories suggérées créées'
          : '';
      messenger.showSnackBar(SnackBar(
        content: Text('Client ${dto.name} créé avec succès$extraMsg'),
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

              // Plan
              DropdownButtonFormField<String>(
                initialValue: _plan,
                decoration: const InputDecoration(
                  labelText: 'Plan',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'standard',   child: Text('Standard — 15 000 FCFA/mois')),
                  DropdownMenuItem(value: 'premium',    child: Text('Premium — 25 000 FCFA/mois')),
                  DropdownMenuItem(value: 'enterprise', child: Text('Enterprise — sur devis')),
                ],
                onChanged: (v) => setState(() => _plan = v ?? _plan),
              ),
              const SizedBox(height: 8),

              // Période d'essai (30 jours)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Période d\'essai (30 jours)'),
                subtitle: Text(_trial
                    ? 'Modules Standard activés pendant l\'essai'
                    : 'Modules du plan choisi activés immédiatement'),
                value: _trial,
                onChanged: (v) => setState(() => _trial = v),
              ),
              const SizedBox(height: 8),

              // Type de business (filtre par vertical "retail" — seul vertical actif)
              ref.watch(businessTypesProvider).when(
                    data: (types) {
                      final retailTypes =
                          types.where((t) => t.vertical == 'retail').toList();
                      return DropdownButtonFormField<String>(
                        initialValue: _businessType,
                        decoration: const InputDecoration(
                          labelText: 'Type de business',
                          border: OutlineInputBorder(),
                        ),
                        items: retailTypes
                            .map((t) => DropdownMenuItem(
                                  value: t.code,
                                  child: Text(t.name),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _businessType = v ?? _businessType),
                      );
                    },
                    loading: () => const InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Type de business',
                        border: OutlineInputBorder(),
                      ),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (e, st) => const InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Type de business',
                        border: OutlineInputBorder(),
                      ),
                      child: Text('Généraliste (défaut)'),
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
