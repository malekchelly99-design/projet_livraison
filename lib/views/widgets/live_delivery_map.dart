import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/courier_location.dart';
import '../../models/order_model.dart';
import '../../utils/route_coordinates_helper.dart';

/// Carte interactive en temps réel affichant l'itinéraire de livraison complet
/// (Boutique -> Livreur -> Client) avec les noms affichés sous chaque point.
class LiveDeliveryMap extends StatefulWidget {
  final OrderModel order;
  final CourierLocation? location;
  final double height;
  final bool isCourierView;
  final LatLng? destinationLatLng;
  final LatLng? vendorLatLng;
  final VoidCallback? onExpandFullScreen;

  const LiveDeliveryMap({
    super.key,
    required this.order,
    this.location,
    this.height = 360,
    this.isCourierView = false,
    this.destinationLatLng,
    this.vendorLatLng,
    this.onExpandFullScreen,
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

  DeliveryRouteResult _getRouteResult() {
    return RouteCoordinatesHelper.resolveOrderRoute(
      order: widget.order,
      liveLocation: _getEffectiveLocation(),
      explicitDestination: widget.destinationLatLng,
      explicitVendor: widget.vendorLatLng,
    );
  }

  @override
  void didUpdateWidget(covariant LiveDeliveryMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    final route = _getRouteResult();
    final courierLatLng = route.courierPoint.position;

    if (_autoFollow) {
      if (_lastCenteredLocation == null ||
          _lastCenteredLocation!.latitude != courierLatLng.latitude ||
          _lastCenteredLocation!.longitude != courierLatLng.longitude) {
        _lastCenteredLocation = courierLatLng;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            _mapController.move(courierLatLng, _mapController.camera.zoom);
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

  void _recenterOnCourier(LatLng courierPos) {
    _mapController.move(courierPos, 16.0);
    setState(() => _autoFollow = true);
  }

  void _fitAllRoutePoints(List<LatLng> points) {
    if (points.isEmpty) return;
    try {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
          maxZoom: 16.5,
          minZoom: 11.0,
        ),
      );
      setState(() => _autoFollow = false);
    } catch (_) {}
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
    final route = _getRouteResult();
    final courierPos = route.courierPoint.position;
    final vendorPos = route.vendorPoint.position;
    final destPos = route.destinationPoint.position;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. CARTE OPENSTREETMAP (Leaflet via flutter_map)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: courierPos,
              initialZoom: 14.5,
              minZoom: 5.0,
              maxZoom: 18.0,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture && _autoFollow) {
                  setState(() => _autoFollow = false);
                }
              },
            ),
            children: [
              // Tuiles OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.livraison_rapide',
              ),

              // Tracé de l'itinéraire (Polylines)
              PolylineLayer(
                polylines: [
                  // Contour blanc pour visibilité optimale sur la carte
                  Polyline(
                    points: route.fullRoute,
                    strokeWidth: 6.5,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  // Segment Boutique -> Livreur (parcours effectué / en cours de collecte)
                  Polyline(
                    points: route.completedSegment,
                    strokeWidth: 4.5,
                    color: const Color(0xFF6366F1), // Indigo
                  ),
                  // Segment Livreur -> Client (trajet en cours vers la destination)
                  Polyline(
                    points: route.remainingSegment,
                    strokeWidth: 4.5,
                    color: const Color(0xFFEA580C), // Orange vif
                  ),
                ],
              ),

              // Marqueurs avec les NOMS sous chaque point
              MarkerLayer(
                markers: [
                  // 1. POINT BOUTIQUE (Point de retrait)
                  Marker(
                    point: vendorPos,
                    width: 140,
                    height: 82,
                    alignment: const Alignment(0.0, -0.6),
                    child: _buildNamedPointMarker(
                      info: route.vendorPoint,
                      defaultBadgeIcon: Icons.storefront_rounded,
                      badgeColor: const Color(0xFF7C3AED),
                    ),
                  ),

                  // 2. POINT CLIENT / DESTINATION
                  // Si le livreur et le client sont au même endroit (ex: test sur téléphone et PC dans la même pièce),
                  // on décale légèrement l'alignement pour que les deux étiquettes restent parfaitement visibles
                  Marker(
                    point: destPos,
                    width: 140,
                    height: 82,
                    alignment: ((courierPos.latitude - destPos.latitude).abs() < 0.0003 &&
                            (courierPos.longitude - destPos.longitude).abs() < 0.0003)
                        ? const Alignment(-0.65, -0.6)
                        : const Alignment(0.0, -0.6),
                    child: _buildNamedPointMarker(
                      info: route.destinationPoint,
                      defaultBadgeIcon: Icons.home_rounded,
                      badgeColor: const Color(0xFF10B981),
                    ),
                  ),

                  // 3. POINT LIVREUR (En direct)
                  Marker(
                    point: courierPos,
                    width: 150,
                    height: 86,
                    alignment: ((courierPos.latitude - destPos.latitude).abs() < 0.0003 &&
                            (courierPos.longitude - destPos.longitude).abs() < 0.0003)
                        ? const Alignment(0.65, -0.6)
                        : const Alignment(0.0, -0.6),
                    child: _buildNamedCourierMarker(
                      info: route.courierPoint,
                      hasLiveGps: route.hasLiveGps,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. BANDEAU DE STATUT SUPÉRIEUR
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: _buildStatusHeader(route),
          ),

          // 3. CONTRÔLES COMPACTS DE NAVIGATION (Recentrer, Vue globale, Zoom)
          Positioned(
            right: 10,
            bottom: 64,
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
                    onTap: () => _recenterOnCourier(courierPos),
                  ),
                  Container(height: 1, width: 28, color: Colors.grey.shade200),
                  _buildMapIconButton(
                    icon: Icons.alt_route,
                    color: Colors.indigo.shade600,
                    tooltip: 'Voir tout l\'itinéraire (Boutique, Livreur, Client)',
                    onTap: () => _fitAllRoutePoints(route.fullRoute),
                  ),
                  if (widget.onExpandFullScreen != null) ...[
                    Container(height: 1, width: 28, color: Colors.grey.shade200),
                    _buildMapIconButton(
                      icon: Icons.fullscreen,
                      color: Colors.teal.shade700,
                      tooltip: 'Agrandir en plein écran',
                      onTap: widget.onExpandFullScreen!,
                    ),
                  ],
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

          // 4. BANDEAU D'INFORMATIONS INFÉRIEUR (ETA, Étapes & Vitesse)
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: _buildBottomInfoBar(route),
          ),
        ],
      ),
    );
  }

