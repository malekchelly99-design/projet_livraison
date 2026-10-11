import 'package:flutter/material.dart';

import '../../controllers/vendeur_dashboard_controller.dart';
import '../../models/app_user.dart';
import '../../models/order_model.dart';
import '../../models/product.dart';

class VendeurDashboardView extends StatefulWidget {
  final AppUser user;
  final VoidCallback onLogout;

  const VendeurDashboardView({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<VendeurDashboardView> createState() => _VendeurDashboardViewState();
}

class _VendeurDashboardViewState extends State<VendeurDashboardView> {
  late final VendeurDashboardController _controller;
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> _categories = const [
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
    _controller = VendeurDashboardController(user: widget.user);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter de votre espace vendeur ?'),
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 820;

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
                          Expanded(child: _buildCurrentView()),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: AppBar(
                title: Text(_getPageTitle()),
                backgroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 2,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Déconnexion',
                    onPressed: _showLogoutDialog,
                  ),
                ],
              ),
              body: _buildCurrentView(),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _controller.currentTab,
                onDestinationSelected: _controller.setTab,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: 'Tableau de bord',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.inventory_2_outlined),
                    selectedIcon: Icon(Icons.inventory_2),
                    label: 'Produits',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long),
                    label: 'Commandes',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.storefront_outlined),
                    selectedIcon: Icon(Icons.storefront),
                    label: 'Boutique',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getPageTitle() {
    switch (_controller.currentTab) {
      case 0:
        return 'Tableau de bord Vendeur';
      case 1:
        return 'Gestion des Produits';
      case 2:
        return 'Commandes Reçues';
      case 3:
        return 'Paramètres de la Boutique';
      default:
        return 'Espace Vendeur';
    }
  }

  Widget _buildTopHeader() {
    return Container(
      height: 68,
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
                _getPageTitle(),
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
                  color: _controller.isOpen ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _controller.isOpen ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _controller.isOpen ? 'Boutique Ouverte' : 'Boutique Fermée',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _controller.isOpen ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  _controller.shopName.isNotEmpty ? _controller.shopName[0].toUpperCase() : 'V',
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
                    _controller.shopName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    _controller.user.name.isNotEmpty ? _controller.user.name : 'Gérant',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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

  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.storefront, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _controller.shopName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Text(
                        'Espace Vendeur Pro',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),
          _buildSidebarItem(
            index: 0,
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            title: 'Tableau de bord',
          ),
          _buildSidebarItem(
            index: 1,
            icon: Icons.inventory_2_outlined,
            selectedIcon: Icons.inventory_2,
            title: 'Mes Produits',
            badge: '${_controller.products.length}',
          ),
          _buildSidebarItem(
            index: 2,
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long,
            title: 'Commandes',
            badge: _controller.pendingOrdersCount > 0 ? '${_controller.pendingOrdersCount}' : null,
            badgeColor: Colors.orange,
          ),
          _buildSidebarItem(
            index: 3,
            icon: Icons.storefront_outlined,
            selectedIcon: Icons.storefront,
            title: 'Ma Boutique',
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 0,
              color: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      _controller.isOpen ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                      color: _controller.isOpen ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _controller.isOpen ? 'Réception active' : 'Commandes en pause',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Switch(
                      value: _controller.isOpen,
                      onChanged: _controller.toggleShopOpen,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String title,
    String? badge,
    Color? badgeColor,
  }) {
    final isSelected = _controller.currentTab == index;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selected: isSelected,
        selectedTileColor: primary.withAlpha(25),
        leading: Icon(
          isSelected ? selectedIcon : icon,
          color: isSelected ? primary : const Color(0xFF64748B),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? primary : const Color(0xFF334155),
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (badgeColor ?? primary).withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor ?? primary,
                  ),
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
        return _buildOverviewTab();
      case 1:
        return _buildProductsTab();
      case 2:
        return _buildOrdersTab();
      case 3:
        return _buildShopSettingsTab();
      default:
        return _buildOverviewTab();
    }
  }

  // ==========================================
  // ONGLET 0 : TABLEAU DE BORD (OVERVIEW)
  // ==========================================
  Widget _buildOverviewTab() {
    final primary = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bannière de bienvenue dynamique
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primary,
                  const Color(0xFFC2410C),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxGradientShadow(
                  color: primary.withAlpha(70),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(40),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '🏪 ${_controller.shopCategory}',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_controller.shopCity.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(40),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '📍 ${_controller.shopCity}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Bienvenue, ${_controller.shopName} 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Gérez vos commandes en temps réel, ajoutez de nouveaux articles et maximisez vos ventes.',
                        style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.point_of_sale, color: Colors.white, size: 48),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cartes KPI
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: isWide ? 1.5 : 1.3,
                children: [
                  _buildStatCard(
                    title: 'Chiffre d\'Affaires',
                    value: '${_controller.totalRevenue.toStringAsFixed(2)} DT',
                    icon: Icons.payments_outlined,
                    color: const Color(0xFF10B981),
                    subtitle: 'Commandes livrées',
                  ),
                  _buildStatCard(
                    title: 'À Préparer',
                    value: '${_controller.pendingOrdersCount}',
                    icon: Icons.kitchen_outlined,
                    color: const Color(0xFFF59E0B),
                    subtitle: 'En attente & préparation',
                  ),
                  _buildStatCard(
                    title: 'En Livraison',
                    value: '${_controller.deliveringOrdersCount}',
                    icon: Icons.delivery_dining,
                    color: const Color(0xFF6366F1),
                    subtitle: 'Vers les clients',
                  ),
                  _buildStatCard(
                    title: 'Mes Produits',
                    value: '${_controller.products.length}',
                    icon: Icons.inventory_2_outlined,
                    color: const Color(0xFF0EA5E9),
                    subtitle: 'Articles actifs',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Actions rapides
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Actions Rapides',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouveau Produit'),
                onPressed: () => _showProductDialog(),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildActionTile(
                  title: 'Ajouter un Produit',
                  description: 'Créer un nouvel article dans votre boutique',
                  icon: Icons.add_circle_outline,
                  color: Colors.blue,
                  onTap: () => _showProductDialog(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildActionTile(
                  title: 'Voir les Commandes',
                  description: '${_controller.orders.length} commande(s) enregistrée(s)',
                  icon: Icons.receipt_long,
                  color: Colors.orange,
                  onTap: () => _controller.setTab(2),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildActionTile(
                  title: 'Modifier ma Boutique',
                  description: 'Horaires, adresse et informations légales',
                  icon: Icons.storefront,
                  color: Colors.teal,
                  onTap: () => _controller.setTab(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Commandes urgentes à traiter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Commandes Récentes & Urgentes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              TextButton(
                onPressed: () => _controller.setTab(2),
                child: const Text('Voir tout'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_controller.orders.isEmpty)
            _buildEmptyCard(
              icon: Icons.receipt_long_outlined,
              title: 'Aucune commande pour le moment',
              subtitle: 'Les nouvelles commandes passées par vos clients apparaîtront ici en temps réel.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _controller.orders.take(5).length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final order = _controller.orders[index];
                return _buildOrderCompactCard(order);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCompactCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getStatusColor(order.status).withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getStatusIcon(order.status),
              color: _getStatusColor(order.status),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Commande #${order.id.isEmpty ? "Récents" : (order.id.length > 6 ? order.id.substring(0, 6).toUpperCase() : order.id)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(order.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.clientName} • ${order.items.length} article(s) • ${order.deliveryAddress}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Text(
            '${order.total.toStringAsFixed(2)} DT',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
            onSelected: (action) {
              if (action == 'detail') {
                _showOrderDetailDialog(order);
              } else if (action == 'prep') {
                _controller.updateOrderStatus(order.id, OrderStatus.preparing);
              } else if (action == 'deliv') {
                _controller.updateOrderStatus(order.id, OrderStatus.delivering);
              } else if (action == 'done') {
                _controller.updateOrderStatus(order.id, OrderStatus.delivered);
              } else if (action == 'cancel') {
                _controller.updateOrderStatus(order.id, OrderStatus.cancelled);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'detail', child: Text('Voir les détails')),
              if (order.status == OrderStatus.pending)
                const PopupMenuItem(value: 'prep', child: Text('Passer en préparation')),
              if (order.status == OrderStatus.preparing)
                const PopupMenuItem(value: 'deliv', child: Text('Prêt / En livraison')),
              if (order.status == OrderStatus.delivering)
                const PopupMenuItem(value: 'done', child: Text('Marquer Livrée')),
              if (order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled)
                const PopupMenuItem(value: 'cancel', child: Text('Annuler')),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ONGLET 1 : GESTION DES PRODUITS (CATALOGUE)
  // ==========================================
  Widget _buildProductsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mes Produits & Menus',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    '${_controller.products.length} produit(s) enregistré(s) dans votre boutique',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un Produit'),
                onPressed: () => _showProductDialog(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Barre de recherche et catégories
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _controller.setProductSearch,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un produit...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Colors.white,
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
          const SizedBox(height: 14),

          // Chips de catégories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _controller.selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => _controller.setCategory(cat),
                    backgroundColor: Colors.white,
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Grille des produits
          if (_controller.filteredProducts.isEmpty)
            _buildEmptyCard(
              icon: Icons.inventory_2_outlined,
              title: 'Aucun produit trouvé',
              subtitle: 'Ajoutez votre premier article au menu pour commencer à recevoir des commandes !',
              action: FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Créer mon premier produit'),
                onPressed: () => _showProductDialog(),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 900;
                final isTablet = constraints.maxWidth >= 600;
                final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 290,
                  ),
                  itemCount: _controller.filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _controller.filteredProducts[index];
                    return _buildProductCard(product);
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 130,
                  width: double.infinity,
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                        )
                      : _buildImagePlaceholder(),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(160),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product.category,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (product.isPopular)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Populaire',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Détails
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
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                    ),
                    Text(
                      '${product.price.toStringAsFixed(2)} DT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  product.description.isNotEmpty ? product.description : 'Aucune description fournie.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),

                // Ligne inférieure
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(
                          '${product.deliveryTimeMinutes} min',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
                          tooltip: 'Modifier',
                          onPressed: () => _showProductDialog(product: product),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
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
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: const Center(
        child: Icon(Icons.fastfood_outlined, size: 40, color: Color(0xFF94A3B8)),
      ),
    );
  }

  // ==========================================
  // ONGLET 2 : GESTION DES COMMANDES (ORDERS)
  // ==========================================
  Widget _buildOrdersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Commandes de la Boutique',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    '${_controller.orders.length} commande(s) totale(s)',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filtres par statut
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildOrderStatusChip(label: 'Toutes', status: null),
                _buildOrderStatusChip(label: 'En attente', status: OrderStatus.pending),
                _buildOrderStatusChip(label: 'En préparation', status: OrderStatus.preparing),
                _buildOrderStatusChip(label: 'En livraison', status: OrderStatus.delivering),
                _buildOrderStatusChip(label: 'Livrées', status: OrderStatus.delivered),
                _buildOrderStatusChip(label: 'Annulées', status: OrderStatus.cancelled),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Liste des commandes filtrées
          if (_controller.filteredOrders.isEmpty)
            _buildEmptyCard(
              icon: Icons.receipt_long_outlined,
              title: 'Aucune commande dans cette catégorie',
              subtitle: 'Les commandes s\'actualisent automatiquement en temps réel.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _controller.filteredOrders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final order = _controller.filteredOrders[index];
                return _buildOrderDetailCard(order);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusChip({required String label, required OrderStatus? status}) {
    final isSelected = _controller.selectedOrderStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _controller.setOrderStatusFilter(status),
        backgroundColor: Colors.white,
        selectedColor: Theme.of(context).colorScheme.primaryContainer,
      ),
    );
  }

  Widget _buildOrderDetailCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête commande
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getStatusIcon(order.status),
                      color: _getStatusColor(order.status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Commande #${order.id.isEmpty ? "Récents" : (order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Passée le ${_formatDate(order.createdAt)}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              _buildStatusBadge(order.status),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),

          // Infos client et livraison
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Client', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      order.clientName.isNotEmpty ? order.clientName : 'Client anonyme',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (order.clientPhone.isNotEmpty)
                      Text(
                        '📞 ${order.clientPhone}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Adresse de livraison', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      order.deliveryAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Articles commandés
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Articles :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
                const SizedBox(height: 6),
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('• ${item.name} x${item.quantity}', style: const TextStyle(fontSize: 13)),
                          Text('${(item.price * item.quantity).toStringAsFixed(2)} DT', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Total & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Commande', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  Text(
                    '${order.total.toStringAsFixed(2)} DT',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  if (order.status == OrderStatus.pending) ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () => _controller.updateOrderStatus(order.id, OrderStatus.cancelled),
                      child: const Text('Refuser'),
                    ),
                    FilledButton.icon(
                      icon: const Icon(Icons.soup_kitchen, size: 18),
                      label: const Text('Accepter & Préparer'),
                      onPressed: () => _controller.updateOrderStatus(order.id, OrderStatus.preparing),
                    ),
                  ] else if (order.status == OrderStatus.preparing) ...[
                    FilledButton.icon(
                      icon: const Icon(Icons.two_wheeler, size: 18),
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                      label: const Text('Prêt / Remis au livreur'),
                      onPressed: () => _controller.updateOrderStatus(order.id, OrderStatus.delivering),
                    ),
                  ] else if (order.status == OrderStatus.delivering) ...[
                    FilledButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                      label: const Text('Marquer Livrée'),
                      onPressed: () => _controller.updateOrderStatus(order.id, OrderStatus.delivered),
                    ),
                  ] else ...[
                    OutlinedButton(
                      onPressed: () => _showOrderDetailDialog(order),
                      child: const Text('Détails complets'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ONGLET 3 : PARAMÈTRES BOUTIQUE (SETTINGS)
  // ==========================================
  Widget _buildShopSettingsTab() {
    final shopNameCtrl = TextEditingController(text: _controller.shopName);
    final categoryCtrl = TextEditingController(text: _controller.shopCategory);
    final addressCtrl = TextEditingController(text: _controller.shopAddress);
    final cityCtrl = TextEditingController(text: _controller.shopCity);
    final taxIdCtrl = TextEditingController(text: _controller.shopTaxId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations de ma Boutique',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const Text(
            'Personnalisez les coordonnées et l\'activité visibles par vos clients et livreurs.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(24),
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
                    const Text('Statut actuel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Row(
                      children: [
                        Text(_controller.isOpen ? 'Boutique Ouverte' : 'Boutique Fermée'),
                        const SizedBox(width: 8),
                        Switch(
                          value: _controller.isOpen,
                          onChanged: _controller.toggleShopOpen,
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 28, color: Color(0xFFE2E8F0)),

                TextFormField(
                  controller: shopNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la Boutique / Enseigne',
                    prefixIcon: Icon(Icons.store),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie d\'activité (Restaurant, Épicerie, etc.)',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: addressCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Adresse physique',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: cityCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Ville',
                          prefixIcon: Icon(Icons.location_city),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: taxIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Matricule Fiscal / Registre de Commerce',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Enregistrer les modifications'),
                    onPressed: () async {
                      final success = await _controller.updateShopProfile(
                        newShopName: shopNameCtrl.text.trim(),
                        newCategory: categoryCtrl.text.trim(),
                        newAddress: addressCtrl.text.trim(),
                        newCity: cityCtrl.text.trim(),
                        newTaxId: taxIdCtrl.text.trim(),
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'Informations de la boutique mises à jour avec succès !'
                              : 'Échec de l\'enregistrement.'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Coordonnées du contact
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
                const Text('Compte Propriétaire & Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(widget.user.name.isNotEmpty ? widget.user.name : 'Vendeur Partenaire'),
                  subtitle: Text('${widget.user.email} • ${widget.user.phone}'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DIALOGUES ET MODALES
  // ==========================================
  void _showProductDialog({Product? product}) {
    final isEditing = product != null;
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final descCtrl = TextEditingController(text: product?.description ?? '');
    final priceCtrl = TextEditingController(text: product != null ? product.price.toString() : '');
    final timeCtrl = TextEditingController(text: product != null ? product.deliveryTimeMinutes.toString() : '20');
    final imageCtrl = TextEditingController(text: product?.imageUrl ?? '');
    String selectedCategory = product?.category ?? 'Plats';
    bool isPopular = product?.isPopular ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEditing ? 'Modifier le Produit' : 'Ajouter un Nouveau Produit'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nom du Produit *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Prix (DT) *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: timeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Préparation (min)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _categories.contains(selectedCategory) && selectedCategory != 'Tous'
                        ? selectedCategory
                        : 'Plats',
                    decoration: const InputDecoration(
                      labelText: 'Catégorie *',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories
                        .where((c) => c != 'Tous')
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: imageCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL de l\'image (optionnel)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Mettre en avant (Populaire)'),
                    value: isPopular,
                    onChanged: (val) => setDialogState(() => isPopular = val),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                final time = int.tryParse(timeCtrl.text.trim()) ?? 20;

                if (name.isEmpty || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez renseigner un nom et un prix valide.')),
                  );
                  return;
                }

                Navigator.pop(ctx);

                if (isEditing) {
                  await _controller.updateProduct(
                    id: product.id,
                    name: name,
                    description: descCtrl.text.trim(),
                    price: price,
                    category: selectedCategory,
                    deliveryTimeMinutes: time,
                    isPopular: isPopular,
                    imageUrl: imageCtrl.text.trim(),
                  );
                } else {
                  await _controller.addProduct(
                    name: name,
                    description: descCtrl.text.trim(),
                    price: price,
                    category: selectedCategory,
                    deliveryTimeMinutes: time,
                    isPopular: isPopular,
                    imageUrl: imageCtrl.text.trim(),
                  );
                }
              },
              child: Text(isEditing ? 'Sauvegarder' : 'Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce produit ?'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${product.name}" de votre catalogue ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _controller.deleteProduct(product.id);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showOrderDetailDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Commande #${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id}'),
            _buildStatusBadge(order.status),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Client : ${order.clientName}'),
                Text('Téléphone : ${order.clientPhone}'),
                Text('Adresse : ${order.deliveryAddress}'),
                if (order.notes != null && order.notes!.isNotEmpty) Text('Notes : ${order.notes}'),
                const Divider(height: 20),
                const Text('Articles :', style: TextStyle(fontWeight: FontWeight.bold)),
                ...order.items.map((i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${i.name} x${i.quantity}'),
                          Text('${(i.price * i.quantity).toStringAsFixed(2)} DT'),
                        ],
                      ),
                    )),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${order.total.toStringAsFixed(2)} DT',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildStatusBadge(OrderStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFF59E0B);
      case OrderStatus.preparing:
        return const Color(0xFF3B82F6);
      case OrderStatus.delivering:
        return const Color(0xFF8B5CF6);
      case OrderStatus.delivered:
        return const Color(0xFF10B981);
      case OrderStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.hourglass_empty;
      case OrderStatus.preparing:
        return Icons.soup_kitchen;
      case OrderStatus.delivering:
        return Icons.delivery_dining;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action,
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class BoxGradientShadow extends BoxShadow {
  const BoxGradientShadow({
    super.color,
    super.offset,
    super.blurRadius,
    super.spreadRadius,
  });
}
