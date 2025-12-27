import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/vendor_service.dart';
import '../services/django_auth_service.dart';
import '../config/fonts.dart';
import '../screens/vendors_list_screen.dart';

class VendorsCardWidget extends StatefulWidget {
  const VendorsCardWidget({Key? key}) : super(key: key);

  @override
  State<VendorsCardWidget> createState() => _VendorsCardWidgetState();
}

class _VendorsCardWidgetState extends State<VendorsCardWidget> {
  final VendorService _vendorService = VendorService(
    DjangoAuthService.instance,
  );
  List<Vendor> _vendors = [];
  bool _isLoading = true;
  String _selectedRegion = 'Toutes les régions';
  Map<String, List<Vendor>> _vendorsByRegion = {};

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    try {
      print('🔄 VendorsCardWidget: Chargement des vendeurs...');

      final vendors = await _vendorService.getAvailableVendors();
      final vendorsByRegion = await _vendorService.getVendorsByRegion();

      print('📊 VendorsCardWidget: Vendeurs reçus: ${vendors.length}');
      print('🗺️ VendorsCardWidget: Régions: ${vendorsByRegion.keys.toList()}');

      setState(() {
        _vendors = vendors;
        _vendorsByRegion = vendorsByRegion;
        _isLoading = false;
      });

      print(
        '✅ VendorsCardWidget: État mis à jour - Vendeurs: ${_vendors.length}, Régions: ${_vendorsByRegion.length}',
      );
    } catch (e) {
      print('❌ VendorsCardWidget: Erreur lors du chargement: $e');
      setState(() {
        _isLoading = false;
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
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFa93236), Color(0xFFC54A4E)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.store, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vendeurs Partenaires',
                        style: TextStyle(
                          fontFamily: AppFonts.helvetica,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Trouvez un vendeur près de chez vous',
                        style: TextStyle(
                          fontFamily: AppFonts.helveticaNow,
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                // Bouton de carte
                IconButton(
                  onPressed: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (context) => const VendorsListScreen(),
                          ),
                        )
                        .then((_) {
                          // Optionnel: forcer l'ouverture de l'onglet carte
                          // Vous pouvez ajouter une logique ici si nécessaire
                        });
                  },
                  icon: const Icon(Icons.map, color: Colors.white, size: 20),
                  tooltip: 'Voir sur la carte',
                ),
                // Bouton de rafraîchissement
                IconButton(
                  onPressed: _loadVendors,
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: 'Actualiser',
                ),
                if (_vendors.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_filteredVendors.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Filtre par région
          if (_vendorsByRegion.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtrer par région',
                    style: TextStyle(
                      fontFamily: AppFonts.helveticaNow,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildRegionChip('Toutes les régions'),
                        const SizedBox(width: 8),
                        ..._vendorsByRegion.keys.map(
                          (region) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildRegionChip(region),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],

          // Liste des vendeurs
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFa93236),
                        ),
                      ),
                    ),
                  )
                : _filteredVendors.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.store_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Aucun vendeur disponible',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredVendors.length,
                    itemBuilder: (context, index) {
                      final vendor = _filteredVendors[index];
                      return _buildVendorItem(vendor);
                    },
                  ),
          ),

          // Bouton "Voir tous"
          if (_filteredVendors.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const VendorsListScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF488950),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Voir tous les vendeurs'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRegionChip(String region) {
    final isSelected = _selectedRegion == region;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRegion = region;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFa93236) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFa93236) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          region,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildVendorItem(Vendor vendor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Icône du vendeur
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: vendor.isActive
                  ? const Color(0xFF488950).withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.store,
              color: vendor.isActive ? const Color(0xFF488950) : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Informations du vendeur
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vendor.businessName,
                  style: const TextStyle(
                    fontFamily: AppFonts.helvetica,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  vendor.location,
                  style: TextStyle(
                    fontFamily: AppFonts.helveticaNow,
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (vendor.businessAddress.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    vendor.businessAddress,
                    style: TextStyle(
                      fontFamily: AppFonts.helveticaNow,
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Statut
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: vendor.isActive
                      ? const Color(0xFF488950).withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  vendor.isActive ? 'Ouvert' : 'Fermé',
                  style: TextStyle(
                    fontFamily: AppFonts.helveticaNow,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: vendor.isActive
                        ? const Color(0xFF488950)
                        : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Bouton d'appel
              if (vendor.phoneNumber.isNotEmpty)
                GestureDetector(
                  onTap: () => _callVendor(vendor.phoneNumber),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF488950).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.phone,
                      color: Color(0xFF488950),
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
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
}
