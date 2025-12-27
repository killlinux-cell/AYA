import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/vendor_map_service.dart';

class VendorMapWidget extends StatefulWidget {
  final List<VendorLocation> vendors;
  final double? userLatitude;
  final double? userLongitude;

  const VendorMapWidget({
    super.key,
    required this.vendors,
    this.userLatitude,
    this.userLongitude,
  });

  @override
  State<VendorMapWidget> createState() => _VendorMapWidgetState();
}

class _VendorMapWidgetState extends State<VendorMapWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  VendorLocation? _selectedVendor;
  bool _showVendorList = false;

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  @override
  void didUpdateWidget(VendorMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vendors != widget.vendors) {
      _createMarkers();
    }
  }

  void _createMarkers() {
    _markers.clear();

    // Marqueur de l'utilisateur
    if (widget.userLatitude != null && widget.userLongitude != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(widget.userLatitude!, widget.userLongitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Ma position',
            snippet: 'Votre position actuelle',
          ),
        ),
      );
    }

    // Marqueurs des vendeurs
    for (final vendor in widget.vendors) {
      _markers.add(
        Marker(
          markerId: MarkerId(vendor.id),
          position: LatLng(vendor.latitude, vendor.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            vendor.isActive
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: vendor.businessName,
            snippet:
                '${vendor.fullAddress}\n${vendor.isActive ? "Ouvert" : "Fermé"}',
          ),
          onTap: () => _onVendorTapped(vendor),
        ),
      );
    }
  }

  void _onVendorTapped(VendorLocation vendor) {
    setState(() {
      _selectedVendor = vendor;
      _showVendorList = true;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  LatLng _getInitialCameraPosition() {
    // Si l'utilisateur a une position, l'utiliser
    if (widget.userLatitude != null && widget.userLongitude != null) {
      return LatLng(widget.userLatitude!, widget.userLongitude!);
    }

    // Si des vendeurs sont disponibles, centrer sur eux
    if (widget.vendors.isNotEmpty) {
      return _calculateVendorsCenter();
    }

    // Sinon, centrer sur la Côte d'Ivoire
    return const LatLng(7.5400, -5.5471); // Centre de la Côte d'Ivoire
  }

  double _getInitialZoom() {
    // Si l'utilisateur a une position, zoom plus proche
    if (widget.userLatitude != null && widget.userLongitude != null) {
      return 12.0;
    }

    // Si des vendeurs sont disponibles, ajuster le zoom pour tous les voir
    if (widget.vendors.isNotEmpty) {
      return _calculateOptimalZoom();
    }

    // Sinon, zoom pour voir toute la Côte d'Ivoire
    return 7.0;
  }

  LatLng _calculateVendorsCenter() {
    if (widget.vendors.isEmpty) {
      return const LatLng(7.5400, -5.5471);
    }

    double totalLat = 0;
    double totalLng = 0;

    for (final vendor in widget.vendors) {
      totalLat += vendor.latitude;
      totalLng += vendor.longitude;
    }

    return LatLng(
      totalLat / widget.vendors.length,
      totalLng / widget.vendors.length,
    );
  }

  double _calculateOptimalZoom() {
    if (widget.vendors.length <= 1) {
      return 12.0;
    }

    // Calculer la distance maximale entre les vendeurs
    double maxDistance = 0;

    for (int i = 0; i < widget.vendors.length; i++) {
      for (int j = i + 1; j < widget.vendors.length; j++) {
        final vendor1 = widget.vendors[i];
        final vendor2 = widget.vendors[j];

        final distance = _calculateDistance(
          vendor1.latitude,
          vendor1.longitude,
          vendor2.latitude,
          vendor2.longitude,
        );

        if (distance > maxDistance) {
          maxDistance = distance;
        }
      }
    }

    // Ajuster le zoom en fonction de la distance
    if (maxDistance > 100) return 6.0; // Vue très large
    if (maxDistance > 50) return 7.0; // Vue large
    if (maxDistance > 20) return 8.0; // Vue moyenne
    if (maxDistance > 10) return 9.0; // Vue rapprochée
    return 10.0; // Vue très rapprochée
  }

  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371; // Rayon de la Terre en km

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  void _centerOnUser() {
    if (_mapController != null &&
        widget.userLatitude != null &&
        widget.userLongitude != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(widget.userLatitude!, widget.userLongitude!),
        ),
      );
    }
  }

  void _centerOnVendor(VendorLocation vendor) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(vendor.latitude, vendor.longitude)),
      );
    }
  }

  void _centerOnCoteDIvoire() {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          const LatLng(7.5400, -5.5471), // Centre de la Côte d'Ivoire
          7.0, // Zoom pour voir tout le pays
        ),
      );
    }
  }

  void _centerOnVendors() {
    if (_mapController != null && widget.vendors.isNotEmpty) {
      final center = _calculateVendorsCenter();
      final zoom = _calculateOptimalZoom();

      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(center, zoom));
    } else if (widget.vendors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun vendeur disponible'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _callVendor(String phoneNumber) async {
    try {
      final uri = Uri(scheme: 'tel', path: phoneNumber);

      // Vérifier si l'URL peut être lancée
      if (await canLaunchUrl(uri)) {
        // Essayer de lancer l'appel
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Impossible d\'ouvrir l\'appel vers $phoneNumber'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Aucune application téléphone disponible pour appeler $phoneNumber',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'appel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToVendor(VendorLocation vendor) async {
    if (widget.userLatitude == null || widget.userLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Position utilisateur non disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Ouvrir Google Maps avec l'itinéraire
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/${widget.userLatitude},${widget.userLongitude}/${vendor.latitude},${vendor.longitude}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir Google Maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Carte Google Maps
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _getInitialCameraPosition(),
              zoom: _getInitialZoom(),
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            // Activer tous les gestes de navigation
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
            compassEnabled: true,
            liteModeEnabled: false,
            buildingsEnabled: true,
            trafficEnabled: false,
          ),

          // Boutons de contrôle
          Positioned(
            top: 50,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  onPressed: _centerOnUser,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _centerOnCoteDIvoire,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.public, color: Colors.orange),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _centerOnVendors,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.store, color: Colors.green),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    setState(() {
                      _showVendorList = !_showVendorList;
                    });
                  },
                  backgroundColor: Colors.white,
                  child: Icon(
                    _showVendorList ? Icons.close : Icons.list,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // Liste des vendeurs
          if (_showVendorList)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.4,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Titre
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.store, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Vendeurs AYA+ (${widget.vendors.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Liste des vendeurs
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: widget.vendors.length,
                        itemBuilder: (context, index) {
                          final vendor = widget.vendors[index];
                          return _buildVendorCard(vendor);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Légende
          Positioned(
            top: 50,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Légende',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('Ouvert', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('Fermé', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Détails du vendeur sélectionné
          if (_selectedVendor != null)
            Positioned(
              bottom: _showVendorList
                  ? MediaQuery.of(context).size.height * 0.4 + 16
                  : 16,
              left: 16,
              right: 16,
              child: _buildVendorDetailsCard(_selectedVendor!),
            ),
        ],
      ),
    );
  }

  Widget _buildVendorCard(VendorLocation vendor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: vendor.isActive ? Colors.green : Colors.red,
          child: Icon(
            vendor.isActive ? Icons.store : Icons.store_mall_directory,
            color: Colors.white,
          ),
        ),
        title: Text(
          vendor.businessName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vendor.fullAddress),
            if (vendor.distance != null)
              Text(
                '${vendor.distance!.toStringAsFixed(1)} km',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.location_on, color: Colors.blue),
              onPressed: () => _centerOnVendor(vendor),
            ),
            IconButton(
              icon: const Icon(Icons.phone, color: Colors.green),
              onPressed: () => _callVendor(vendor.phoneNumber),
            ),
          ],
        ),
        onTap: () {
          setState(() {
            _selectedVendor = vendor;
          });
          _centerOnVendor(vendor);
        },
      ),
    );
  }

  Widget _buildVendorDetailsCard(VendorLocation vendor) {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: vendor.isActive ? Colors.green : Colors.red,
                  child: Icon(
                    vendor.isActive ? Icons.store : Icons.store_mall_directory,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor.businessName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        vendor.vendorCode,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedVendor = null;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vendor.fullAddress,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),

            if (vendor.distance != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.directions, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${vendor.distance!.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _callVendor(vendor.phoneNumber),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Appeler'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToVendor(vendor),
                    icon: const Icon(Icons.directions, size: 16),
                    label: const Text('Itinéraire'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
