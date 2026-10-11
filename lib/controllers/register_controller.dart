import '../core/auth_errors.dart';
import '../models/app_user.dart';
import '../models/profiles.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'base_controller.dart';

/// Inscription : état du formulaire (rôle, listes déroulantes)
/// et création du compte + du profil.
class RegisterController extends BaseController {
  static const shopCategories = [
    'Restaurant',
    'Fast-food',
    'Pâtisserie / Boulangerie',
    'Supermarché / Épicerie',
    'Pharmacie',
    'Boutique / Vêtements',
    'Autre',
  ];
  static const vehicleTypes = ['Moto', 'Vélo', 'Voiture', 'Camionnette'];

  final AuthService _auth;
  final UserService _users;

  RegisterController({AuthService? auth, UserService? users})
      : _auth = auth ?? AuthService(),
        _users = users ?? UserService();

  UserRole _role = UserRole.client;
  String? _shopCategory;
  String? _vehicleType;
  bool _loading = false;

  UserRole get role => _role;
  String? get shopCategory => _shopCategory;
  String? get vehicleType => _vehicleType;
  bool get loading => _loading;

  bool get isVendeur => _role == UserRole.vendeur;
  bool get isLivreur => _role == UserRole.livreur;

  /// Un vélo n'a pas de plaque d'immatriculation.
  bool get needsPlate => _vehicleType != null && _vehicleType != 'Vélo';

  void selectRole(UserRole role) {
    _role = role;
    notifyListeners();
  }

  void selectShopCategory(String? value) {
    _shopCategory = value;
    notifyListeners();
  }

  void selectVehicleType(String? value) {
    _vehicleType = value;
    notifyListeners();
  }

  /// Renvoie `null` en cas de succès, ou un message d'erreur.
  Future<String?> submit({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String city,
    String shopName = '',
    String shopAddress = '',
    String taxId = '',
    String cin = '',
    String plate = '',
  }) async {
    if (!selfRegisterRoles.contains(_role)) {
      return 'Rôle non autorisé à l\'inscription';
    }
    _loading = true;
    notifyListeners();
    try {
      final uid = await _auth.signUp(
        name: name,
        email: email,
        password: password,
      );
      await _users.create(AppUser(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: _role,
        profile: _buildProfile(
          city: city,
          shopName: shopName,
          shopAddress: shopAddress,
          taxId: taxId,
          cin: cin,
          plate: plate,
        ),
      ));
      return null;
    } catch (e) {
      return authErrorMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _buildProfile({
    required String city,
    required String shopName,
    required String shopAddress,
    required String taxId,
    required String cin,
    required String plate,
  }) {
    switch (_role) {
      case UserRole.vendeur:
        return ShopProfile(
          shopName: shopName.trim(),
          category: _shopCategory,
          address: shopAddress.trim(),
          city: city.trim(),
          taxId: taxId.trim(),
        ).toMap();
      case UserRole.livreur:
        return CourierProfile(
          cin: cin.trim(),
          vehicleType: _vehicleType,
          plateNumber: plate.trim(),
          city: city.trim(),
        ).toMap();
      default:
        return {};
    }
  }
}
