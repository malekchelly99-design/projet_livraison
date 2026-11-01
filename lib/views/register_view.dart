import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  // Livreur
  final _cinCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();

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
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final error = await _controller.submit(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      phone: _phoneCtrl.text,
      city: _cityCtrl.text,
      shopName: _shopNameCtrl.text,
      shopAddress: _shopAddressCtrl.text,
      taxId: _taxIdCtrl.text,
      cin: _cinCtrl.text,
      plate: _plateCtrl.text,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

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

  // ---------- Sections ----------

  Widget _roleSelector() {
    return SegmentedButton<UserRole>(
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
