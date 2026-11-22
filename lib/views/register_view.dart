import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/auth_controller.dart';
import '../controllers/register_controller.dart';
import '../core/validators.dart';
import '../models/user_role.dart';
import 'widgets/form_widgets.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _controller = RegisterController();

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
  final _descriptionCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController(text: '08:00 - 22:00');

  // Livreur
  final _cinCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();

  bool _obscure = true;

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _phoneCtrl, _emailCtrl, _passwordCtrl, _confirmCtrl,
      _cityCtrl, _shopNameCtrl, _shopAddressCtrl, _taxIdCtrl,
      _descriptionCtrl, _hoursCtrl, _cinCtrl, _plateCtrl,
    ]) {
      c.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  // ── Soumission ──────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await _controller.submitWithResult(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      phone: _phoneCtrl.text,
      city: _cityCtrl.text,
      shopName: _shopNameCtrl.text,
      shopAddress: _shopAddressCtrl.text,
      taxId: _taxIdCtrl.text,
      description: _descriptionCtrl.text,
      horaires: _hoursCtrl.text.trim().isNotEmpty
          ? _hoursCtrl.text.trim()
          : '08:00 - 22:00',
      cin: _cinCtrl.text,
      plate: _plateCtrl.text,
    );

    if (!mounted) return;

    switch (result.type) {
      case RegisterResult.success:
        // Inscription réussie → retour à l'accueil
        Navigator.of(context).popUntil((r) => r.isFirst);

      case RegisterResult.emailAlreadyExists:
        // Cas migration : le compte Auth existe mais pas Firestore
        await _showEmailExistsDialog(result.existingEmail ?? _emailCtrl.text);

      case RegisterResult.error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? 'Erreur inconnue')),
        );
    }
  }

  // ── Dialog "email déjà utilisé" ─────────────────────────────────────────

  Future<void> _showEmailExistsDialog(String email) async {
    final passwordCtrl = TextEditingController();
    bool obscure = true;
    String? loginError;
    bool loggingIn = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Compte déjà existant',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Un compte existe déjà avec l\'adresse :',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Entrez votre mot de passe pour vous connecter à ce compte '
                  'et restaurer votre profil.',
                ),
                const SizedBox(height: 16),

                // Champ mot de passe
                StatefulBuilder(
                  builder: (_, setInnerState) => TextFormField(
                    controller: passwordCtrl,
                    obscureText: obscure,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      errorText: loginError,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setInnerState(() => obscure = !obscure),
                      ),
                    ),
                  ),
                ),

                if (loggingIn) ...[
                  const SizedBox(height: 12),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
          actions: [
            // Annuler
            TextButton(
              onPressed:
                  loggingIn ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),

            // Se connecter
            FilledButton(
              onPressed: loggingIn
                  ? null
                  : () async {
                      if (passwordCtrl.text.isEmpty) {
                        setDialogState(
                          () => loginError = 'Veuillez entrer votre mot de passe',
                        );
                        return;
                      }

                      setDialogState(() {
                        loggingIn = true;
                        loginError = null;
                      });

                      // Tentative de connexion
                      final authCtrl = AuthController();
                      final error = await authCtrl.login(
                        email: email,
                        password: passwordCtrl.text,
                      );
                      authCtrl.dispose();

                      if (!ctx.mounted) return;

                      if (error == null) {
                        // Connexion réussie → fermer le dialog et retourner à l'accueil
                        Navigator.of(ctx).pop();
                        if (mounted) {
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        }
                      } else {
                        setDialogState(() {
                          loggingIn = false;
                          loginError = error;
                        });
                      }
                    },
              child: const Text('Se connecter'),
            ),
          ],
        ),
      ),
    );

    passwordCtrl.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Créer un compte')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _roleSelector(),
                  const SizedBox(height: 24),
                  ..._personalSection(),
                  if (_controller.isVendeur) ..._vendeurSection(),
                  if (_controller.isLivreur) ..._livreurSection(),
                  ..._credentialsSection(),
                  const SizedBox(height: 8),
                  LoadingButton(
                    label: "S'inscrire",
                    loading: _controller.loading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Sections du formulaire ───────────────────────────────────────────────

  Widget _roleSelector() {
    return SegmentedButton<UserRole>(
      showSelectedIcon: false,
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
      selected: {_controller.role},
      onSelectionChanged: (s) => _controller.selectRole(s.first),
    );
  }

  List<Widget> _personalSection() => [
        SectionTitle(_controller.isVendeur
            ? 'Responsable du compte'
            : 'Informations personnelles'),
        AppTextField(
          controller: _nameCtrl,
          label: 'Nom complet',
          icon: Icons.badge_outlined,
          capitalization: TextCapitalization.words,
          validator: Validators.name,
        ),
        AppTextField(
          controller: _phoneCtrl,
          label: 'Téléphone',
          hint: '+216 XX XXX XXX',
          icon: Icons.phone_outlined,
          keyboard: TextInputType.phone,
          formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
          validator: Validators.phone,
        ),
      ];

  List<Widget> _vendeurSection() => [
        const SectionTitle('Informations de la boutique'),
        AppTextField(
          controller: _shopNameCtrl,
          label: 'Nom de la boutique',
          icon: Icons.store_outlined,
          capitalization: TextCapitalization.words,
          validator: Validators.required,
        ),
        AppDropdown(
          label: "Catégorie d'activité",
          icon: Icons.category_outlined,
          items: RegisterController.shopCategories,
          value: _controller.shopCategory,
          onChanged: _controller.selectShopCategory,
        ),
        AppTextField(
          controller: _shopAddressCtrl,
          label: 'Adresse de la boutique',
          icon: Icons.location_on_outlined,
          capitalization: TextCapitalization.sentences,
          validator: Validators.required,
        ),
        AppTextField(
          controller: _cityCtrl,
          label: 'Ville',
          icon: Icons.location_city_outlined,
          capitalization: TextCapitalization.words,
          validator: Validators.required,
        ),
        AppTextField(
          controller: _descriptionCtrl,
          label: 'Description / Spécialité (optionnel)',
          hint: 'Ex: Pizzas au feu de bois, burgers gourmets...',
          icon: Icons.description_outlined,
          capitalization: TextCapitalization.sentences,
        ),
        AppTextField(
          controller: _hoursCtrl,
          label: "Horaires d'ouverture",
          hint: 'Ex: 08:00 - 22:00',
          icon: Icons.access_time_outlined,
        ),
        AppTextField(
          controller: _taxIdCtrl,
          label: 'Matricule fiscal (optionnel)',
          icon: Icons.receipt_long_outlined,
          capitalization: TextCapitalization.characters,
        ),
      ];

  List<Widget> _livreurSection() => [
        const SectionTitle('Informations de livraison'),
        AppTextField(
          controller: _cinCtrl,
          label: "N° de carte d'identité (CIN)",
          icon: Icons.credit_card_outlined,
          keyboard: TextInputType.number,
          formatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          validator: Validators.cin,
        ),
        AppDropdown(
          label: 'Type de véhicule',
          icon: Icons.two_wheeler,
          items: RegisterController.vehicleTypes,
          value: _controller.vehicleType,
          onChanged: _controller.selectVehicleType,
        ),
        if (_controller.needsPlate)
          AppTextField(
            controller: _plateCtrl,
            label: "Numéro d'immatriculation",
            icon: Icons.pin_outlined,
            capitalization: TextCapitalization.characters,
            validator: Validators.required,
          ),
        AppTextField(
          controller: _cityCtrl,
          label: 'Ville / zone de livraison',
          icon: Icons.map_outlined,
          capitalization: TextCapitalization.words,
          validator: Validators.required,
        ),
      ];

  List<Widget> _credentialsSection() => [
        const SectionTitle('Identifiants de connexion'),
        AppTextField(
          controller: _emailCtrl,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboard: TextInputType.emailAddress,
          validator: Validators.email,
        ),
        AppTextField(
          controller: _passwordCtrl,
          label: 'Mot de passe',
          icon: Icons.lock_outline,
          obscure: _obscure,
          validator: Validators.password(minLength: 8),
          suffix: IconButton(
            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        AppTextField(
          controller: _confirmCtrl,
          label: 'Confirmer le mot de passe',
          icon: Icons.lock_outline,
          obscure: _obscure,
          validator: Validators.matches(() => _passwordCtrl.text),
        ),
      ];
}
