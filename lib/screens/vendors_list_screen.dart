import 'package:flutter/material.dart';
import '../services/vendor_service.dart';
import '../services/django_auth_service.dart';
import '../services/vendor_map_service.dart';
import '../widgets/vendor_map_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class VendorsListScreen extends StatefulWidget {
  const VendorsListScreen({Key? key}) : super(key: key);

  @override
  State<VendorsListScreen> createState() => _VendorsListScreenState();
}

class _VendorsListScreenState extends State<VendorsListScreen>
    with TickerProviderStateMixin {
  final VendorService _vendorService = VendorService(
    DjangoAuthService.instance,
  );
  List<Vendor> _vendors = [];
  Map<String, List<Vendor>> _vendorsByRegion = {};
  bool _isLoading = true;
  String _selectedRegion = 'Toutes les régions';
  late TabController _tabController;

  // Variables pour la carte
  List<VendorLocation> _vendorLocations = [];
  double? _userLatitude;
  double? _userLongitude;
  bool _isMapLoading = false;
  String _mapError = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVendors();

    // Écouter les changements d'onglet pour charger la carte
    _tabController.addListener(() {
      if (_tabController.index == 1 && _vendorLocations.isEmpty) {
        _loadMapData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVendors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 VendorsListScreen: Chargement des vendeurs...');

      final vendors = await _vendorService.getAvailableVendors();
      final vendorsByRegion = await _vendorService.getVendorsByRegion();

      setState(() {
        _vendors = vendors;
        _vendorsByRegion = vendorsByRegion;
        _isLoading = false;
      });

      print('✅ VendorsListScreen: Vendeurs chargés: ${_vendors.length}');
    } catch (e) {
      print('❌ VendorsListScreen: Erreur: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMapData() async {
    setState(() {
      _isMapLoading = true;
      _mapError = '';
    });

    try {
      print('🔄 VendorsListScreen: Chargement des données de la carte...');

      // Récupérer la position de l'utilisateur
      final position = await VendorMapService.getCurrentLocation();

      if (position != null) {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
      }

      // Récupérer les vendeurs avec positions
      final vendorLocations = await VendorMapService.getVendorsWithLocation();

      setState(() {
        _vendorLocations = vendorLocations;
        _isMapLoading = false;
      });

      print(
        '✅ VendorsListScreen: Données carte chargées: ${_vendorLocations.length} vendeurs',
      );
    } catch (e) {
      print('❌ VendorsListScreen: Erreur carte: $e');
      setState(() {
        _mapError = 'Erreur lors du chargement de la carte: $e';
        _isMapLoading = false;
      });
    }
  }

  List<Vendor> get _filteredVendors {
    if (_selectedRegion == 'Toutes les régions') {
      return _vendors;
    }
    return _vendorsByRegion[_selectedRegion] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Nos Vendeurs',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF488950),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadVendors,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Liste'),
            Tab(icon: Icon(Icons.map), text: 'Carte'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF488950)),
            )
          : TabBarView(
              controller: _tabController,
              children: [_buildListView(), _buildMapView()],
            ),
    );
  }

  Widget _buildListView() {
    return Column(
      children: [
        _buildRegionFilter(),
        Expanded(
          child: _filteredVendors.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredVendors.length,
                  itemBuilder: (context, index) {
                    final vendor = _filteredVendors[index];
                    return _buildVendorCard(vendor);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRegionFilter() {
    final regions = ['Toutes les régions', ..._vendorsByRegion.keys.toList()];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRegion,
          isExpanded: true,
          items: regions.map((region) {
            return DropdownMenuItem<String>(
              value: region,
              child: Text(
                region,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedRegion = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildVendorCard(Vendor vendor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF488950).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.store, color: Color(0xFF488950), size: 24),
        ),
        title: Text(
          vendor.businessName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${vendor.city}, ${vendor.region}',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: vendor.status == 'active'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    vendor.status == 'active' ? 'Ouvert' : 'Fermé',
                    style: TextStyle(
                      color: vendor.status == 'active'
                          ? Colors.green
                          : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [_buildVendorDetails(vendor)],
      ),
    );
  }

  Widget _buildVendorDetails(Vendor vendor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        _buildDetailRow(
          icon: Icons.location_on,
          label: 'Adresse',
          value: vendor.businessAddress,
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          icon: Icons.phone,
          label: 'Téléphone',
          value: vendor.phoneNumber,
          onTap: () => _callVendor(vendor.phoneNumber),
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          icon: Icons.map,
          label: 'Coordonnées',
          value: vendor.latitude != null && vendor.longitude != null
              ? '${vendor.latitude!.toStringAsFixed(4)}, ${vendor.longitude!.toStringAsFixed(4)}'
              : 'Non disponibles',
          onTap: vendor.latitude != null && vendor.longitude != null
              ? () => _openInMaps(vendor.latitude!, vendor.longitude!)
              : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _callVendor(vendor.phoneNumber),
                icon: const Icon(Icons.phone, size: 18),
                label: const Text('Appeler'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF488950),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: vendor.latitude != null && vendor.longitude != null
                    ? () => _openInMaps(vendor.latitude!, vendor.longitude!)
                    : null,
                icon: const Icon(Icons.directions, size: 18),
                label: const Text('Itinéraire'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF488950),
                  side: const BorderSide(color: Color(0xFF488950)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _selectedRegion == 'Toutes les régions'
                ? 'Aucun vendeur disponible'
                : 'Aucun vendeur dans cette région',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Veuillez réessayer plus tard',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadVendors,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF488950),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    if (_isMapLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF488950)),
            SizedBox(height: 16),
            Text('Chargement de la carte...'),
          ],
        ),
      );
    }

    if (_mapError.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _mapError,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMapData,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_vendorLocations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.store_mall_directory,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun vendeur avec position GPS trouvé',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMapData,
              child: const Text('Actualiser'),
            ),
          ],
        ),
      );
    }

    // Afficher la carte interactive
    return VendorMapWidget(
      vendors: _vendorLocations,
      userLatitude: _userLatitude,
      userLongitude: _userLongitude,
    );
  }

  Future<void> _callVendor(String phoneNumber) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

      // Vérifier si l'URL peut être lancée
      if (await canLaunchUrl(phoneUri)) {
        // Essayer de lancer l'appel
        final launched = await launchUrl(
          phoneUri,
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

  Future<void> _openInMaps(double latitude, double longitude) async {
    final Uri mapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir l\'application de cartes'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
