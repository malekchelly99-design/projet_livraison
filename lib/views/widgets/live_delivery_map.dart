import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/courier_location.dart';
import '../../models/order_model.dart';
import '../../services/location_tracking_service.dart';

/// Carte interactive en temps réel affichant la position du livreur et de la livraison
/// utilisant OpenStreetMap (Leaflet / flutter_map).
class LiveDeliveryMap extends StatefulWidget {
  final OrderModel order;
  final CourierLocation? location;
  final double height;
  final bool isCourierView;
  final LatLng? destinationLatLng;

  const LiveDeliveryMap({
    super.key,
    required this.order,
    this.location,
    this.height = 360,
    this.isCourierView = false,
    this.destinationLatLng,
  });

  @override
  State<LiveDeliveryMap> createState() => _LiveDeliveryMapState();
}

class _LiveDeliveryMapState extends State<LiveDeliveryMap> {
  late final MapController _mapController;
  bool _autoFollow = true;
  LatLng? _lastCenteredLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  CourierLocation? _getEffectiveLocation() {
    if (widget.location != null &&
        widget.location!.latitude != 0.0 &&
        widget.location!.longitude != 0.0) {
      return widget.location;
    }
    if (widget.order.courierLatitude != null &&
        widget.order.courierLongitude != null &&
        widget.order.courierLatitude != 0.0) {
      return CourierLocation(
        id: widget.order.id,
        courierId: widget.order.courierId ?? '',
        orderId: widget.order.id,
        latitude: widget.order.courierLatitude!,
        longitude: widget.order.courierLongitude!,
        updatedAt: DateTime.now(),
        heading: widget.order.courierHeading,
        speed: widget.order.courierSpeed,
        isActive: widget.order.isTrackingActive ?? true,
      );
    }
    return null;
  }

