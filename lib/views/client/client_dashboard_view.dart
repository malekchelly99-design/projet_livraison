import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';

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
  int _selectedIndex = 0;

  // Contrôleurs de filtres
  final TextEditingController _shopSearchCtrl = TextEditingController();
  String _selectedCategory = 'Toutes';

  final List<Map<String, dynamic>> _categories = const [
    {'name': 'Toutes', 'icon': Icons.apps},
    {'name': 'Restaurants', 'icon': Icons.restaurant},
    {'name': 'Épicerie', 'icon': Icons.local_grocery_store},
    {'name': 'Pharmacie', 'icon': Icons.local_pharmacy},
    {'name': 'Boulangerie', 'icon': Icons.bakery_dining},
  ];

  @override
  void dispose() {
    _shopSearchCtrl.dispose();
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        if (isDesktop) {
          // Disposition pour Navigateur / Écran large : Barre latérale (Sidebar)
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

        // Disposition pour Mobile / Écran étroit : Barre de navigation inférieure
        return Scaffold(
          appBar: AppBar(
            title: Text(_getPageTitle()),
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
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront),
                label: 'Boutiques',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Commandes',
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
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Tableau de bord';
      case 1:
        return 'Boutiques partenaires';
      case 2:
        return 'Mes commandes';
      case 3:
        return 'Mon profil';
      default:
        return 'Espace Client';
    }
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
                    'Client vérifié',
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
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Logo / Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
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

          // Menu items
          _buildSidebarItem(
            index: 0,
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            title: 'Tableau de bord',
          ),
          _buildSidebarItem(
            index: 1,
            icon: Icons.storefront_outlined,
            selectedIcon: Icons.storefront,
            title: 'Boutiques',
          ),
          _buildSidebarItem(
            index: 2,
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long,
            title: 'Mes commandes',
          ),
          _buildSidebarItem(
            index: 3,
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            title: 'Mon profil',
          ),

          const Spacer(),
          const Divider(height: 1),

          // Déconnexion
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

  Widget _buildSidebarItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String title,
  }) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selected: isSelected,
        selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withAlpha(90),
        leading: Icon(
          isSelected ? selectedIcon : icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade700,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.black87,
          ),
        ),
        onTap: () => setState(() => _selectedIndex = index),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildShopsTab();
      case 2:
        return _buildOrdersTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildDashboardTab();
    }
  }

  // ==========================================
  // ONGLET 1 : TABLEAU DE BORD (DASHBOARD)
  // ==========================================
  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message d'accueil
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.tertiary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenue sur votre Dashboard, ${widget.user.name} 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Suivez vos commandes, explorez les boutiques partenaires et gérez vos livraisons.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.analytics_outlined, color: Colors.white, size: 56),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cartes KPI / Statistiques (Temps réel depuis Firestore)
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('clientId', isEqualTo: widget.user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              final orders = snapshot.data?.docs ?? [];
              final pendingCount = orders
                  .where((d) => (d.data()['status'] as String? ?? '') != 'Livrée' && (d.data()['status'] as String? ?? '') != 'Annulée')
                  .length;
              final completedCount = orders
                  .where((d) => (d.data()['status'] as String? ?? '') == 'Livrée')
                  .length;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  return GridView.count(
                    crossAxisCount: isWide ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: isWide ? 1.4 : 1.3,
                    children: [
                      _buildKpiCard(
                        title: 'En cours',
                        value: '$pendingCount',
                        icon: Icons.hourglass_top,
                        color: Colors.orange,
                      ),
                      _buildKpiCard(
                        title: 'Livrées',
                        value: '$completedCount',
                        icon: Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                      _buildKpiCard(
                        title: 'Total commandes',
                        value: '${orders.length}',
                        icon: Icons.receipt_long,
                        color: Colors.blue,
                      ),
                      _buildKpiCard(
                        title: 'Points Fidélité',
                        value: '50 pts',
                        icon: Icons.star_border,
                        color: Colors.amber.shade700,
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 28),

          // Actions rapides
          Text(
            'Actions rapides',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  title: 'Explorer boutiques',
                  icon: Icons.storefront,
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAction(
                  title: 'Mes commandes',
                  icon: Icons.receipt_long,
                  color: Colors.indigo,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAction(
                  title: 'Mon profil',
                  icon: Icons.person_outline,
                  color: Colors.teal,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Dernières activités / commandes récentes
          Text(
            'Commandes récentes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _buildRecentOrdersSummary(),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
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
            radius: 20,
            backgroundColor: color.withAlpha(30),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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

  Widget _buildQuickAction({
    required String title,
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
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(60)),
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

  Widget _buildRecentOrdersSummary() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('clientId', isEqualTo: widget.user.uid)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                const Text(
                  'Aucune activité récente',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vos dernières commandes apparaîtront ici.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            final status = data['status'] as String? ?? 'En attente';
            final total = (data['total'] as num?)?.toDouble() ?? 0.0;

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: const Icon(Icons.receipt, color: Colors.deepOrange),
                title: Text('Commande #${doc.id.substring(0, doc.id.length.clamp(0, 6)).toUpperCase()}'),
                subtitle: Text('Statut: $status'),
                trailing: Text(
                  '${total.toStringAsFixed(2)} DT',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ==========================================
  // ONGLET 2 : BOUTIQUES PARTENAIRES
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
              hintText: 'Rechercher une boutique ou un commerce...',
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
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(70),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat['name'];
                return ChoiceChip(
                  avatar: Icon(cat['icon'] as IconData, size: 16),
                  label: Text(cat['name'] as String),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = cat['name'] as String);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Liste des boutiques depuis Firestore
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'vendeur')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              final query = _shopSearchCtrl.text.trim().toLowerCase();

              final filtered = docs.where((doc) {
                final data = doc.data();
                final profile = Map<String, dynamic>.from(data['profile'] as Map? ?? {});
                final shopName = (profile['shopName'] as String? ?? data['name'] as String? ?? '').toLowerCase();
                final category = (profile['category'] as String? ?? '').toLowerCase();

                final matchQuery = query.isEmpty || shopName.contains(query);
                final matchCat = _selectedCategory == 'Toutes' ||
                    category.contains(_selectedCategory.toLowerCase());
                return matchQuery && matchCat;
              }).toList();

              if (filtered.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.storefront_outlined, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'Aucune boutique disponible',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Les boutiques créées par les vendeurs inscrits apparaîtront ici.',
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
                  final profile = Map<String, dynamic>.from(data['profile'] as Map? ?? {});
                  final shopName = profile['shopName'] as String? ?? data['name'] as String? ?? 'Boutique';
                  final category = profile['category'] as String? ?? 'Commerce';
                  final address = profile['address'] as String? ?? profile['city'] as String? ?? '';

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(Icons.store, color: Theme.of(context).colorScheme.primary),
                      ),
                      title: Text(shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text('$category • $address'),
                      trailing: FilledButton.tonal(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Boutique : $shopName')),
                          );
                        },
                        child: const Text('Visiter'),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ONGLET 3 : MES COMMANDES
  // ==========================================
  Widget _buildOrdersTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('clientId', isEqualTo: widget.user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune commande enregistrée',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vos commandes passées apparaîtront ici avec leur suivi en temps réel.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final orderId = docs[index].id;
            final status = data['status'] as String? ?? 'En attente';
            final total = (data['total'] as num?)?.toDouble() ?? 0.0;
            final address = data['deliveryAddress'] as String? ?? '';

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Commande #${orderId.substring(0, orderId.length.clamp(0, 6)).toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Chip(
                          label: Text(status),
                          backgroundColor: Colors.orange.shade50,
                          labelStyle: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total : ${total.toStringAsFixed(2)} DT', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(address, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // ONGLET 4 : PROFIL CLIENT
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
                  radius: 44,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    widget.user.name.isNotEmpty
                        ? widget.user.name[0].toUpperCase()
                        : 'C',
                    style: TextStyle(
                      fontSize: 32,
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
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Téléphone'),
                  subtitle: Text(widget.user.phone.isNotEmpty ? widget.user.phone : 'Non renseigné'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(widget.user.email),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Rôle utilisateur'),
                  subtitle: const Text('Client'),
                ),
              ],
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
