import 'package:flutter/material.dart';

import '../../controllers/livreur_dashboard_controller.dart';
import '../../models/app_user.dart';
import '../../models/order_model.dart';

class LivreurDashboardView extends StatefulWidget {
  final AppUser user;
  final VoidCallback onLogout;

  const LivreurDashboardView({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<LivreurDashboardView> createState() => _LivreurDashboardViewState();
}

class _LivreurDashboardViewState extends State<LivreurDashboardView> {
  late final LivreurDashboardController _controller;

  // Profil text editing controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _vehicleCtrl;
  late final TextEditingController _plateCtrl;
  late final TextEditingController _cityCtrl;

  String _searchFilter = '';

  @override
  void initState() {
    super.initState();
    _controller = LivreurDashboardController();
    _controller.initAvailability(widget.user.uid);

    final prof = widget.user.profile;
    _nameCtrl = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
    _vehicleCtrl = TextEditingController(
      text: prof['vehicleType']?.toString() ?? 'Moto / Scooter',
    );
    _plateCtrl = TextEditingController(
      text: prof['plateNumber']?.toString() ?? '123-TN-4567',
    );
    _cityCtrl = TextEditingController(
      text: prof['city']?.toString() ?? 'Grand Tunis',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _vehicleCtrl.dispose();
    _plateCtrl.dispose();
    _cityCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text(
          'Voulez-vous vraiment vous déconnecter de l\'espace livreur ?',
        ),
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

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.deepOrange.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 768;

            if (isDesktop) {
              return Scaffold(
                backgroundColor: const Color(0xFFF8FAFC),
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

            // Mobile layout
            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: AppBar(
                title: Text(_getPageTitle()),
                backgroundColor: Colors.white,
                elevation: 0.5,
                actions: [
                  _buildAvailabilityBadge(),
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
                onDestinationSelected: (idx) => _controller.setTab(idx),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.moped_outlined),
                    selectedIcon: Icon(Icons.moped),
                    label: 'Disponibles',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.navigation_outlined),
                    selectedIcon: Icon(Icons.navigation),
                    label: 'En cours',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.history_outlined),
                    selectedIcon: Icon(Icons.history),
                    label: 'Historique',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: 'Profil',
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
        return 'Tableau de bord Livreur';
      case 1:
        return 'Courses disponibles';
      case 2:
        return 'Course en cours & GPS';
      case 3:
        return 'Historique & Gains';
      case 4:
        return 'Profil & Véhicule';
      default:
        return 'Espace Livreur';
    }
  }

  Widget _buildAvailabilityBadge() {
    final isAvail = _controller.isAvailable;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: isAvail ? 'Vous êtes en service' : 'Vous êtes en pause',
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _controller.toggleAvailability(widget.user.uid),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isAvail ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isAvail ? Colors.green.shade400 : Colors.grey.shade400,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isAvail ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isAvail ? 'En service' : 'En pause',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isAvail
                        ? Colors.green.shade800
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                _getPageTitle(),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              _buildAvailabilityBadge(),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber.shade700, size: 16),
                    const SizedBox(width: 4),
                    const Text(
                      '4.9/5',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              CircleAvatar(
                backgroundColor: Colors.deepOrange.shade700,
                child: Text(
                  widget.user.name.isNotEmpty
                      ? widget.user.name[0].toUpperCase()
                      : 'L',
                  style: const TextStyle(
                    color: Colors.white,
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
                    widget.user.name.isNotEmpty ? widget.user.name : 'Livreur',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Livreur certifié',
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
                    color: Colors.deepOrange.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.two_wheeler,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Livraison Pro',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Espace Livreur',
                      style: TextStyle(
                        color: Colors.deepOrange.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 12),

          _buildSidebarItem(
            index: 0,
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            title: 'Tableau de bord',
          ),
          _buildSidebarItem(
            index: 1,
            icon: Icons.moped_outlined,
            selectedIcon: Icons.moped,
            title: 'Courses disponibles',
          ),
          _buildSidebarItem(
            index: 2,
            icon: Icons.navigation_outlined,
            selectedIcon: Icons.navigation,
            title: 'Course active & GPS',
          ),
          _buildSidebarItem(
            index: 3,
            icon: Icons.history_outlined,
            selectedIcon: Icons.history,
            title: 'Historique & Gains',
          ),
          _buildSidebarItem(
            index: 4,
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            title: 'Profil & Véhicule',
          ),

          const Spacer(),
          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.all(16),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Déconnexion',
                style: TextStyle(color: Colors.red),
              ),
              onTap: _showLogoutDialog,
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
  }) {
    final isSelected = _controller.currentTab == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selected: isSelected,
        selectedTileColor: Colors.deepOrange.shade50,
        leading: Icon(
          isSelected ? selectedIcon : icon,
          color: isSelected ? Colors.deepOrange.shade800 : Colors.grey.shade700,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.deepOrange.shade800 : Colors.black87,
          ),
        ),
        onTap: () => _controller.setTab(index),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_controller.currentTab) {
      case 0:
        return _buildDashboardOverview();
      case 1:
        return _buildAvailableDeliveriesTab();
      case 2:
        return _buildActiveDeliveryTab();
      case 3:
        return _buildHistoryTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildDashboardOverview();
    }
  }

  // ========================================================
  // ONGLET 0 : DASHBOARD OVERVIEW & KPIS
  // ========================================================
  Widget _buildDashboardOverview() {
    return StreamBuilder<List<OrderModel>>(
      stream: _controller.watchMyDeliveries(widget.user.uid),
      builder: (context, myOrdersSnap) {
        final myOrders = myOrdersSnap.data ?? [];
        final activeOrder = myOrders
            .where(
              (o) =>
          o.status == OrderStatus.assigned ||
              o.status == OrderStatus.pickedUp ||
              o.status == OrderStatus.delivering,
        )
            .firstOrNull;

        final completedOrders = myOrders
            .where((o) => o.status == OrderStatus.delivered)
            .toList();
        final totalEarnings = completedOrders.fold(
          0.0,
              (sum, o) => sum + o.deliveryFee,
        );

        return StreamBuilder<List<OrderModel>>(
          stream: _controller.watchAvailableDeliveries(),
          builder: (context, availSnap) {
            final availableCount = availSnap.data?.length ?? 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bannière Bienvenue Livreur
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.deepOrange.shade800, Colors.deepOrange.shade900],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepOrange.withAlpha(40),
                          blurRadius: 16,
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
                              Text(
                                'Bienvenue, ${widget.user.name} 🛵',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _controller.isAvailable
                                    ? 'Vous êtes en service et prêt à recevoir des livraisons.'
                                    : 'Vous êtes actuellement en pause. Activez votre statut pour recevoir des courses.',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _controller.isAvailable
                                      ? Colors.white
                                      : Colors.amber.shade400,
                                  foregroundColor: _controller.isAvailable
                                      ? Colors.deepOrange.shade900
                                      : Colors.black87,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: Icon(
                                  _controller.isAvailable
                                      ? Icons.pause_circle_outline
                                      : Icons.play_circle_fill,
                                ),
                                label: Text(
                                  _controller.isAvailable
                                      ? 'Passer en pause'
                                      : 'Se mettre en service',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () => _controller.toggleAvailability(
                                  widget.user.uid,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.delivery_dining,
                          color: Colors.white,
                          size: 70,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Cartes KPI
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 650;
                      return GridView.count(
                        crossAxisCount: isWide ? 4 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isWide ? 1.4 : 1.3,
                        children: [
                          _buildKpiCard(
                            title: 'Disponibles',
                            value: '$availableCount',
                            subtitle: 'Prêtes à récupérer',
                            icon: Icons.storefront,
                            color: Colors.blue,
                            onTap: () => _controller.setTab(1),
                          ),
                          _buildKpiCard(
                            title: 'En cours',
                            value: activeOrder != null ? '1 active' : '0',
                            subtitle: activeOrder != null
                                ? 'Mission en cours'
                                : 'Aucune mission',
                            icon: Icons.navigation,
                            color: Colors.orange,
                            onTap: () => _controller.setTab(2),
                          ),
                          _buildKpiCard(
                            title: 'Livrées',
                            value: '${completedOrders.length}',
                            subtitle: 'Missions réussies',
                            icon: Icons.check_circle_outline,
                            color: Colors.green,
                            onTap: () => _controller.setTab(3),
                          ),
                          _buildKpiCard(
                            title: 'Mes Gains',
                            value: '${totalEarnings.toStringAsFixed(1)} DT',
                            subtitle: 'Commissions cumulées',
                            icon: Icons.account_balance_wallet_outlined,
                            color: Colors.purple,
                            onTap: () => _controller.setTab(3),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Focus sur la mission active (s'il y en a une)
                  if (activeOrder != null) ...[
                    _buildActiveOrderBanner(activeOrder),
                    const SizedBox(height: 28),
                  ],

                  // Raccourcis et Démo Helper
                  // (Wrap au lieu de Row : évite le débordement sur mobile)
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 4,
                    children: [
                      const Text(
                        'Actions rapides',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add_task),
                        label: const Text(
                          'Générer des commandes de test (Démo)',
                        ),
                        onPressed: () async {
                          final err = await _controller.seedDemoOrders();
                          if (err != null) {
                            _showSnack(err, isError: true);
                          } else {
                            _showSnack(
                              'Commandes de test créées avec succès !',
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.moped, size: 18),
                        label: const Text('Voir les courses disponibles'),
                        onPressed: () => _controller.setTab(1),
                      ),
                      ActionChip(
                        avatar: const Icon(
                          Icons.account_balance_wallet,
                          size: 18,
                        ),
                        label: const Text('Consulter mes gains'),
                        onPressed: () => _controller.setTab(3),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.badge_outlined, size: 18),
                        label: const Text('Mon profil livreur'),
                        onPressed: () => _controller.setTab(4),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
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
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrderBanner(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade300, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.navigation, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade700,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'COURSE ACTIVE • ${order.status.label.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Destination : ${order.deliveryAddress}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Client : ${order.clientName} (${order.clientPhone})',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
            ),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Accéder au suivi GPS'),
            onPressed: () => _controller.setTab(2),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // ONGLET 1 : COURSES DISPONIBLES (SECTION 9 DU PDF)
  // ========================================================
  Widget _buildAvailableDeliveriesTab() {
    return StreamBuilder<List<OrderModel>>(
      stream: _controller.watchAvailableDeliveries(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data ?? [];
        final filtered = orders.where((o) {
          if (_searchFilter.isEmpty) return true;
          final q = _searchFilter.toLowerCase();
          return o.deliveryAddress.toLowerCase().contains(q) ||
              o.vendorName.toLowerCase().contains(q) ||
              o.clientName.toLowerCase().contains(q);
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Alerte si hors ligne
              if (!_controller.isAvailable)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.amber.shade800,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Vous êtes actuellement en pause. Cliquez pour vous mettre en service et accepter des livraisons.',
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            _controller.toggleAvailability(widget.user.uid),
                        child: const Text('Activer'),
                      ),
                    ],
                  ),
                ),

              // Barre de recherche et actions
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText:
                        'Rechercher par adresse, boutique ou client...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                      onChanged: (val) =>
                          setState(() => _searchFilter = val.trim()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter démo'),
                    onPressed: () async {
                      await _controller.seedDemoOrders();
                      _showSnack('Commandes de démonstration ajoutées !');
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                '${filtered.length} livraison(s) disponible(s)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucune livraison disponible pour le moment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Les nouvelles commandes des clients apparaîtront ici dès qu\'elles seront prêtes.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text(
                          'Générer des commandes de test pour tester',
                        ),
                        onPressed: () async {
                          await _controller.seedDemoOrders();
                          _showSnack('Commandes créées !');
                        },
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final order = filtered[index];
                    return _buildAvailableDeliveryCard(order);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvailableDeliveryCard(OrderModel order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header de la carte
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.deepOrange.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.receipt_long,
                      size: 18,
                      color: Colors.deepOrange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Commande #${order.id.length > 6 ? order.id.substring(0, 6).toUpperCase() : order.id.toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+${order.deliveryFee.toStringAsFixed(1)} DT',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Point de départ : Boutique
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.storefront,
                        color: Colors.blue.shade700,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Retrait : ${order.vendorName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            order.vendorAddress,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height: 20,
                      child: VerticalDivider(thickness: 2, color: Colors.grey),
                    ),
                  ),
                ),

                // Point d'arrivée : Client
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: Colors.green.shade700,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Livraison : ${order.clientName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            order.deliveryAddress,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24),

                // Informations complémentaires
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.payment,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          order.paymentMethod,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Total : ${order.total.toStringAsFixed(1)} DT',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Boutons d'action
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Détails'),
                      onPressed: () => _showOrderDetailsDialog(order),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.deepOrange.shade700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Accepter la livraison'),
                      onPressed: () async {
                        final err = await _controller.acceptDelivery(
                          order: order,
                          courier: widget.user,
                        );
                        if (err != null) {
                          _showSnack(err, isError: true);
                        } else {
                          _showSnack('Livraison acceptée ! Mission en cours.');
                        }
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

  // ========================================================
  // ONGLET 2 : COURSE ACTIVE & GÉOLOCALISATION GPS (SECTIONS 9 & 10)
  // ========================================================
  Widget _buildActiveDeliveryTab() {
    return StreamBuilder<List<OrderModel>>(
      stream: _controller.watchMyDeliveries(widget.user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final myOrders = snapshot.data ?? [];
        final activeOrder = myOrders
            .where(
              (o) =>
          o.status == OrderStatus.assigned ||
              o.status == OrderStatus.pickedUp ||
              o.status == OrderStatus.delivering,
        )
            .firstOrNull;

        if (activeOrder == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.directions_bike,
                    size: 72,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune course active en cours',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Consultez les livraisons disponibles pour accepter une nouvelle commande.',
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text('Voir les livraisons disponibles'),
                    onPressed: () => _controller.setTab(1),
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indicateur de statut interactif (Cycle de vie complet du PDF)
              _buildDeliveryLifecycleStepper(activeOrder),

              const SizedBox(height: 24),

              // Simulateur d'itinéraire & Géolocalisation (Section 10 du PDF)
              _buildGpsMapSimulation(activeOrder),

              const SizedBox(height: 24),

              // Carte Mission et Actions
              _buildMissionActionCard(activeOrder),

              const SizedBox(height: 24),

              // Détails des articles à livrer
              _buildOrderItemsCard(activeOrder),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliveryLifecycleStepper(OrderModel order) {
    int getStepIndex() {
      switch (order.status) {
        case OrderStatus.ready:
          return 0;
        case OrderStatus.assigned:
          return 1;
        case OrderStatus.pickedUp:
          return 2;
        case OrderStatus.delivering:
          return 3;
        case OrderStatus.delivered:
          return 4;
        default:
          return 1;
      }
    }

    final currentStep = getStepIndex();
    final steps = [
      {'title': 'Commande prête', 'icon': Icons.inventory},
      {'title': 'Livreur affecté', 'icon': Icons.person_pin},
      {'title': 'Récupérée', 'icon': Icons.store},
      {'title': 'En livraison', 'icon': Icons.moped},
      {'title': 'Livrée', 'icon': Icons.check_circle},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cycle de la livraison (Temps réel)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.deepOrange.shade200),
                ),
                child: Text(
                  order.status.label,
                  style: TextStyle(
                    color: Colors.deepOrange.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: List.generate(steps.length, (idx) {
              final isPassed = idx <= currentStep;
              final isCurrent = idx == currentStep;
              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (idx > 0)
                          Expanded(
                            child: Container(
                              height: 3,
                              color: isPassed
                                  ? Colors.deepOrange
                                  : Colors.grey.shade200,
                            ),
                          ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? Colors.deepOrange.shade700
                                : isPassed
                                ? Colors.deepOrange.shade100
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isPassed
                                  ? Colors.deepOrange
                                  : Colors.grey.shade300,
                              width: isCurrent ? 2 : 1,
                            ),
                          ),
                          child: Icon(
                            steps[idx]['icon'] as IconData,
                            size: 16,
                            color: isCurrent
                                ? Colors.white
                                : isPassed
                                ? Colors.deepOrange.shade800
                                : Colors.grey.shade400,
                          ),
                        ),
                        if (idx < steps.length - 1)
                          Expanded(
                            child: Container(
                              height: 3,
                              color: idx < currentStep
                                  ? Colors.deepOrange
                                  : Colors.grey.shade200,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      steps[idx]['title'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCurrent
                            ? Colors.deepOrange.shade900
                            : isPassed
                            ? Colors.black87
                            : Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsMapSimulation(OrderModel order) {
    // Calcul de distance simulée et ETA
    final isHeadingToShop = order.status == OrderStatus.assigned;
    final targetDestination = isHeadingToShop
        ? order.vendorAddress
        : order.deliveryAddress;
    final targetContact = isHeadingToShop ? order.vendorName : order.clientName;
    final distanceKm = isHeadingToShop ? '1.8 km' : '3.4 km';
    final etaMinutes = isHeadingToShop ? '6 min' : '12 min';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark slate aesthetic for GPS map
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.gps_fixed,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Suivi GPS & Itinéraire en direct',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: Colors.amber,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ETA : $etaMinutes ($distanceKm)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Trace GPS simulé avec graphisme interactif
          Container(
            height: 130,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepOrange.shade700.withAlpha(80)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Étape 1 : Vendeur
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isHeadingToShop
                                ? Colors.amber
                                : Colors.blue.shade400,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.store,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.vendorName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),

                    // Ligne pointillée animée avec icône de moto
                    Expanded(
                      child: Column(
                        children: [
                          Icon(
                            Icons.two_wheeler,
                            color: Colors.deepOrangeAccent.shade400,
                            size: 24,
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.deepOrangeAccent.shade400,
                                  Colors.orangeAccent,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Text(
                            '$distanceKm restant',
                            style: TextStyle(
                              color: Colors.deepOrangeAccent.shade100,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Étape 2 : Client
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: !isHeadingToShop
                                ? Colors.greenAccent.shade700
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.clientName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Adresse cible et boutons d'appel
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isHeadingToShop ? Icons.store : Icons.home,
                  color: Colors.deepOrangeAccent,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHeadingToShop
                            ? 'Point de retrait (Boutique) :'
                            : 'Point de livraison (Client) :',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        targetDestination,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Contact : $targetContact',
                        style: const TextStyle(
                          color: Colors.deepOrangeAccent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.phone),
                  tooltip: 'Appeler',
                  onPressed: () {
                    final phone = isHeadingToShop
                        ? order.vendorPhone
                        : order.clientPhone;
                    _showSnack('Appel simulé vers le numéro : $phone');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionActionCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Action requise pour la mission',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Message d'instruction selon le statut actuel
          if (order.status == OrderStatus.assigned) ...[
            Text(
              '1. Rendez-vous à l\'adresse de la boutique : "${order.vendorAddress}".\n2. Récupérez la commande et vérifiez son contenu.\n3. Cliquez ci-dessous pour valider la prise en charge.',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepOrange.shade700,
                ),
                icon: const Icon(Icons.inventory_2),
                label: const Text(
                  'Confirmer la récupération chez le vendeur',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final err = await _controller.confirmPickup(order.id);
                  if (err != null) {
                    _showSnack(err, isError: true);
                  } else {
                    _showSnack(
                      'Commande récupérée ! Prochaine étape : livraison.',
                    );
                  }
                },
              ),
            ),
          ] else if (order.status == OrderStatus.pickedUp) ...[
            Text(
              'La commande est entre vos mains !\n1. Démarrez votre trajet vers le client à l\'adresse : "${order.deliveryAddress}".\n2. Cliquez sur le bouton pour notifier le client de votre départ.',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange.shade800,
                ),
                icon: const Icon(Icons.two_wheeler),
                label: const Text(
                  'Démarrer la course vers le client',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final err = await _controller.startDelivering(order.id);
                  if (err != null) {
                    _showSnack(err, isError: true);
                  } else {
                    _showSnack('Statut mis à jour : en cours de livraison !');
                  }
                },
              ),
            ),
          ] else if (order.status == OrderStatus.delivering) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.monetization_on, color: Colors.amber.shade800),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      order.paymentMethod.toLowerCase().contains('espèces')
                          ? 'À ENCAISSER DU CLIENT : ${order.total.toStringAsFixed(1)} DT en espèces'
                          : 'COMMANDE DÉJÀ RÉGLÉE EN LIGNE (Ne pas encaisser)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  'Confirmer la livraison au client',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => _showConfirmDeliveryDialog(order),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Option de libérer la course en cas de problème
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(
                Icons.cancel_outlined,
                color: Colors.red,
                size: 16,
              ),
              label: const Text(
                'Libérer cette course / Problème',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
              onPressed: () => _showReleaseDialog(order),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmDeliveryDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation de livraison'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Avez-vous bien remis la commande à ${order.clientName} ?'),
            const SizedBox(height: 12),
            if (order.paymentMethod.toLowerCase().contains('espèces'))
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Montant encaissé : ${order.total.toStringAsFixed(1)} DT',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade700,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final err = await _controller.confirmDelivered(order.id);
              if (err != null) {
                _showSnack(err, isError: true);
              } else {
                _showSnack('Félicitations ! Livraison terminée avec succès.');
                _controller.setTab(3); // Aller vers historique & gains
              }
            },
            child: const Text('Oui, livraison terminée'),
          ),
        ],
      ),
    );
  }

  void _showReleaseDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Libérer la livraison'),
        content: const Text(
          'Voulez-vous annuler votre prise en charge ? Cette commande sera à nouveau visible pour les autres livreurs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Garder la course'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final err = await _controller.releaseDelivery(order.id);
              if (err != null) {
                _showSnack(err, isError: true);
              } else {
                _showSnack('Course libérée.');
                _controller.setTab(1);
              }
            },
            child: const Text('Libérer la course'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contenu du colis',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            separatorBuilder: (_, _) => const Divider(height: 16),
            itemBuilder: (context, idx) {
              final item = order.items[idx];
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${item.quantity}x',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '${(item.price * item.quantity).toStringAsFixed(1)} DT',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ],
              );
            },
          ),
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.note, size: 16, color: Colors.orange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Note du client : "${order.notes}"',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ========================================================
  // ONGLET 3 : HISTORIQUE & GAINS (SECTION 9 DU PDF)
  // ========================================================
  Widget _buildHistoryTab() {
    return StreamBuilder<List<OrderModel>>(
      stream: _controller.watchMyDeliveries(widget.user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data ?? [];
        final completed = orders
            .where((o) => o.status == OrderStatus.delivered)
            .toList();
        final totalGain = completed.fold(0.0, (sum, o) => sum + o.deliveryFee);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bilan financier
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepOrange.shade800, Colors.deepOrange.shade900],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrange.withAlpha(40),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Portefeuille & Commissions',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${totalGain.toStringAsFixed(2)} DT',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildStatPill(
                          'Courses livrées',
                          '${completed.length}',
                        ),
                        const SizedBox(width: 12),
                        _buildStatPill('Moyenne / course', '4.50 DT'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Historique des courses (${completed.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              if (completed.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history_toggle_off,
                        size: 56,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Aucune course terminée pour l\'instant',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Vos livraisons terminées apparaîtront ici avec vos gains détaillés.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: completed.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = completed[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: Colors.green.shade700,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Livré à ${order.clientName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  order.deliveryAddress,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Boutique : ${order.vendorName}',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '+${order.deliveryFee.toStringAsFixed(1)} DT',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // ONGLET 4 : PROFIL & VÉHICULE (SECTION 8 DU PDF)
  // ========================================================
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte Header Profil
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.deepOrange.shade700,
                  child: Text(
                    widget.user.name.isNotEmpty
                        ? widget.user.name[0].toUpperCase()
                        : 'L',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.user.email,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Livreur certifié',
                              style: TextStyle(
                                color: Colors.deepOrange.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildAvailabilityBadge(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Formulaire informations livreur
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informations professionnelles & Véhicule',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone de contact',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _vehicleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Type de véhicule (Moto, Voiture, Vélo...)',
                    prefixIcon: Icon(Icons.two_wheeler_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _plateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Plaque d\'immatriculation',
                    prefixIcon: Icon(Icons.confirmation_number_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _cityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ville d\'intervention',
                    prefixIcon: Icon(Icons.location_city_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.deepOrange.shade700,
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text('Enregistrer les modifications'),
                    onPressed: () async {
                      final err = await _controller.updateProfile(
                        courierId: widget.user.uid,
                        name: _nameCtrl.text.trim(),
                        phone: _phoneCtrl.text.trim(),
                        vehicleType: _vehicleCtrl.text.trim(),
                        plateNumber: _plateCtrl.text.trim(),
                        city: _cityCtrl.text.trim(),
                      );
                      if (err != null) {
                        _showSnack(err, isError: true);
                      } else {
                        _showSnack('Profil mis à jour avec succès !');
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Évaluations reçues (Section 12 du PDF)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Évaluations des clients',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '4.9 / 5',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildReviewItem(
                  'Sarra B.',
                  'Livreur très rapide et courtois. Commande bien chaude !',
                  5,
                ),
                const Divider(height: 20),
                _buildReviewItem(
                  'Karim M.',
                  'Ponctuel et professionnel, je recommande.',
                  5,
                ),
                const Divider(height: 20),
                _buildReviewItem(
                  'Amine T.',
                  'Livraison effectuée dans les délais prévus.',
                  4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String author, String comment, int stars) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              author,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Row(
              children: List.generate(
                5,
                    (i) => Icon(
                  Icons.star,
                  size: 14,
                  color: i < stars
                      ? Colors.amber.shade700
                      : Colors.grey.shade300,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          comment,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        ),
      ],
    );
  }

  // Dialogue de détails d'une commande
  void _showOrderDetailsDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Détails de la commande #${order.id.length > 6 ? order.id.substring(0, 6).toUpperCase() : order.id}',
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.store, color: Colors.deepOrange),
                  title: Text(
                    order.vendorName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${order.vendorAddress}\nTél : ${order.vendorPhone}',
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on, color: Colors.orange),
                  title: Text(
                    'Client : ${order.clientName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${order.deliveryAddress}\nTél : ${order.clientPhone}',
                  ),
                ),
                if (order.notes != null) ...[
                  const Divider(),
                  Text(
                    'Note : ${order.notes}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
                const Divider(),
                const Text(
                  'Articles :',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...order.items.map(
                      (i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${i.quantity}x ${i.name}'),
                        Text('${(i.price * i.quantity).toStringAsFixed(1)} DT'),
                      ],
                    ),
                  ),
                ),
                const Divider(),
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
                    const Text(
                      'Frais de livraison (votre gain) :',
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '+${order.deliveryFee.toStringAsFixed(1)} DT',
                      style: const TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total à encaisser :',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${order.total.toStringAsFixed(1)} DT',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _controller.acceptDelivery(order: order, courier: widget.user);
            },
            child: const Text('Accepter cette commande'),
          ),
        ],
      ),
    );
  }
}