  /// Marqueur avec badge icône et étiquette contenant le nom sous le point
  Widget _buildNamedPointMarker({
    required RoutePointInfo info,
    required IconData defaultBadgeIcon,
    required Color badgeColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Pin circulaire principal
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: badgeColor,
            border: Border.all(color: Colors.white, width: 2.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              info.icon,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),

        const SizedBox(height: 3),

        // Étiquette avec le NOM sous le point
        Container(
          constraints: const BoxConstraints(maxWidth: 135),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: badgeColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                info.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              Text(
                info.role,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: badgeColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Marqueur du livreur avec halo pulsant et son nom sous le point
  Widget _buildNamedCourierMarker({
    required RoutePointInfo info,
    required bool hasLiveGps,
  }) {
    const courierColor = Color(0xFFEA580C);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icône Livreur avec halo en direct
        Stack(
          alignment: Alignment.center,
          children: [
            // Halo lumineux
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: courierColor.withValues(alpha: hasLiveGps ? 0.35 : 0.15),
              ),
            ),
            // Cercle principal
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: courierColor,
                border: Border.all(color: Colors.white, width: 2.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.two_wheeler,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 2),

        // Étiquette avec le NOM du livreur sous le point
        Container(
          constraints: const BoxConstraints(maxWidth: 145),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A), // Fond sombre contrasté
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: courierColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                info.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              Text(
                info.subtitle,
                style: const TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFB923C),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildStatusHeader(DeliveryRouteResult route) {
    final status = widget.order.status;
    Color badgeColor;
    String statusTitle;

    switch (status) {
      case OrderStatus.preparing:
        badgeColor = Colors.blue;
        statusTitle = 'En préparation chez la boutique';
        break;
      case OrderStatus.ready:
        badgeColor = Colors.purple;
        statusTitle = 'Commande prête - En attente du livreur';
        break;
      case OrderStatus.assigned:
        badgeColor = Colors.indigo;
        statusTitle = 'Livreur affecté - En route vers la boutique';
        break;
      case OrderStatus.pickedUp:
        badgeColor = Colors.orange;
        statusTitle = 'Colis récupéré - En route vers vous';
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

    final isSameLocation =
        (route.courierPoint.position.latitude - route.destinationPoint.position.latitude).abs() < 0.0003 &&
        (route.courierPoint.position.longitude - route.destinationPoint.position.longitude).abs() < 0.0003;

    if (isSameLocation && (status == OrderStatus.delivering || status == OrderStatus.pickedUp)) {
      statusTitle = 'Livreur sur place (Même localisation)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: route.hasLiveGps ? Colors.green : badgeColor,
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
                    fontSize: 12,
                    color: Colors.grey.shade900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  route.hasLiveGps
                      ? 'GPS en direct actif • Livreur en mouvement'
                      : 'Itinéraire complet tracé • Noms affichés',
                  style: TextStyle(
                    fontSize: 10,
                    color: route.hasLiveGps
                        ? Colors.green.shade700
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.label,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.bold,
                fontSize: 10.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInfoBar(DeliveryRouteResult route) {
    final isSameLocation = route.etaInfo['isSameLocation'] == true;
    final etaText = isSameLocation
        ? 'Arrivée : À destination / Même adresse (< 50 m)'
        : 'Arrivée : ~${route.etaInfo['formattedEta']} (${route.etaInfo['formattedDistance']})';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.navigation_rounded,
            color: Colors.deepOrange,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              etaText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          // Indicateur des 3 étapes
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storefront, size: 11, color: Color(0xFFA78BFA)),
                SizedBox(width: 2),
                Icon(Icons.arrow_right_alt, size: 11, color: Colors.white54),
                SizedBox(width: 2),
                Icon(Icons.two_wheeler, size: 11, color: Color(0xFFFB923C)),
                SizedBox(width: 2),
                Icon(Icons.arrow_right_alt, size: 11, color: Colors.white54),
                SizedBox(width: 2),
                Icon(Icons.home, size: 11, color: Color(0xFF34D399)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
