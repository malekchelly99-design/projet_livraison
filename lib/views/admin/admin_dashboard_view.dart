import 'package:flutter/material.dart';
import '../../controllers/admin_dashboard_controller.dart';
import '../../models/app_user.dart';
import '../../models/order_model.dart';
import '../../models/product.dart';
import '../../models/user_role.dart';

class AdminDashboardView extends StatefulWidget {
  final AppUser user;
  final VoidCallback onLogout;

  const AdminDashboardView({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  late final AdminDashboardController _controller;

  // Controllers pour recherche et formulaires
  final TextEditingController _orderSearchCtrl = TextEditingController();
  final TextEditingController _userSearchCtrl = TextEditingController();
  final TextEditingController _productSearchCtrl = TextEditingController();

  final List<String> _productCategories = const [
    'Tous',
    'Plats',
    'Sandwiches',
    'Pizzas',
    'Boissons',
    'Desserts',
    'Épicerie',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AdminDashboardController(user: widget.user);
  }

  @override
  void dispose() {
    _orderSearchCtrl.dispose();
    _userSearchCtrl.dispose();
    _productSearchCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter du portail administrateur ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.deepOrange,
            ),
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;

            if (isDesktop) {
              return Scaffold(
                backgroundColor: const Color(0xFFF8FAFC),
                body: Row(
                  children: [
                    _buildSidebar(),
                    const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                    Expanded(
                      child: Column(
                        children: [
                          _buildTopHeader(),
                          Expanded(
                            child: _controller.isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(color: Colors.deepOrange),
                                  )
                                : _buildCurrentTab(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            // Version Mobile / Tablette
            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: AppBar(
                title: Text(
                  _getTabTitle(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                backgroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 2,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: Color(0xFF64748B)),
                    tooltip: 'Déconnexion',
                    onPressed: _showLogoutDialog,
                  ),
                ],
              ),
              drawer: _buildMobileDrawer(),
              body: _controller.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.deepOrange),
                    )
                  : _buildCurrentTab(),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _controller.currentTab > 3 ? 0 : _controller.currentTab,
                onDestinationSelected: _controller.setTab,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard, color: Colors.deepOrange),
                    label: 'Aperçu',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long, color: Colors.deepOrange),
                    label: 'Commandes',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.people_alt_outlined),
                    selectedIcon: Icon(Icons.people_alt, color: Colors.deepOrange),
                    label: 'Utilisateurs',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.inventory_2_outlined),
                    selectedIcon: Icon(Icons.inventory_2, color: Colors.deepOrange),
                    label: 'Catalogue',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getTabTitle() {
    switch (_controller.currentTab) {
      case 0:
        return 'Tableau de bord Administrateur';
      case 1:
        return 'Gestion des Commandes';
      case 2:
        return 'Gestion des Utilisateurs';
      case 3:
        return 'Catalogue & Produits';
      case 4:
        return 'Boutiques & Vendeurs';
      case 5:
        return 'Flotte de Livreurs';
      case 6:
        return 'Paramètres & Maintenance';
      default:
        return 'Administration';
    }
  }

  // --- HEADER SUPERIEUR ---
  Widget _buildTopHeader() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                _getTabTitle(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'En direct',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Bouton Démo rapide si peu de données
              if (_controller.orders.isEmpty || _controller.products.isEmpty)
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF7ED),
                    foregroundColor: Colors.deepOrange,
                  ),
                  onPressed: () => _confirmSeedDemoData(),
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                  label: const Text('Injecter données démo'),
                ),
              const SizedBox(width: 16),
              // Profil Admin
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFFFEDD5),
                child: const Icon(Icons.admin_panel_settings, color: Colors.deepOrange, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.name.isNotEmpty ? widget.user.name : 'Administrateur',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                  ),
                  const Text(
                    'Super Admin',
                    style: TextStyle(fontSize: 11, color: Colors.deepOrange, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.logout, color: Color(0xFF64748B)),
                tooltip: 'Déconnexion',
                onPressed: _showLogoutDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SIDEBAR DESKTOP ---
  Widget _buildSidebar() {
    return Container(
      width: 270,
      color: Colors.white,
      child: Column(
        children: [
          // Logo & Branding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.deepOrange, Color(0xFFFF8A65)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepOrange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.delivery_dining, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Livraison Pro',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Console Admin',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSidebarItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Vue d\'ensemble'),
                _buildSidebarItem(
                  1,
                  Icons.receipt_long_outlined,
                  Icons.receipt_long,
                  'Commandes',
                  badgeText: _controller.activeOrdersCount > 0
                      ? '${_controller.activeOrdersCount}'
                      : null,
                ),
                _buildSidebarItem(
                  2,
                  Icons.people_alt_outlined,
                  Icons.people_alt,
                  'Utilisateurs',
                  badgeText: '${_controller.users.length}',
                ),
                _buildSidebarItem(3, Icons.inventory_2_outlined, Icons.inventory_2, 'Catalogue & Produits'),
                _buildSidebarItem(4, Icons.storefront_outlined, Icons.storefront, 'Boutiques & Vendeurs'),
                _buildSidebarItem(5, Icons.two_wheeler_outlined, Icons.two_wheeler, 'Flotte Livreurs'),
                _buildSidebarItem(6, Icons.tune_outlined, Icons.tune, 'Paramètres & Outils'),
              ],
            ),
          ),
          // Footer Sidebar
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFEDD5)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.deepOrange,
                  child: Text(
                    widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'A',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.name.isNotEmpty ? widget.user.name : 'Administrateur',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.user.email,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 20, color: Colors.deepOrange),
                  onPressed: _showLogoutDialog,
                  tooltip: 'Déconnexion',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, IconData activeIcon, String label, {String? badgeText}) {
    final isSelected = _controller.currentTab == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isSelected ? const Color(0xFFFFF7ED) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _controller.setTab(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 22,
                  color: isSelected ? Colors.deepOrange : const Color(0xFF64748B),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.deepOrange : const Color(0xFF334155),
                    ),
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.deepOrange : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- DRAWER MOBILE ---
  Widget _buildMobileDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFFFFF7ED),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delivery_dining, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Livraison Rapide',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Panneau Admin',
                        style: TextStyle(fontSize: 12, color: Colors.deepOrange, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildSidebarItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Vue d\'ensemble'),
                  _buildSidebarItem(1, Icons.receipt_long_outlined, Icons.receipt_long, 'Commandes'),
                  _buildSidebarItem(2, Icons.people_alt_outlined, Icons.people_alt, 'Utilisateurs'),
                  _buildSidebarItem(3, Icons.inventory_2_outlined, Icons.inventory_2, 'Catalogue & Produits'),
                  _buildSidebarItem(4, Icons.storefront_outlined, Icons.storefront, 'Boutiques & Vendeurs'),
                  _buildSidebarItem(5, Icons.two_wheeler_outlined, Icons.two_wheeler, 'Flotte Livreurs'),
                  _buildSidebarItem(6, Icons.tune_outlined, Icons.tune, 'Paramètres & Outils'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CONTENU PRINCIPAL SELON TAB ACTUEL ---
  Widget _buildCurrentTab() {
    switch (_controller.currentTab) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildOrdersTab();
      case 2:
        return _buildUsersTab();
      case 3:
        return _buildCatalogTab();
      case 4:
        return _buildVendorsTab();
      case 5:
        return _buildCouriersTab();
      case 6:
        return _buildSettingsTab();
      default:
        return _buildOverviewTab();
    }
  }

