import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../core/validators.dart';
import 'register_view.dart';
import 'widgets/form_widgets.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _controller = AuthController();

  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final error = await _controller.login(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );
    if (error != null && mounted) _snack(error);
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _snack("Saisis d'abord ton email ci-dessus.");
      return;
    }
    final error = await _controller.resetPassword(email);
    if (mounted) _snack(error ?? 'Email de réinitialisation envoyé.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.delivery_dining,
                      size: 80, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 8),
                  Text('Connexion',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 32),
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
                    validator: Validators.password(),
                    suffix: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPassword,
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) => LoadingButton(
                      label: 'Se connecter',
                      loading: _controller.loading,
                      onPressed: _submit,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Pas encore de compte ?'),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterView()),
                        ),
                        child: const Text("S'inscrire"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