  @override
  void didUpdateWidget(covariant LiveDeliveryMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newLoc = _getEffectiveLocation();
    if (newLoc != null && _autoFollow) {
      final currentLatLng = LatLng(newLoc.latitude, newLoc.longitude);
      if (_lastCenteredLocation == null ||
          _lastCenteredLocation!.latitude != currentLatLng.latitude ||
          _lastCenteredLocation!.longitude != currentLatLng.longitude) {
        _lastCenteredLocation = currentLatLng;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            _mapController.move(currentLatLng, _mapController.camera.zoom);
          } catch (_) {}
        });
      }
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _recenterOnCourier() {
    final loc = _getEffectiveLocation();
    if (loc != null) {
      final target = LatLng(loc.latitude, loc.longitude);
      _mapController.move(target, 16.0);
      setState(() => _autoFollow = true);
    }
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  @override
  Widget build(BuildContext context) {
    final location = _getEffectiveLocation();
    final hasLocation = location != null &&
        location.latitude != 0.0 &&
        location.longitude != 0.0;

    // Si pas de position active et que la livraison n'a pas encore démarré
    final isDelivering = widget.order.status == OrderStatus.delivering;
    final isAssignedOrPickedUp = widget.order.status == OrderStatus.assigned ||
        widget.order.status == OrderStatus.pickedUp;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. CARTE FLUTTER_MAP / OPENSTREETMAP
          if (hasLocation)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(location.latitude, location.longitude),
                initialZoom: 15.5,
                minZoom: 5.0,
                maxZoom: 18.0,
                onPositionChanged: (camera, hasGesture) {
                  if (hasGesture && _autoFollow) {
                    setState(() => _autoFollow = false);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.livraison_rapide',
                ),
                MarkerLayer(
                  markers: [
                    // Marqueur de la destination (si disponible)
                    if (widget.destinationLatLng != null)
                      Marker(
                        point: widget.destinationLatLng!,
                        width: 50,
                        height: 50,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Marqueur du Livreur avec effet visuel
                    Marker(
                      point: LatLng(location.latitude, location.longitude),
                      width: 60,
                      height: 60,
                      child: _buildCourierMarker(location),
                    ),
                  ],
                ),
              ],
            )
          else
            _buildNoLocationPlaceholder(isDelivering, isAssignedOrPickedUp),

          // 2. BANDEAU DE STATUT SUPÉRIEUR
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _buildStatusHeader(hasLocation, location),
          ),

          // 3. CONTRÔLES COMPACTS DE LA CARTE (Zoom & Recentrage sans Hero ni overflow)
          if (hasLocation)
            Positioned(
              right: 12,
              bottom: 60,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMapIconButton(
                      icon: Icons.my_location,
                      color: _autoFollow ? Colors.deepOrange : Colors.grey.shade700,
                      tooltip: 'Recentrer sur le livreur',
                      onTap: _recenterOnCourier,
                    ),
                    Container(height: 1, width: 28, color: Colors.grey.shade200),
                    _buildMapIconButton(
                      icon: Icons.add,
                      color: Colors.grey.shade800,
                      tooltip: 'Zoom avant',
                      onTap: _zoomIn,
                    ),
                    Container(height: 1, width: 28, color: Colors.grey.shade200),
                    _buildMapIconButton(
                      icon: Icons.remove,
                      color: Colors.grey.shade800,
                      tooltip: 'Zoom arrière',
                      onTap: _zoomOut,
                    ),
                  ],
                ),
              ),
            ),

          // 4. BANDEAU D'INFORMATIONS INFÉRIEUR (ETA & VITESSE)
          if (hasLocation)
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: _buildBottomInfoBar(location),
            ),
        ],
      ),
    );
  }

  Widget _buildMapIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildCourierMarker(CourierLocation loc) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Halo pulsant
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.deepOrange.withValues(alpha: 0.25),
          ),
        ),
        // Cercle extérieur
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.deepOrange.shade600,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.two_wheeler,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusHeader(bool hasLocation, CourierLocation? loc) {
    final status = widget.order.status;
    Color badgeColor;
    String statusTitle;

    switch (status) {
      case OrderStatus.preparing:
        badgeColor = Colors.blue;
        statusTitle = 'En préparation chez le vendeur';
        break;
      case OrderStatus.ready:
        badgeColor = Colors.purple;
        statusTitle = 'Prête - En attente du livreur';
        break;
      case OrderStatus.assigned:
        badgeColor = Colors.indigo;
        statusTitle = 'Livreur assigné - En route vers la boutique';
        break;
      case OrderStatus.pickedUp:
        badgeColor = Colors.orange;
        statusTitle = 'Colis récupéré - Départ imminent';
        break;
      case OrderStatus.delivering:
        badgeColor = Colors.green;
        statusTitle = 'En cours de livraison vers votre adresse';
        break;
      case OrderStatus.delivered:
        badgeColor = Colors.teal;
        statusTitle = 'Commande livrée avec succès !';
        break;
      default:
        badgeColor = Colors.grey;
        statusTitle = status.label;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasLocation ? Colors.green : badgeColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey.shade900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  hasLocation
                      ? (loc?.isActive == true
                          ? 'Suivi GPS en direct activé'
                          : 'Dernière position connue enregistrée')
                      : 'Position en attente d\'activation',
                  style: TextStyle(
                    fontSize: 11,
                    color: hasLocation ? Colors.green.shade700 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.label,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInfoBar(CourierLocation loc) {
    // Calcul ETA si destination présente
    String etaText = 'Calcul de l\'arrivée...';
    if (widget.destinationLatLng != null) {
      final info = LocationTrackingService.calculateDistanceAndEta(
        startLat: loc.latitude,
        startLng: loc.longitude,
        endLat: widget.destinationLatLng!.latitude,
        endLng: widget.destinationLatLng!.longitude,
      );
      etaText = 'Arrivée estimée : ~${info['formattedEta']} (${info['formattedDistance']})';
    } else {
      etaText = 'GPS Actif : ${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.navigation_outlined,
            color: Colors.deepOrange,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              etaText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (loc.speed != null && loc.speed! > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${(loc.speed! * 3.6).toStringAsFixed(0)} km/h',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoLocationPlaceholder(bool isDelivering, bool isAssigned) {
    return Container(
      width: double.infinity,
      color: Colors.grey.shade50,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepOrange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDelivering
                  ? Icons.location_searching
                  : (isAssigned ? Icons.moped : Icons.schedule),
              size: 40,
              color: Colors.deepOrange.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isDelivering
                ? 'Signal GPS en cours d\'initialisation'
                : (isAssigned
                    ? 'Le livreur prépare votre commande'
                    : 'Livraison en attente de prise en charge'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isDelivering
                ? 'La position du livreur va s\'afficher automatiquement sur la carte dès que le signal satellite sera reçu.'
                : 'La carte interactive en temps réel s\'activera dès que le livreur prendra la route pour la livraison.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.isCourierView && isDelivering) ...[
            const SizedBox(height: 16),
            const Text(
              '⚠️ Activez le partage GPS ci-dessous pour transmettre votre position au client.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.deepOrange,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

