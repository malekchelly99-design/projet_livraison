import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../controllers/client_dashboard_controller.dart';
import '../../models/app_user.dart';
import '../../models/order_model.dart';
import '../../models/product.dart';

class ClientDashboardView extends StatefulWidget {
  final AppUser user;
  final VoidCallback onLogout;

  const ClientDashboardView({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<ClientDashboardView> createState() => _ClientDashboardViewState();
}

class _ClientDashboardViewState extends State<ClientDashboardView> {
  late final ClientDashboardController _controller;

  // Contrôleurs pour l'édition de profil
  late final TextEditingController _profileNameCtrl;
  late final TextEditingController _profilePhoneCtrl;
  late final TextEditingController _profileAddressCtrl;
  late final TextEditingController _profileCityCtrl;

  // Recherche de boutique
  final TextEditingController _shopSearchCtrl = TextEditingController();
  final TextEditingController _promoInputCtrl = TextEditingController();

  final List<Map<String, dynamic>> _categories = const [
    {'name': 'Tous', 'icon': Icons.apps},
    {'name': 'Restauration', 'icon': Icons.restaurant},
    {'name': 'Pizzas & Fast-food', 'icon': Icons.local_pizza},
    {'name': 'Épicerie', 'icon': Icons.local_grocery_store},
    {'name': 'Boulangerie & Pâtisserie', 'icon': Icons.bakery_dining},
    {'name': 'Boissons & Cafés', 'icon': Icons.local_cafe},
    {'name': 'Pharmacie & Santé', 'icon': Icons.local_pharmacy},
  ];

  @override
  void initState() {
    super.initState();
    _controller = ClientDashboardController();
    _controller.initUserInfo(widget.user);

    _profileNameCtrl = TextEditingController(text: widget.user.name);
    _profilePhoneCtrl = TextEditingController(text: widget.user.phone);
    _profileAddressCtrl = TextEditingController(
      text: (widget.user.profile['address'] as String?) ?? '',
    );
    _profileCityCtrl = TextEditingController(
      text: (widget.user.profile['city'] as String?) ?? widget.user.city,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _shopSearchCtrl.dispose();
    _promoInputCtrl.dispose();
    _profileNameCtrl.dispose();
    _profilePhoneCtrl.dispose();
    _profileAddressCtrl.dispose();
    _profileCityCtrl.dispose();
    super.dispose();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onLogout();
            },
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_controller.currentTab) {
      case 0:
        return 'Tableau de bord';
      case 1:
        return 'Catalogue & Plats';
      case 2:
        return 'Boutiques partenaires';
      case 3:
        return 'Mon panier (${_controller.totalItemCount})';
      case 4:
        return 'Mes commandes';
      case 5:
        return 'Mon profil';
      default:
        return 'Espace Client';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 850;

            if (isDesktop) {
              return Scaffold(
                body: Row(
                  children: [
                    _buildSidebar(),
                    const VerticalDivider(width: 1, thickness: 1),
                    Expanded(
                      child: Column(
                        children: [
                          _buildTopHeader(),
                          Expanded(child: _buildCurrentView()),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Scaffold(
              appBar: AppBar(
                title: Text(_getPageTitle()),
                actions: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_bag_outlined),
                        onPressed: () => _controller.setTab(3),
                      ),
                      if (_controller.totalItemCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.deepOrange,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${_controller.totalItemCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Déconnexion',
                    onPressed: _showLogoutDialog,
                  ),
                ],
              ),
              body: _buildCurrentView(),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _controller.currentTab > 4 ? 4 : _controller.currentTab,
                onDestinationSelected: (index) {
                  _controller.setTab(index);
                },
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: 'Accueil',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.restaurant_menu_outlined),
                    selectedIcon: Icon(Icons.restaurant_menu),
                    label: 'Catalogue',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.storefront_outlined),
                    selectedIcon: Icon(Icons.storefront),
                    label: 'Boutiques',
                  ),
                  NavigationDestination(
                    icon: Badge(
                      isLabelVisible: _controller.totalItemCount > 0,
                      label: Text('${_controller.totalItemCount}'),
                      child: const Icon(Icons.shopping_bag_outlined),
                    ),
                    selectedIcon: Badge(
                      isLabelVisible: _controller.totalItemCount > 0,
                      label: Text('${_controller.totalItemCount}'),
                      child: const Icon(Icons.shopping_bag),
                    ),
                    label: 'Panier',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long),
                    label: 'Commandes',
                  ),
                ],
              ),
              floatingActionButton: _controller.currentTab != 3 && _controller.totalItemCount > 0
                  ? FloatingActionButton.extended(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      onPressed: () => _controller.setTab(3),
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: Text(
                        'Panier (${_controller.total.toStringAsFixed(2)} DT)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildTopHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _getPageTitle(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Row(
            children: [
              OutlinedButton.icon(
                icon: Badge(
                  isLabelVisible: _controller.totalItemCount > 0,
                  label: Text('${_controller.totalItemCount}'),
                  child: const Icon(Icons.shopping_bag_outlined, size: 18),
                ),
                label: Text(
                  'Panier (${_controller.total.toStringAsFixed(2)} DT)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => _controller.setTab(3),
              ),
              const SizedBox(width: 16),
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  widget.user.name.isNotEmpty
                      ? widget.user.name[0].toUpperCase()
                      : 'C',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.name.isNotEmpty ? widget.user.name : 'Client',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    'Client régulier',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Déconnexion',
                onPressed: _showLogoutDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delivery_dining, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Livraison Express',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Espace Client',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _buildSidebarItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Tableau de bord'),
          _buildSidebarItem(1, Icons.restaurant_menu_outlined, Icons.restaurant_menu, 'Catalogue'),
          _buildSidebarItem(2, Icons.storefront_outlined, Icons.storefront, 'Boutiques'),
          _buildSidebarItem(
            3,
            Icons.shopping_bag_outlined,
            Icons.shopping_bag,
            'Mon panier',
            badgeCount: _controller.totalItemCount,
          ),
          _buildSidebarItem(4, Icons.receipt_long_outlined, Icons.receipt_long, 'Mes commandes'),
          _buildSidebarItem(5, Icons.person_outline, Icons.person, 'Mon profil'),
          const Spacer(),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
              onTap: _showLogoutDialog,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String title, {
    int badgeCount = 0,
  }) {
    final isSelected = _controller.currentTab == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selected: isSelected,
        selectedTileColor: Colors.deepOrange.withAlpha(25),
        leading: Icon(
          isSelected ? selectedIcon : icon,
          color: isSelected ? Colors.deepOrange : Colors.grey.shade700,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.deepOrange : Colors.black87,
          ),
        ),
        trailing: badgeCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              )
            : null,
        onTap: () => _controller.setTab(index),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_controller.currentTab) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildCatalogTab();
      case 2:
        return _buildShopsTab();
      case 3:
        return _buildCartTab();
      case 4:
        return _buildOrdersTab();
      case 5:
        return _buildProfileTab();
      default:
        return _buildDashboardTab();
    }
  }

  // ==========================================
  // 1. DASHBOARD OVERVIEW
  // ==========================================
  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bannière de bienvenue
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepOrange.withAlpha(50),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenue, ${widget.user.name} 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Découvrez les commerces à proximité, commandez vos repas ou articles et suivez votre livreur en direct.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepOrange,
                        ),
                        onPressed: () => _controller.setTab(1),
                        child: const Text('Commander maintenant', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.fastfood_outlined, color: Colors.white, size: 64),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // KPIs en temps réel
          StreamBuilder<List<OrderModel>>(
            stream: _controller.watchOrders(widget.user.uid),
            builder: (context, snapshot) {
              final orders = snapshot.data ?? [];
              final pendingCount = orders
                  .where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled)
                  .length;
              final deliveredCount = orders
                  .where((o) => o.status == OrderStatus.delivered)
                  .length;
              final totalSpent = orders
                  .where((o) => o.status == OrderStatus.delivered)
                  .fold(0.0, (sum, o) => sum + o.total);

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 650;
                  return GridView.count(
                    crossAxisCount: isWide ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: isWide ? 1.5 : 1.3,
                    children: [
                      _buildKpiCard(
                        title: 'En cours',
                        value: '$pendingCount',
                        icon: Icons.hourglass_top,
                        color: Colors.orange,
                      ),
                      _buildKpiCard(
                        title: 'Commandes livrées',
                        value: '$deliveredCount',
                        icon: Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                      _buildKpiCard(
                        title: 'Total dépensé',
                        value: '${totalSpent.toStringAsFixed(1)} DT',
                        icon: Icons.account_balance_wallet_outlined,
                        color: Colors.blue,
                      ),
                      _buildKpiCard(
                        title: 'Panier actuel',
                        value: '${_controller.totalItemCount} art.',
                        icon: Icons.shopping_bag_outlined,
                        color: Colors.deepOrange,
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 28),

          // Actions rapides
          const Text(
            'Actions rapides',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionTile(
                  icon: Icons.restaurant,
                  title: 'Parcourir catalogue',
                  color: Colors.deepOrange,
                  onTap: () => _controller.setTab(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionTile(
                  icon: Icons.storefront,
                  title: 'Boutiques partenaires',
                  color: Colors.purple,
                  onTap: () => _controller.setTab(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionTile(
                  icon: Icons.receipt_long,
                  title: 'Historique commandes',
                  color: Colors.blue,
                  onTap: () => _controller.setTab(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Produits populaires / recommandés
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recommandés pour vous',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => _controller.setTab(1),
                child: const Text('Voir tout'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPopularHorizontalList(),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withAlpha(30),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularHorizontalList() {
    final products = _controller.popularProducts.isNotEmpty
        ? _controller.popularProducts
        : _controller.filteredProducts.take(5).toList();

    if (products.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Text('Les produits ajoutés par les vendeurs apparaîtront ici.'),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final p = products[index];
          return SizedBox(
            width: 200,
            child: _buildProductItemCard(p),
          );
        },
      ),
    );
  }

  // ==========================================
  // 2. CATALOGUE & RECHERCHE DE PRODUITS
  // ==========================================
  Widget _buildCatalogTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre de recherche
          TextField(
            onChanged: (val) => _controller.setSearchQuery(val),
            decoration: InputDecoration(
              hintText: 'Rechercher un plat, burger, pizza, article...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _controller.setSearchQuery(''),
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Filtre par boutique si sélectionnée
          if (_controller.selectedShopName != null && _controller.selectedShopName!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Chip(
                avatar: const Icon(Icons.storefront, size: 16),
                label: Text('Boutique : ${_controller.selectedShopName}'),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _controller.setSelectedShop(null),
              ),
            ),

          // Chips de catégories
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _controller.selectedCategory.toLowerCase() == (cat['name'] as String).toLowerCase();
                return ChoiceChip(
                  avatar: Icon(cat['icon'] as IconData, size: 16),
                  label: Text(cat['name'] as String),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) _controller.setCategory(cat['name'] as String);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Grille des produits
          _buildProductsGrid(),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    final products = _controller.filteredProducts;

    if (products.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Aucun produit trouvé',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Modifiez vos filtres ou ajoutez des produits depuis l\'espace vendeur.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : (constraints.maxWidth > 600 ? 3 : 2);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final p = products[index];
            return _buildProductItemCard(p);
          },
        );
      },
    );
  }

  Widget _buildProductItemCard(Product p) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / placeholder
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.deepOrange.withAlpha(15),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: p.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        p.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _productDefaultIcon(),
                      ),
                    )
                  : _productDefaultIcon(),
            ),
          ),
          // Info produit
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          p.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  p.shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${p.price.toStringAsFixed(2)} DT',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.deepOrange,
                      ),
                    ),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        padding: const EdgeInsets.all(6),
                        minimumSize: const Size(32, 32),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () {
                        _controller.addToCart(p);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${p.name} ajouté au panier'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _productDefaultIcon() {
    return const Center(
      child: Icon(Icons.lunch_dining, size: 44, color: Colors.deepOrange),
    );
  }

  // ==========================================
  // 3. BOUTIQUES PARTENAIRES
  // ==========================================
  Widget _buildShopsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _shopSearchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Rechercher une boutique partenaire...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _shopSearchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _shopSearchCtrl.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Liste des boutiques - source combinée boutiques + vendeurs
          _BoutiquesStreamWidget(
            searchQuery: _shopSearchCtrl.text.trim().toLowerCase(),
            onBoutiqueSelected: (shopName) {
              _controller.setSelectedShop(shopName);
              _controller.setTab(1);
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. PANIER & PROCESSUS DE COMMANDE (CHECKOUT)
  // ==========================================
  Widget _buildCartTab() {
    if (_controller.cartItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_basket_outlined, size: 72, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Votre panier est vide',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                'Explorez le catalogue et ajoutez vos plats préférés.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
                onPressed: () => _controller.setTab(1),
                child: const Text('Découvrir les plats'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 750;

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildCartItemsList()),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: _buildCheckoutSummaryCard()),
              ],
            );
          }

          return Column(
            children: [
              _buildCartItemsList(),
              const SizedBox(height: 24),
              _buildCheckoutSummaryCard(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItemsList() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Articles du panier',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => _controller.clearCart(),
                  child: const Text('Vider le panier', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
            const Divider(),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _controller.cartItems.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _controller.cartItems[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.deepOrange.withAlpha(20),
                        child: const Icon(Icons.fastfood, color: Colors.deepOrange, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              '${item.product.price.toStringAsFixed(2)} DT | ${item.product.shopName}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 22),
                            onPressed: () => _controller.decrementQuantity(item.product),
                          ),
                          Text(
                            '${item.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 22),
                            onPressed: () => _controller.incrementQuantity(item.product),
                          ),
                        ],
                      ),
                      Text(
                        '${item.totalPrice.toStringAsFixed(2)} DT',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutSummaryCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Finaliser la commande',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Adresse de livraison
            TextFormField(
              controller: _controller.addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Adresse de livraison *',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Téléphone de livraison
            TextFormField(
              controller: _controller.phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Numéro de téléphone *',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Instructions / Notes pour le livreur
            TextFormField(
              controller: _controller.notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Instructions de livraison (optionnel)',
                prefixIcon: Icon(Icons.notes),
                hintText: 'Étage, sonnette, repère...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Mode de paiement
            DropdownButtonFormField<String>(
              initialValue: _controller.selectedPaymentMethod,
              decoration: const InputDecoration(
                labelText: 'Moyen de paiement',
                prefixIcon: Icon(Icons.payment),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Paiement en espèces à la livraison',
                  child: Text('Espèces à la livraison'),
                ),
                DropdownMenuItem(
                  value: 'Paiement par carte bancaire',
                  child: Text('Carte bancaire'),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _controller.selectedPaymentMethod = val);
                }
              },
            ),
            const SizedBox(height: 16),

            // Code Promo
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoInputCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Code Promo',
                      hintText: 'BIENVENUE / PROMO20',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () {
                    final ok = _controller.applyPromo(_promoInputCtrl.text);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? 'Code promo appliqué avec succès !'
                            : 'Code promo invalide.'),
                      ),
                    );
                  },
                  child: const Text('Appliquer'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),

            // Détails du prix
            _buildPriceRow('Sous-total', '${_controller.subtotal.toStringAsFixed(2)} DT'),
            const SizedBox(height: 6),
            _buildPriceRow('Frais de livraison', '${_controller.deliveryFee.toStringAsFixed(2)} DT'),
            if (_controller.discountAmount > 0) ...[
              const SizedBox(height: 6),
              _buildPriceRow('Remise promo', '-${_controller.discountAmount.toStringAsFixed(2)} DT', color: Colors.green),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total à payer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                Text(
                  '${_controller.total.toStringAsFixed(2)} DT',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bouton de confirmation
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
                onPressed: _controller.isSubmittingOrder
                    ? null
                    : () async {
                        final err = await _controller.placeOrder(widget.user);
                        if (!mounted) return;
                        if (err != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err), backgroundColor: Colors.red),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Votre commande a été transmise avec succès !'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _controller.setTab(4); // Bascule sur Mes Commandes
                        }
                      },
                icon: _controller.isSubmittingOrder
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _controller.isSubmittingOrder ? 'Transmission en cours...' : 'Confirmer et Commander',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade700)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  // ==========================================
  // 5. MES COMMANDES & SUIVI EN DIRECT
  // ==========================================
  Widget _buildOrdersTab() {
    return StreamBuilder<List<OrderModel>>(
      stream: _controller.watchOrders(widget.user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 68, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune commande trouvée',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vos commandes passées apparaîtront ici avec leur suivi en temps réel.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
                    onPressed: () => _controller.setTab(1),
                    child: const Text('Passer ma première commande'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: orders.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderTrackingCard(order);
          },
        );
      },
    );
  }

  Widget _buildOrderTrackingCard(OrderModel order) {
    Color statusColor;
    switch (order.status) {
      case OrderStatus.pending:
        statusColor = Colors.orange;
        break;
      case OrderStatus.preparing:
        statusColor = Colors.blue;
        break;
      case OrderStatus.ready:
        statusColor = Colors.purple;
        break;
      case OrderStatus.assigned:
      case OrderStatus.pickedUp:
      case OrderStatus.delivering:
        statusColor = Colors.indigo;
        break;
      case OrderStatus.delivered:
        statusColor = Colors.green;
        break;
      case OrderStatus.cancelled:
        statusColor = Colors.red;
        break;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commande #${order.id.length >= 6 ? order.id.substring(0, 6).toUpperCase() : order.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      order.vendorName.isNotEmpty ? order.vendorName : 'Boutique Partenaire',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status.label,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Stepper de suivi de statut
            _buildOrderStatusStepper(order.status),
            const SizedBox(height: 16),

            // Articles de la commande
            ...order.items.map((it) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${it.quantity}x ${it.name}'),
                      Text('${(it.price * it.quantity).toStringAsFixed(2)} DT'),
                    ],
                  ),
                )),
            const Divider(height: 20),

            // Information livreur si assigné
            if (order.courierName != null && order.courierName!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.two_wheeler, color: Colors.indigo),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Livreur : ${order.courierName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (order.courierPhone != null && order.courierPhone!.isNotEmpty)
                            Text('Contact : ${order.courierPhone}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Total et actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total payé', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    Text(
                      '${order.total.toStringAsFixed(2)} DT',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepOrange),
                    ),
                  ],
                ),
                if (order.status == OrderStatus.pending)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Annuler'),
                    onPressed: () async {
                      await _controller.cancelOrder(order.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Commande annulée.')),
                        );
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusStepper(OrderStatus currentStatus) {
    final steps = [
      OrderStatus.pending,
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.delivering,
      OrderStatus.delivered,
    ];

    if (currentStatus == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('Cette commande a été annulée', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ),
      );
    }

    int currentStepIndex = steps.indexOf(currentStatus);
    if (currentStepIndex == -1) {
      if (currentStatus == OrderStatus.assigned || currentStatus == OrderStatus.pickedUp) {
        currentStepIndex = 3; // En cours de livraison
      } else {
        currentStepIndex = 0;
      }
    }

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final lineIndex = i ~/ 2;
          final isPassed = currentStepIndex > lineIndex;
          return Expanded(
            child: Container(
              height: 3,
              color: isPassed ? Colors.green : Colors.grey.shade300,
            ),
          );
        } else {
          final stepIndex = i ~/ 2;
          final isCompleted = currentStepIndex >= stepIndex;
          return CircleAvatar(
            radius: 12,
            backgroundColor: isCompleted ? Colors.green : Colors.grey.shade300,
            child: Icon(
              isCompleted ? Icons.check : Icons.circle,
              size: 14,
              color: Colors.white,
            ),
          );
        }
      }),
    );
  }

  // ==========================================
  // 6. PROFIL CLIENT
  // ==========================================
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    widget.user.name.isNotEmpty
                        ? widget.user.name[0].toUpperCase()
                        : 'C',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.user.name.isNotEmpty ? widget.user.name : 'Client',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  widget.user.email,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Coordonnées personnelles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _profileNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nom complet',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _profilePhoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de téléphone',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _profileAddressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Adresse par défaut',
                      prefixIcon: Icon(Icons.home_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _profileCityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ville / Gouvernorat',
                      prefixIcon: Icon(Icons.location_city_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
                      onPressed: () async {
                        final ok = await _controller.updateProfile(
                          widget.user.uid,
                          name: _profileNameCtrl.text.trim(),
                          phone: _profilePhoneCtrl.text.trim(),
                          address: _profileAddressCtrl.text.trim(),
                          city: _profileCityCtrl.text.trim(),
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? 'Profil mis à jour avec succès !'
                                  : 'Erreur lors de la mise à jour.'),
                            ),
                          );
                        }
                      },
                      child: const Text('Enregistrer les modifications'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              onPressed: _showLogoutDialog,
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Widget autonome pour charger et afficher les boutiques.
// Gère les erreurs de règles Firestore en basculant automatiquement vers
// la collection `users` si `boutiques` est inaccessible.
// ═══════════════════════════════════════════════════════════════════════════
class _BoutiquesStreamWidget extends StatefulWidget {
  final String searchQuery;
  final void Function(String shopName) onBoutiqueSelected;

  const _BoutiquesStreamWidget({
    required this.searchQuery,
    required this.onBoutiqueSelected,
  });

  @override
  State<_BoutiquesStreamWidget> createState() => _BoutiquesStreamWidgetState();
}

class _BoutiquesStreamWidgetState extends State<_BoutiquesStreamWidget> {
  // true = lecture OK depuis 'boutiques', false = fallback 'users', null = en cours
  bool? _usesBoutiquesCollection;

  @override
  void initState() {
    super.initState();
    _detectSource();
  }

  /// Vérifie quelle collection est accessible avec les règles Firestore actuelles.
  Future<void> _detectSource() async {
    try {
      await FirebaseFirestore.instance.collection('boutiques').limit(1).get();
      if (mounted) setState(() => _usesBoutiquesCollection = true);
    } catch (_) {
      // Règles Firestore bloquent 'boutiques' → fallback vers 'users'
      if (mounted) setState(() => _usesBoutiquesCollection = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // En attente de la détection de source
    if (_usesBoutiquesCollection == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_usesBoutiquesCollection == true) {
      // ── Source principale: collection 'boutiques' ──
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('boutiques').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
              child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            // La règle a changé en cours de session → basculer
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _usesBoutiquesCollection = false);
            });
            return const Center(
              child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
            );
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            // 'boutiques' accessible mais vide → regarder aussi dans 'users'
            return _buildFromUsersStream();
          }
          return _BoutiquesList(
            docs: docs,
            fromUsers: false,
            searchQuery: widget.searchQuery,
            onBoutiqueSelected: widget.onBoutiqueSelected,
          );
        },
      );
    } else {
      // ── Fallback: collection 'users' avec role='vendeur' ──
      return _buildFromUsersStream();
    }
  }

  Widget _buildFromUsersStream() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'vendeur')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(
            child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return _buildPermissionError();
        }
        final docs = snapshot.data?.docs ?? [];
        return _BoutiquesList(
          docs: docs,
          fromUsers: true,
          searchQuery: widget.searchQuery,
          onBoutiqueSelected: widget.onBoutiqueSelected,
        );
      },
    );
  }

  Widget _buildPermissionError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_outline, size: 52, color: Colors.orange.shade400),
          const SizedBox(height: 12),
          const Text(
            'Accès restreint',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Les boutiques ne sont pas encore accessibles. '
            'Demandez à l\'administrateur de configurer les règles Firestore.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _usesBoutiquesCollection = null);
              _detectSource();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Widget de liste des boutiques (stateless, réutilisable).
// ═══════════════════════════════════════════════════════════════════════════
class _BoutiquesList extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final bool fromUsers;
  final String searchQuery;
  final void Function(String shopName) onBoutiqueSelected;

  const _BoutiquesList({
    required this.docs,
    required this.fromUsers,
    required this.searchQuery,
    required this.onBoutiqueSelected,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = docs.where((doc) {
      final data = doc.data();
      final profile = fromUsers
          ? Map<String, dynamic>.from(data['profile'] as Map? ?? {})
          : data;
      final shopName =
          ((profile['nomBoutique'] ?? profile['shopName'] ?? data['name']) as String? ?? '')
              .toLowerCase();
      final category =
          ((profile['categorie'] ?? profile['category']) as String? ?? '').toLowerCase();
      final city =
          ((profile['ville'] ?? profile['city']) as String? ?? '').toLowerCase();
      return searchQuery.isEmpty ||
          shopName.contains(searchQuery) ||
          category.contains(searchQuery) ||
          city.contains(searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.storefront_outlined, size: 52, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Aucune boutique trouvée',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Les commerces inscrits sur la plateforme apparaîtront automatiquement ici.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final data = filtered[index].data();
        final profile = fromUsers
            ? Map<String, dynamic>.from(data['profile'] as Map? ?? {})
            : data;

        final shopName =
            (profile['nomBoutique'] ?? profile['shopName'] ?? data['name'] ?? 'Boutique') as String;
        final category = (profile['categorie'] ?? profile['category'] ?? 'Commerce') as String;
        final address =
            (profile['adresse'] ?? profile['address'] ?? profile['ville'] ?? profile['city'] ?? 'Tunis') as String;
        final city = (profile['ville'] ?? profile['city'] ?? '') as String;
        final description = (profile['description'] as String?) ?? '';
        final horaires = (profile['horaires'] as String?) ?? '';
        final isOpen = (profile['disponible'] ?? profile['isOpen']) as bool? ?? true;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onBoutiqueSelected(shopName),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.deepOrange.withAlpha(25),
                    child: const Icon(Icons.store, color: Colors.deepOrange),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                shopName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isOpen
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isOpen ? 'Ouvert' : 'Fermé',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isOpen
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          city.isNotEmpty && city != address
                              ? '$category | $address ($city)'
                              : '$category | $address',
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (horaires.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                horaires,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