  // =========================================================================
  // TAB 0 : VUE D'ENSEMBLE (OVERVIEW & ANALYTICS)
  // =========================================================================
  Widget _buildOverviewTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;
        final screenPadding = isWide ? 24.0 : 16.0;
        final sectionSpacing = isWide ? 24.0 : 16.0;
        final cardPadding = isWide ? 20.0 : 14.0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner d'accueil admin
              Container(
                padding: EdgeInsets.all(isWide ? 22 : 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEA580C), Color(0xFFFF8A65)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrange.withOpacity(0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
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
                            'Bonjour, ${widget.user.name.isNotEmpty ? widget.user.name : "Administrateur"} 🚀',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isWide ? 22 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Supervisez en temps réel les commandes, les boutiques partenaires, la flotte de livraison et les utilisateurs de la plateforme.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: isWide ? 14 : 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.all(isWide ? 12 : 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.shield_outlined, size: isWide ? 40 : 32, color: Colors.white),
                    ),
                  ],
                ),
              ),
              SizedBox(height: sectionSpacing),

              // Cartes KPI Principales
              GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: isWide ? 16 : 10,
                crossAxisSpacing: isWide ? 16 : 10,
                childAspectRatio: isWide ? 1.4 : 1.12,
                children: [
                  _buildKpiCard(
                    title: 'Chiffre d\'Affaires',
                    value: '${_controller.totalRevenue.toStringAsFixed(1)} DT',
                    subtitle: 'Commission : ${_controller.platformCommission.toStringAsFixed(1)} DT',
                    icon: Icons.payments_outlined,
                    accentColor: Colors.deepOrange,
                    isWide: isWide,
                  ),
                  _buildKpiCard(
                    title: 'Total Commandes',
                    value: '${_controller.totalOrdersCount}',
                    subtitle: '${_controller.deliveredOrdersCount} livrées • ${_controller.activeOrdersCount} en cours',
                    icon: Icons.shopping_bag_outlined,
                    accentColor: const Color(0xFF2563EB),
                    isWide: isWide,
                  ),
                  _buildKpiCard(
                    title: 'Utilisateurs Actifs',
                    value: '${_controller.users.length}',
                    subtitle: '${_controller.clients.length} clients • ${_controller.couriers.length} livreurs',
                    icon: Icons.group_outlined,
                    accentColor: const Color(0xFF059669),
                    isWide: isWide,
                  ),
                  _buildKpiCard(
                    title: 'Produits au Catalogue',
                    value: '${_controller.products.length}',
                    subtitle: '${_controller.vendors.length} boutiques partenaires',
                    icon: Icons.storefront_outlined,
                    accentColor: const Color(0xFF7C3AED),
                    isWide: isWide,
                  ),
                ],
              ),
              SizedBox(height: sectionSpacing),

              // Statut des commandes & actions rapides
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildOrderStatusCard(cardPadding),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildQuickActionsCard(cardPadding),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildOrderStatusCard(cardPadding),
                    const SizedBox(height: 14),
                    _buildQuickActionsCard(cardPadding),
                  ],
                ),
              SizedBox(height: sectionSpacing),

              // Dernières Commandes
              Container(
                padding: EdgeInsets.all(cardPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Dernières Commandes Passées',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        TextButton(
                          onPressed: () => _controller.setTab(1),
                          child: const Text('Voir toutes', style: TextStyle(color: Colors.deepOrange)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_controller.orders.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              const Text('Aucune commande enregistrée pour l\'instant.'),
                              const SizedBox(height: 10),
                              FilledButton.tonal(
                                onPressed: _confirmSeedDemoData,
                                child: const Text('Générer des commandes de test'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _controller.orders.take(5).length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (ctx, index) {
                          final order = _controller.orders[index];
                          return _buildRecentOrderRow(order);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderStatusCard(double padding) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'État des Commandes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 16),
          _buildStatusProgressBar(),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _buildStatusLegendItem('En attente', _controller.pendingOrdersCount, const Color(0xFFF59E0B)),
              _buildStatusLegendItem('En préparation', _controller.preparingOrdersCount, Colors.deepOrange),
              _buildStatusLegendItem('En livraison', _controller.inDeliveryOrdersCount, const Color(0xFF0284C7)),
              _buildStatusLegendItem('Livrées', _controller.deliveredOrdersCount, const Color(0xFF10B981)),
              _buildStatusLegendItem('Annulées', _controller.cancelledOrdersCount, const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(double padding) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions Rapides',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 14),
          _buildQuickActionTile(
            icon: Icons.receipt_long,
            title: 'Toutes les Commandes',
            subtitle: '${_controller.orders.length} commandes au total',
            onTap: () => _controller.setTab(1),
          ),
          _buildQuickActionTile(
            icon: Icons.person_add_outlined,
            title: 'Gestion des Rôles',
            subtitle: 'Promouvoir ou administrer les comptes',
            onTap: () => _controller.setTab(2),
          ),
          _buildQuickActionTile(
            icon: Icons.add_box_outlined,
            title: 'Ajouter un Produit',
            subtitle: 'Enrichir le catalogue global',
            onTap: () => _showAddProductDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    bool isWide = true,
  }) {
    return Container(
      padding: EdgeInsets.all(isWide ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isWide ? 13 : 11.5,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: EdgeInsets.all(isWide ? 8 : 6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: isWide ? 20 : 16),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isWide ? 22 : 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: isWide ? 11 : 10,
              color: const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusProgressBar() {
    final total = _controller.totalOrdersCount;
    if (total == 0) {
      return Container(
        height: 12,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }

    final pPending = _controller.pendingOrdersCount / total;
    final pPreparing = _controller.preparingOrdersCount / total;
    final pDelivering = _controller.inDeliveryOrdersCount / total;
    final pDelivered = _controller.deliveredOrdersCount / total;
    final pCancelled = _controller.cancelledOrdersCount / total;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 12,
        child: Row(
          children: [
            if (pPending > 0)
              Expanded(
                flex: (pPending * 100).round(),
                child: Container(color: const Color(0xFFF59E0B)),
              ),
            if (pPreparing > 0)
              Expanded(
                flex: (pPreparing * 100).round(),
                child: Container(color: Colors.deepOrange),
              ),
            if (pDelivering > 0)
              Expanded(
                flex: (pDelivering * 100).round(),
                child: Container(color: const Color(0xFF0284C7)),
              ),
            if (pDelivered > 0)
              Expanded(
                flex: (pDelivered * 100).round(),
                child: Container(color: const Color(0xFF10B981)),
              ),
            if (pCancelled > 0)
              Expanded(
                flex: (pCancelled * 100).round(),
                child: Container(color: const Color(0xFFEF4444)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLegendItem(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        Text(
          '$count',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
      ],
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.deepOrange, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentOrderRow(OrderModel order) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFFFF7ED),
            child: const Icon(Icons.receipt, color: Colors.deepOrange, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.clientName.isNotEmpty ? order.clientName : 'Client inconnu',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${order.vendorName.isNotEmpty ? order.vendorName : "Boutique"} • ${order.items.length} article(s)',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _buildStatusBadge(order.status),
          const SizedBox(width: 8),
          Text(
            '${order.total.toStringAsFixed(1)} DT',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.remove_red_eye_outlined, size: 18, color: Colors.deepOrange),
            tooltip: 'Détails',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _showOrderDetailsDialog(order),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1 : GESTION DES COMMANDES (ORDERS)
  // =========================================================================
  Widget _buildOrdersTab() {
    final filtered = _controller.filteredOrders;

    return Column(
      children: [
        // Filtres et barre de recherche
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _orderSearchCtrl,
                      onChanged: _controller.setOrderSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Rechercher par client, boutique, livreur, adresse...',
                        prefixIcon: const Icon(Icons.search, color: Colors.deepOrange),
                        suffixIcon: _orderSearchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _orderSearchCtrl.clear();
                                  _controller.setOrderSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Pills de statut
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildOrderFilterChip('Toutes', null),
                    _buildOrderFilterChip('En attente', OrderStatus.pending),
                    _buildOrderFilterChip('En préparation', OrderStatus.preparing),
                    _buildOrderFilterChip('Prête', OrderStatus.ready),
                    _buildOrderFilterChip('Assignée', OrderStatus.assigned),
                    _buildOrderFilterChip('En cours', OrderStatus.delivering),
                    _buildOrderFilterChip('Livrée', OrderStatus.delivered),
                    _buildOrderFilterChip('Annulée', OrderStatus.cancelled),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // Liste des commandes
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('Aucune commande correspondant aux critères.'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final order = filtered[index];
                    return _buildOrderCard(order);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildOrderFilterChip(String label, OrderStatus? status) {
    final isSelected = _controller.selectedOrderStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFFFFF7ED),
        labelStyle: TextStyle(
          color: isSelected ? Colors.deepOrange : const Color(0xFF475569),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? Colors.deepOrange : const Color(0xFFE2E8F0),
        ),
        checkmarkColor: Colors.deepOrange,
        onSelected: (_) => _controller.setOrderStatusFilter(status),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year} à ${order.createdAt.hour}h${order.createdAt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            const Divider(height: 20, color: Color(0xFFF1F5F9)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_pin, size: 16, color: Colors.deepOrange),
                          const SizedBox(width: 6),
                          Text(
                            order.clientName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${order.clientPhone})',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              order.deliveryAddress,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.storefront, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            'Boutique: ${order.vendorName.isNotEmpty ? order.vendorName : "Partenaire"}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.two_wheeler, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            order.courierName != null && order.courierName!.isNotEmpty
                                ? 'Livreur: ${order.courierName} (${order.courierPhone ?? ""})'
                                : 'Livreur: Non assigné',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: order.courierName != null ? FontWeight.w600 : FontWeight.normal,
                              color: order.courierName != null ? Colors.deepOrange : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${order.total.toStringAsFixed(1)} DT',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Sous-total: ${order.subtotal.toStringAsFixed(1)} + Liv: ${order.deliveryFee.toStringAsFixed(1)} DT',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.paymentMethod,
                        style: const TextStyle(fontSize: 11, color: Colors.deepOrange, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepOrange,
                    side: const BorderSide(color: Color(0xFFFFEDD5)),
                    backgroundColor: const Color(0xFFFFF7ED),
                  ),
                  icon: const Icon(Icons.two_wheeler, size: 16),
                  label: const Text('Assigner Livreur'),
                  onPressed: () => _showAssignCourierDialog(order),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  icon: const Icon(Icons.edit_note, size: 16),
                  label: const Text('Statut'),
                  onPressed: () => _showChangeOrderStatusDialog(order),
                ),
                const SizedBox(width: 10),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF0F172A),
                  ),
                  onPressed: () => _showOrderDetailsDialog(order),
                  child: const Text('Détails'),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                  tooltip: 'Supprimer la commande',
                  onPressed: () => _confirmDeleteOrder(order),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 2 : GESTION DES UTILISATEURS (USERS & ROLES)
  // =========================================================================
  Widget _buildUsersTab() {
    final filtered = _controller.filteredUsers;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _userSearchCtrl,
                      onChanged: _controller.setUserSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Rechercher par nom, email, téléphone, boutique...',
                        prefixIcon: const Icon(Icons.search, color: Colors.deepOrange),
                        suffixIcon: _userSearchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _userSearchCtrl.clear();
                                  _controller.setUserSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Pills de rôles
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildUserRoleChip('Tous (${_controller.users.length})', null),
                    _buildUserRoleChip('Clients (${_controller.clients.length})', UserRole.client),
                    _buildUserRoleChip('Vendeurs (${_controller.vendors.length})', UserRole.vendeur),
                    _buildUserRoleChip('Livreurs (${_controller.couriers.length})', UserRole.livreur),
                    _buildUserRoleChip('Admins (${_controller.admins.length})', UserRole.admin),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('Aucun utilisateur correspondant trouvé.'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final u = filtered[index];
                    return _buildUserCard(u);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildUserRoleChip(String label, UserRole? role) {
    final isSelected = _controller.selectedUserRole == role;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFFFFF7ED),
        labelStyle: TextStyle(
          color: isSelected ? Colors.deepOrange : const Color(0xFF475569),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? Colors.deepOrange : const Color(0xFFE2E8F0),
        ),
        checkmarkColor: Colors.deepOrange,
        onSelected: (_) => _controller.setUserRoleFilter(role),
      ),
    );
  }

  Widget _buildUserCard(AppUser u) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _roleColor(u.role).withOpacity(0.15),
              child: Text(
                u.name.isNotEmpty ? u.name[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: _roleColor(u.role),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        u.name.isNotEmpty ? u.name : 'Sans nom',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(width: 8),
                      _buildRoleBadge(u.role),
                      if (u.isBlocked) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Bloqué',
                            style: TextStyle(color: Color(0xFFDC2626), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${u.email} • ${u.phone.isNotEmpty ? u.phone : "Pas de tel"}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  if (u.role == UserRole.vendeur && u.shopName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Boutique: ${u.shopName} (${u.city})',
                        style: const TextStyle(fontSize: 12, color: Colors.deepOrange, fontWeight: FontWeight.w500),
                      ),
                    ),
                  if (u.role == UserRole.livreur && u.vehicleType.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Véhicule: ${u.vehicleType} • Plaque: ${u.plateNumber}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
            ),
            // Actions utilisateur
            Row(
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    foregroundColor: const Color(0xFF334155),
                  ),
                  onPressed: () => _showChangeUserRoleDialog(u),
                  child: const Text('Changer Rôle'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    u.isBlocked ? Icons.lock_open : Icons.block,
                    color: u.isBlocked ? const Color(0xFF10B981) : const Color(0xFFDC2626),
                    size: 20,
                  ),
                  tooltip: u.isBlocked ? 'Débloquer l\'utilisateur' : 'Bloquer l\'utilisateur',
                  onPressed: () => _controller.toggleUserBlocked(u.uid, !u.isBlocked),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                  tooltip: 'Supprimer',
                  onPressed: () => _confirmDeleteUser(u),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 3 : CATALOGUE & PRODUITS (CATALOG)
  // =========================================================================
  Widget _buildCatalogTab() {
    final filtered = _controller.filteredProducts;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _productSearchCtrl,
                      onChanged: _controller.setProductSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Rechercher un produit, ingrédient, boutique...',
                        prefixIcon: const Icon(Icons.search, color: Colors.deepOrange),
                        suffixIcon: _productSearchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _productSearchCtrl.clear();
                                  _controller.setProductSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Nouveau Produit'),
                    onPressed: _showAddProductDialog,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _productCategories.map((cat) {
                    final isSelected = _controller.selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: const Color(0xFFFFF7ED),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.deepOrange : const Color(0xFF475569),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? Colors.deepOrange : const Color(0xFFE2E8F0),
                        ),
                        checkmarkColor: Colors.deepOrange,
                        onSelected: (_) => _controller.setProductCategory(cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('Aucun produit dans le catalogue.'),
                      const SizedBox(height: 10),
                      FilledButton.tonal(
                        onPressed: _showAddProductDialog,
                        child: const Text('Ajouter un produit maintenant'),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth >= 1100 ? 3 : (constraints.maxWidth >= 700 ? 2 : 1);
                    return GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return _buildProductCard(product);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: const Icon(Icons.fastfood, color: Colors.deepOrange, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.shopName,
                        style: const TextStyle(fontSize: 12, color: Colors.deepOrange, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.category,
                          style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${product.price.toStringAsFixed(1)} DT',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            Text(
              product.description,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFF59E0B), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${product.rating}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      '${product.deliveryTimeMinutes} min',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0284C7)),
                      tooltip: 'Modifier',
                      onPressed: () => _showEditProductDialog(product),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                      tooltip: 'Supprimer',
                      onPressed: () => _confirmDeleteProduct(product),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 4 : BOUTIQUES & VENDEURS
  // =========================================================================
  Widget _buildVendorsTab() {
    final vendors = _controller.vendors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Boutiques Partenaires (${vendors.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              Text(
                'Catalogue global : ${_controller.products.length} articles',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (vendors.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.storefront_outlined, size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('Aucune boutique partenaire inscrite.'),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vendors.length,
              itemBuilder: (context, index) {
                final v = vendors[index];
                final shopProducts = _controller.products.where((p) =>
                    p.shopName.trim().toLowerCase() == v.shopName.trim().toLowerCase() ||
                    p.vendorId == v.uid).length;
                final shopOrders = _controller.orders.where((o) =>
                    o.vendorName.trim().toLowerCase() == v.shopName.trim().toLowerCase()).length;

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFEDD5)),
                          ),
                          child: const Icon(Icons.storefront, color: Colors.deepOrange, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.shopName.isNotEmpty ? v.shopName : 'Boutique sans nom',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Gérant: ${v.name} • Contact: ${v.phone} • Email: ${v.email}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Adresse: ${v.profile['address'] ?? "Non spécifiée"} (${v.city})',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                              ),
                              if (v.profile['taxId'] != null)
                                Text(
                                  'Matricule fiscal: ${v.profile['taxId']}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$shopProducts produit(s)',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$shopOrders commande(s)',
                              style: const TextStyle(fontSize: 12, color: Colors.deepOrange, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 5 : FLOTTE DE LIVREURS (COURIERS)
  // =========================================================================
  Widget _buildCouriersTab() {
    final couriers = _controller.couriers;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Flotte de Livreurs (${couriers.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              Text(
                'Livreurs actifs sur le terrain',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (couriers.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.two_wheeler_outlined, size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('Aucun livreur inscrit.'),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: couriers.length,
              itemBuilder: (context, index) {
                final c = couriers[index];
                final courierDeliveries = _controller.orders.where((o) =>
                    o.courierId == c.uid && o.status == OrderStatus.delivered).length;
                final activeOrders = _controller.orders.where((o) =>
                    o.courierId == c.uid && (o.status == OrderStatus.assigned || o.status == OrderStatus.delivering)).length;

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFFE0F2FE),
                          child: const Icon(Icons.two_wheeler, color: Color(0xFF0284C7), size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    c.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: activeOrders > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      activeOrders > 0 ? 'En course ($activeOrders)' : 'Disponible',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: activeOrders > 0 ? const Color(0xFFB45309) : const Color(0xFF15803D),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Téléphone: ${c.phone} • Email: ${c.email}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Véhicule: ${c.vehicleType.isNotEmpty ? c.vehicleType : "Non spécifié"} • Immatriculation: ${c.plateNumber.isNotEmpty ? c.plateNumber : "N/A"}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$courierDeliveries courses livrées',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                                foregroundColor: Colors.deepOrange,
                              ),
                              icon: const Icon(Icons.assignment_ind_outlined, size: 16),
                              label: const Text('Assigner'),
                              onPressed: () => _controller.setTab(1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 6 : PARAMÈTRES & OUTILS (SETTINGS & MAINTENANCE)
  // =========================================================================
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuration de la Plateforme & Maintenance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 18),

          // État du Système
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.cloud_done, color: Color(0xFF10B981)),
                    SizedBox(width: 10),
                    Text(
                      'Statut de connexion Firebase',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Firestore et Firebase Auth sont synchronisés en temps réel. Toutes les modifications apportées par les clients, vendeurs et livreurs sont répercutées instantanément.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const Divider(height: 24, color: Color(0xFFE2E8F0)),
                Row(
                  children: [
                    const Text('Taux de commission plateforme par défaut :', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('10%', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Générateur de Données Démo
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_fix_high, color: Colors.deepOrange),
                    SizedBox(width: 10),
                    Text(
                      'Outil d\'Injection de Données Démo',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Crée automatiquement des utilisateurs types (clients, livreurs avec véhicules, vendeurs avec boutiques), des produits savoureux et des commandes d\'exemple avec différents statuts pour tester l\'ensemble de l\'écosystème.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                  ),
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Injecter les Données Démo'),
                  onPressed: _confirmSeedDemoData,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Informations Profil Super-Admin
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield, color: Colors.deepOrange),
                    SizedBox(width: 10),
                    Text(
                      'Profil Administrateur Actuel',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('Nom: ${widget.user.name}'),
                const SizedBox(height: 4),
                Text('Email: ${widget.user.email}'),
                const SizedBox(height: 4),
                Text('Téléphone: ${widget.user.phone}'),
                const SizedBox(height: 4),
                Text('UID Firestore: ${widget.user.uid}'),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                  ),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Se déconnecter'),
                  onPressed: _showLogoutDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // DIALOGS & ACTIONS
  // =========================================================================

  void _showOrderDetailsDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Commande #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}'),
            _buildStatusBadge(order.status),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Client', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                Text('${order.clientName} (${order.clientPhone})'),
                Text('Adresse: ${order.deliveryAddress}'),
                const Divider(height: 20),
                const Text('Boutique & Livreur', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                Text('Vendeur: ${order.vendorName.isNotEmpty ? order.vendorName : "Partenaire"}'),
                Text('Livreur: ${order.courierName ?? "Non assigné"} ${order.courierPhone != null ? "(${order.courierPhone})" : ""}'),
                const Divider(height: 20),
                const Text('Articles Commandés', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                const SizedBox(height: 8),
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item.quantity}x ${item.name}'),
                          Text('${(item.price * item.quantity).toStringAsFixed(1)} DT'),
                        ],
                      ),
                    )),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sous-total :'),
                    Text('${order.subtotal.toStringAsFixed(1)} DT'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Frais de livraison :'),
                    Text('${order.deliveryFee.toStringAsFixed(1)} DT'),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${order.total.toStringAsFixed(1)} DT',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrange)),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
        ],
      ),
    );
  }

  void _showChangeOrderStatusDialog(OrderModel order) {
    OrderStatus selected = order.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Modifier le Statut'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: OrderStatus.values.map((st) {
              return RadioListTile<OrderStatus>(
                title: Text(st.label),
                value: st,
                groupValue: selected,
                activeColor: Colors.deepOrange,
                onChanged: (val) {
                  if (val != null) setStateModal(() => selected = val);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
              onPressed: () async {
                Navigator.pop(ctx);
                await _controller.updateOrderStatus(order.id, selected);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignCourierDialog(OrderModel order) {
    final couriers = _controller.couriers;

    if (couriers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun livreur enregistré dans la base.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Assigner un Livreur'),
        content: SizedBox(
          width: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: couriers.length,
            itemBuilder: (context, index) {
              final c = couriers[index];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFF7ED),
                  child: Icon(Icons.two_wheeler, color: Colors.deepOrange),
                ),
                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${c.phone} • ${c.vehicleType}'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _controller.assignCourier(
                    orderId: order.id,
                    courierId: c.uid,
                    courierName: c.name,
                    courierPhone: c.phone,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Livreur ${c.name} assigné à la commande.')),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ],
      ),
    );
  }

  void _showChangeUserRoleDialog(AppUser u) {
    UserRole selected = u.role;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Modifier le rôle de ${u.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: UserRole.values.map((r) {
              return RadioListTile<UserRole>(
                title: Text(r.name.toUpperCase()),
                value: r,
                groupValue: selected,
                activeColor: Colors.deepOrange,
                onChanged: (val) {
                  if (val != null) setStateModal(() => selected = val);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
              onPressed: () async {
                Navigator.pop(ctx);
                await _controller.updateUserRole(u.uid, selected);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Rôle mis à jour : ${selected.name}')),
                  );
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final shopCtrl = TextEditingController(text: 'Boutique Partenaire');
    String selectedCat = 'Plats';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Ajouter un Produit au Catalogue'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nom du Produit', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description / Ingrédients', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Prix (DT)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: shopCtrl,
                    decoration: const InputDecoration(labelText: 'Nom de la Boutique', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCat,
                    decoration: const InputDecoration(labelText: 'Catégorie', border: OutlineInputBorder()),
                    items: _productCategories
                        .where((c) => c != 'Tous')
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setStateModal(() => selectedCat = v);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
              onPressed: () async {
                final price = double.tryParse(priceCtrl.text) ?? 0.0;
                if (nameCtrl.text.isEmpty || price <= 0) {
                  return;
                }
                Navigator.pop(ctx);
                final newProduct = Product(
                  id: '',
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  price: price,
                  category: selectedCat,
                  shopName: shopCtrl.text.trim().isNotEmpty ? shopCtrl.text.trim() : 'Boutique Partenaire',
                  rating: 5.0,
                  deliveryTimeMinutes: 25,
                );
                await _controller.addProduct(newProduct);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Produit ajouté avec succès !')),
                  );
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProductDialog(Product product) {
    final nameCtrl = TextEditingController(text: product.name);
    final descCtrl = TextEditingController(text: product.description);
    final priceCtrl = TextEditingController(text: product.price.toString());
    final shopCtrl = TextEditingController(text: product.shopName);
    String selectedCat = _productCategories.contains(product.category) ? product.category : 'Plats';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Modifier le Produit'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nom du Produit', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Prix (DT)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: shopCtrl,
                    decoration: const InputDecoration(labelText: 'Nom de la Boutique', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCat,
                    decoration: const InputDecoration(labelText: 'Catégorie', border: OutlineInputBorder()),
                    items: _productCategories
                        .where((c) => c != 'Tous')
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setStateModal(() => selectedCat = v);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
              onPressed: () async {
                final price = double.tryParse(priceCtrl.text) ?? product.price;
                Navigator.pop(ctx);
                final updated = product.copyWith(
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  price: price,
                  category: selectedCat,
                  shopName: shopCtrl.text.trim(),
                );
                await _controller.updateProduct(updated);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Produit mis à jour.')),
                  );
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteOrder(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer la Commande'),
        content: Text('Voulez-vous supprimer définitivement la commande #${order.id.length > 8 ? order.id.substring(0, 8) : order.id} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () async {
              Navigator.pop(ctx);
              await _controller.deleteOrder(order.id);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(AppUser u) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer l\'Utilisateur'),
        content: Text('Voulez-vous supprimer le profil de ${u.name} (${u.email}) ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () async {
              Navigator.pop(ctx);
              await _controller.deleteUser(u.uid);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProduct(Product p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer le Produit'),
        content: Text('Supprimer "${p.name}" du catalogue ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () async {
              Navigator.pop(ctx);
              await _controller.deleteProduct(p.id);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _confirmSeedDemoData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Injecter les Données Démo'),
        content: const Text(
          'Cette action va injecter des produits de référence, des commandes d\'exemple et des profils livreur/vendeur dans Firestore pour tester l\'application en conditions réelles.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
            onPressed: () async {
              Navigator.pop(ctx);
              await _controller.seedPlatformDemoData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Données de démonstration injectées avec succès !')),
                );
              }
            },
            child: const Text('Confirmer l\'injection'),
          ),
        ],
      ),
    );
  }

  // --- HELPERS BADGES ET COULEURS ---
  Widget _buildStatusBadge(OrderStatus status) {
    Color bg;
    Color text;

    switch (status) {
      case OrderStatus.pending:
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFB45309);
        break;
      case OrderStatus.preparing:
        bg = const Color(0xFFFFEDD5);
        text = const Color(0xFFC2410C);
        break;
      case OrderStatus.ready:
        bg = const Color(0xFFEDE9FE);
        text = const Color(0xFF6D28D9);
        break;
      case OrderStatus.assigned:
      case OrderStatus.delivering:
      case OrderStatus.pickedUp:
        bg = const Color(0xFFE0F2FE);
        text = const Color(0xFF0369A1);
        break;
      case OrderStatus.delivered:
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF15803D);
        break;
      case OrderStatus.cancelled:
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFFB91C1C);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    Color bg;
    Color text;

    switch (role) {
      case UserRole.admin:
        bg = const Color(0xFFFFEDD5);
        text = const Color(0xFFEA580C);
        break;
      case UserRole.vendeur:
        bg = const Color(0xFFF3E8FF);
        text = const Color(0xFF7E22CE);
        break;
      case UserRole.livreur:
        bg = const Color(0xFFE0F2FE);
        text = const Color(0xFF0284C7);
        break;
      case UserRole.client:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF334155);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.name.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.deepOrange;
      case UserRole.vendeur:
        return const Color(0xFF7E22CE);
      case UserRole.livreur:
        return const Color(0xFF0284C7);
      case UserRole.client:
        return const Color(0xFF475569);
    }
  }
}
