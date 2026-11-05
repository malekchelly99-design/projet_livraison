import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      );
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? formatters;
  final TextCapitalization capitalization;
  final String? Function(String?)? validator;
  final bool obscure;
  final Widget? suffix;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboard,
    this.formatters,
    this.capitalization = TextCapitalization.none,
    this.validator,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
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
          suffixIcon: suffix,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }
}

class AppDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;

  const AppDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
}

/// Bouton principal avec indicateur de chargement.
class LoadingButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const LoadingButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}
