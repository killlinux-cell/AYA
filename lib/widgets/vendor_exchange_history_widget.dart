import 'package:flutter/material.dart';
import '../services/vendor_exchange_history_service.dart';
import '../services/django_auth_service.dart';
import '../services/pdf_receipt_service.dart';
import '../services/vendor_auth_service.dart';
import '../config/fonts.dart';

class VendorExchangeHistoryWidget extends StatefulWidget {
  const VendorExchangeHistoryWidget({Key? key}) : super(key: key);

  @override
  State<VendorExchangeHistoryWidget> createState() =>
      _VendorExchangeHistoryWidgetState();
}

// Extension pour permettre l'accès à la méthode de rafraîchissement
extension VendorExchangeHistoryWidgetExtension
    on State<VendorExchangeHistoryWidget> {
  void refreshHistory() {
    if (this is _VendorExchangeHistoryWidgetState) {
      (this as _VendorExchangeHistoryWidgetState).refreshHistory();
    }
  }
}

class _VendorExchangeHistoryWidgetState
    extends State<VendorExchangeHistoryWidget> {
  final VendorExchangeHistoryService _historyService =
      VendorExchangeHistoryService(DjangoAuthService.instance);
  final PDFReceiptService _pdfService = PDFReceiptService();
  final VendorAuthService _vendorAuthService = VendorAuthService();
  List<VendorExchange> _exchanges = [];
  List<VendorExchange> _pendingTokens = [];
  VendorExchangeStats? _stats;
  bool _isLoading = true;
  bool _isExporting = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadExchangeHistory();
  }

  @override
  void didUpdateWidget(VendorExchangeHistoryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Rafraîchir l'historique quand le widget est mis à jour
    if (oldWidget.key != widget.key) {
      _loadExchangeHistory();
    }
  }

  // Méthode publique pour rafraîchir l'historique depuis l'extérieur
  void refreshHistory() {
    _loadExchangeHistory();
  }

  Future<void> _loadExchangeHistory() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      print('🔄 Chargement de l\'historique des échanges...');
      final exchanges = await _historyService.getExchangeHistory();
      final pendingTokens = await _historyService.getPendingTokens();
      final stats = await _historyService.getExchangeStats();

      print('📊 Échanges chargés: ${exchanges.length}');
      print('📋 Tokens en attente: ${pendingTokens.length}');
      print(
        '📈 Statistiques: ${stats.totalExchanges} échanges, ${stats.totalPoints} points',
      );

      if (mounted) {
        setState(() {
          _exchanges = exchanges;
          _pendingTokens = pendingTokens;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur lors du chargement de l\'historique: $e');
      if (mounted) {
        setState(() {
          _error = 'Erreur lors du chargement: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Historique des Échanges',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF488950),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExchangeHistory,
          ),
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.picture_as_pdf),
            onPressed: _isExporting ? null : _exportToPDF,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadExchangeHistory,
        color: const Color(0xFF488950),
        child: Column(
          children: [
            // Statistiques
            if (_stats != null) _buildStatsCard(),

            // Tokens en attente
            if (_pendingTokens.isNotEmpty) _buildPendingTokensSection(),

            // Liste des échanges
            Expanded(
              child: _isLoading
                  ? _buildLoadingWidget()
                  : _error.isNotEmpty
                  ? _buildErrorWidget()
                  : _exchanges.isEmpty
                  ? _buildEmptyWidget()
                  : _buildExchangesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF488950), Color(0xFF60A066)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF488950).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Statistiques des Échanges',
            style: TextStyle(
              fontFamily: AppFonts.helvetica,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total',
                  '${_stats!.totalExchanges}',
                  Icons.swap_horiz,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Points',
                  '${_stats!.totalPoints}',
                  Icons.stars,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Aujourd\'hui',
                  '${_stats!.todayExchanges}',
                  Icons.today,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Cette semaine',
                  '${_stats!.thisWeekExchanges}',
                  Icons.calendar_view_week,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppFonts.helvetica,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.helveticaNow,
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF488950)),
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement de l\'historique...',
            style: TextStyle(
              fontFamily: AppFonts.helvetica,
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontFamily: AppFonts.helvetica,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error,
            style: TextStyle(
              fontFamily: AppFonts.helveticaNow,
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadExchangeHistory,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF488950),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.swap_horiz_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun échange trouvé',
            style: TextStyle(
              fontFamily: AppFonts.helvetica,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les échanges validés apparaîtront ici',
            style: TextStyle(
              fontFamily: AppFonts.helveticaNow,
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _exchanges.length,
      itemBuilder: (context, index) {
        final exchange = _exchanges[index];
        return _buildExchangeCard(exchange);
      },
    );
  }

  /// Exporter l'historique en PDF
  Future<void> _exportToPDF() async {
    if (_exchanges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun échange à exporter'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isExporting = true;
      });
    }

    try {
      final vendorInfo = _vendorAuthService.vendorInfo;
      if (vendorInfo == null) {
        throw Exception('Informations vendeur non disponibles');
      }

      final statsMap = {
        'totalExchanges': _stats?.totalExchanges ?? 0,
        'totalPoints': _stats?.totalPoints ?? 0,
        'todayExchanges': _stats?.todayExchanges ?? 0,
        'thisWeekExchanges': _stats?.thisWeekExchanges ?? 0,
      };

      await _pdfService.generateExchangeHistoryPDF(
        exchanges: _exchanges,
        stats: statsMap,
        vendorInfo: vendorInfo,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF généré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur lors de l\'export PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Widget _buildExchangeCard(VendorExchange exchange) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec points et statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF488950).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${exchange.points} points',
                    style: TextStyle(
                      fontFamily: AppFonts.helvetica,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF488950),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Complété',
                    style: TextStyle(
                      fontFamily: AppFonts.helveticaNow,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Informations client
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exchange.userName,
                    style: TextStyle(
                      fontFamily: AppFonts.helvetica,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Row(
              children: [
                Icon(Icons.email, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exchange.userEmail,
                    style: TextStyle(
                      fontFamily: AppFonts.helveticaNow,
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Code d'échange et date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Code d\'échange',
                      style: TextStyle(
                        fontFamily: AppFonts.helveticaNow,
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      exchange.exchangeCode,
                      style: TextStyle(
                        fontFamily: AppFonts.helvetica,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Date',
                      style: TextStyle(
                        fontFamily: AppFonts.helveticaNow,
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      '${exchange.formattedDate} ${exchange.formattedTime}',
                      style: TextStyle(
                        fontFamily: AppFonts.helvetica,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
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

  Widget _buildPendingTokensSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pending_actions,
                color: Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Tokens en attente de validation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_pendingTokens.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ces tokens d\'échange attendent d\'être validés par un vendeur. '
            'Scannez les QR codes pour valider les échanges.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          // Afficher les 3 premiers tokens en attente
          ...(_pendingTokens
              .take(3)
              .map(
                (token) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              token.userName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${token.points} points - ${token.exchangeCode}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${token.createdAt.day}/${token.createdAt.month}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList()),
          if (_pendingTokens.length > 3)
            Text(
              '+ ${_pendingTokens.length - 3} autres tokens en attente',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}
