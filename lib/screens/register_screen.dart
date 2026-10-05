import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _shopCategories = [
    'Restaurant',
    'Fast-food',
    'Pâtisserie / Boulangerie',
    'Supermarché / Épicerie',
    'Pharmacie',
    'Boutique / Vêtements',
    'Autre',
  ];
  static const _vehicleTypes = ['Moto', 'Vélo', 'Voiture', 'Camionnette'];

  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();

  // Communs
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  // Vendeur
  final _shopNameCtrl = TextEditingController();
  final _shopAddressCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();
  String? _category;

  // Livreur
  final _cinCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  String? _vehicle;

  UserRole _role = UserRole.client;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _phoneCtrl, _emailCtrl, _passwordCtrl, _confirmCtrl,
      _cityCtrl, _shopNameCtrl, _shopAddressCtrl, _taxIdCtrl, _cinCtrl,
      _plateCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------- Petits composants réutilisables ----------

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 12),
    child: Text(title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w600)),
  );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    TextCapitalization capitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        inputFormatters: formatters,
        textCapitalization: capitalization,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required IconData icon,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        // ignore: deprecated_member_use
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        validator: (v) => v == null ? 'Champ requis' : null,
      ),
    );
  }

  String? _required(String? v, [String msg = 'Champ requis']) =>
      (v == null || v.trim().isEmpty) ? msg : null;

  // ---------- Envoi ----------

  Map<String, dynamic> _buildProfile() {
    switch (_role) {
      case UserRole.vendeur:
        return {
          'shopName': _shopNameCtrl.text.trim(),
          'category': _category,
          'address': _shopAddressCtrl.text.trim(),
          'city': _cityCtrl.text.trim(),
          'taxId': _taxIdCtrl.text.trim(), // matricule fiscal (optionnel)
        };
      case UserRole.livreur:
        return {
          'cin': _cinCtrl.text.trim(),
          'vehicleType': _vehicle,
          'plateNumber': _plateCtrl.text.trim(),
          'city': _cityCtrl.text.trim(),
        };
      default:
        return {};
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.register(
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
        phone: _phoneCtrl.text,
        role: _role,
        profile: _buildProfile(),
      );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AuthService.errorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- Interface ----------

  @override
  Widget build(BuildContext context) {
    final isVendeur = _role == UserRole.vendeur;
    final isLivreur = _role == UserRole.livreur;

    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<UserRole>(
                  showSelectedIcon: false, // évite la coche qui prend de la place
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: UserRole.client,
                      label: Text('Client', maxLines: 1, softWrap: false),
                      icon: Icon(Icons.person, size: 18),
                    ),
                    ButtonSegment(
                      value: UserRole.vendeur,
                      label: Text('Vendeur', maxLines: 1, softWrap: false),
                      icon: Icon(Icons.storefront, size: 16),
                    ),
                    ButtonSegment(
                      value: UserRole.livreur,
                      label: Text('Livreur', maxLines: 1, softWrap: false),
                      icon: Icon(Icons.two_wheeler, size: 18),
                    ),
                  ],
                  selected: {_role},
                  onSelectionChanged: (s) => setState(() => _role = s.first),
                ),
                const SizedBox(height: 24),

                // ----- Infos personnelles (tous les rôles) -----
                _section(isVendeur
                    ? 'Responsable du compte'
                    : 'Informations personnelles'),
                _field(
                  controller: _nameCtrl,
                  label: 'Nom complet',
                  icon: Icons.badge_outlined,
                  capitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'Nom requis'
                      : null,
                ),
                _field(
                  controller: _phoneCtrl,
                  label: 'Téléphone',
                  hint: '+216 XX XXX XXX',
                  icon: Icons.phone_outlined,
                  keyboard: TextInputType.phone,
                  formatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                  ],
                  validator: (v) {
                    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                    return digits.length < 8 ? 'Numéro invalide' : null;
                  },
                ),

                // ----- Vendeur -----
                if (isVendeur) ...[
                  _section('Informations de la boutique'),
                  _field(
                    controller: _shopNameCtrl,
                    label: 'Nom de la boutique',
                    icon: Icons.store_outlined,
                    capitalization: TextCapitalization.words,
                    validator: _required,
                  ),
                  _dropdown(
                    label: "Catégorie d'activité",
                    icon: Icons.category_outlined,
                    items: _shopCategories,
                    value: _category,
                    onChanged: (v) => setState(() => _category = v),
                  ),
                  _field(
                    controller: _shopAddressCtrl,
                    label: 'Adresse de la boutique',
                    icon: Icons.location_on_outlined,
                    capitalization: TextCapitalization.sentences,
                    validator: _required,
                  ),
                  _field(
                    controller: _cityCtrl,
                    label: 'Ville',
                    icon: Icons.location_city_outlined,
                    capitalization: TextCapitalization.words,
                    validator: _required,
                  ),
                  _field(
                    controller: _taxIdCtrl,
                    label: 'Matricule fiscal (optionnel)',
                    icon: Icons.receipt_long_outlined,
                    capitalization: TextCapitalization.characters,
                  ),
                ],

                // ----- Livreur -----
                if (isLivreur) ...[
                  _section('Informations de livraison'),
                  _field(
                    controller: _cinCtrl,
                    label: "N° de carte d'identité (CIN)",
                    icon: Icons.credit_card_outlined,
                    keyboard: TextInputType.number,
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    validator: (v) =>
                    (v ?? '').length != 8 ? 'Le CIN contient 8 chiffres' : null,
                  ),
                  _dropdown(
                    label: 'Type de véhicule',
                    icon: Icons.two_wheeler,
                    items: _vehicleTypes,
                    value: _vehicle,
                    onChanged: (v) => setState(() => _vehicle = v),
                  ),
                  if (_vehicle != null && _vehicle != 'Vélo')
                    _field(
                      controller: _plateCtrl,
                      label: "Numéro d'immatriculation",
                      icon: Icons.pin_outlined,
                      capitalization: TextCapitalization.characters,
                      validator: _required,
                    ),
                  _field(
                    controller: _cityCtrl,
                    label: 'Ville / zone de livraison',
                    icon: Icons.map_outlined,
                    capitalization: TextCapitalization.words,
                    validator: _required,
                  ),
                ],

                // ----- Connexion (tous les rôles) -----
                _section('Identifiants de connexion'),
                _field(
                  controller: _emailCtrl,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboard: TextInputType.emailAddress,
                  validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Email invalide' : null,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 8)
                        ? '8 caractères minimum'
                        : null,
                  ),
                ),
                _field(
                  controller: _confirmCtrl,
                  label: 'Confirmer le mot de passe',
                  icon: Icons.lock_outline,
                  obscure: _obscure,
                  validator: (v) => v != _passwordCtrl.text
                      ? 'Les mots de passe ne correspondent pas'
                      : null,
                ),

                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _loading
                        ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text("S'inscrire"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}