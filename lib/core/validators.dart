/// Validateurs de formulaire réutilisables.
class Validators {
  Validators._();

  static String? required(String? v, [String msg = 'Champ requis']) =>
      (v == null || v.trim().isEmpty) ? msg : null;

  static String? name(String? v) =>
      (v == null || v.trim().length < 2) ? 'Nom requis' : null;

  static String? email(String? v) =>
      (v == null || !v.contains('@')) ? 'Email invalide' : null;

  static String? Function(String?) password({int minLength = 6}) {
    return (v) => (v == null || v.length < minLength)
        ? '$minLength caractères minimum'
        : null;
  }

  static String? phone(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    return digits.length < 8 ? 'Numéro invalide' : null;
  }

  static String? cin(String? v) =>
      (v ?? '').length != 8 ? 'Le CIN contient 8 chiffres' : null;

  static String? Function(String?) matches(String Function() other) {
    return (v) =>
        v != other() ? 'Les mots de passe ne correspondent pas' : null;
  }
}
