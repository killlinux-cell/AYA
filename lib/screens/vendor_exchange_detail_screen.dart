import 'package:flutter/material.dart';
import '../config/fonts.dart';
import '../constants/exchange_catalog.dart';
import '../services/pdf_receipt_service.dart';
import '../services/vendor_auth_service.dart';
import '../services/vendor_exchange_history_service.dart';

class VendorExchangeDetailScreen extends StatefulWidget {
  final VendorExchange exchange;

  const VendorExchangeDetailScreen({
    super.key,
    required this.exchange,
  });

  @override
  State<VendorExchangeDetailScreen> createState() =>
      _VendorExchangeDetailScreenState();
}

class _VendorExchangeDetailScreenState
    extends State<VendorExchangeDetailScreen> {
  final PDFReceiptService _pdfService = PDFReceiptService();
  final VendorAuthService _vendorAuthService = VendorAuthService();
  bool _isGenerating = false;

  Map<String, dynamic> get _exchangeMap => {
        'id': widget.exchange.id,
        'points': widget.exchange.points,
        'exchange_code': widget.exchange.exchangeCode,
        'status': widget.exchange.status,
        'created_at': widget.exchange.createdAt.toIso8601String(),
        'approved_at': widget.exchange.approvedAt?.toIso8601String(),
        'completed_at': widget.exchange.completedAt?.toIso8601String(),
        'notes': widget.exchange.notes,
      };

  Future<void> _runPdfAction(Future<void> Function() action) async {
    final vendorInfo = _vendorAuthService.vendorInfo;
    if (vendorInfo == null) {
      _showMessage('Informations vendeur non disponibles', isError: true);
      return;
    }

    setState(() => _isGenerating = true);
    try {
      await action();
    } catch (e) {
      _showMessage('Erreur : $e', isError: true);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _previewReceipt() async {
    final vendorInfo = _vendorAuthService.vendorInfo!;
    await _runPdfAction(() => _pdfService.generateExchangeReceipt(
          exchangeRequest: _exchangeMap,
          vendorInfo: vendorInfo,
          clientName: widget.exchange.userName,
          clientEmail: widget.exchange.userEmail,
        ));
  }

  Future<void> _saveReceipt() async {
    await _runPdfAction(() async {
      final vendorInfo = _vendorAuthService.vendorInfo!;
      await _pdfService.saveExchangeReceipt(
        exchangeRequest: _exchangeMap,
        vendorInfo: vendorInfo,
        clientName: widget.exchange.userName,
        clientEmail: widget.exchange.userEmail,
      );
      _showMessage('Facture enregistrée');
    });
  }

  Future<void> _shareReceipt() async {
    final vendorInfo = _vendorAuthService.vendorInfo!;
    await _runPdfAction(() => _pdfService.shareExchangeReceipt(
          exchangeRequest: _exchangeMap,
          vendorInfo: vendorInfo,
          clientName: widget.exchange.userName,
          clientEmail: widget.exchange.userEmail,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final exchange = widget.exchange;
    final reward = getRewardForPoints(exchange.points);
    final vendorName =
        _vendorAuthService.vendorInfo?['business_name'] ?? 'Vendeur';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Détail de la transaction',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF488950),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusBanner(),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Client',
              icon: Icons.person,
              children: [
                _buildRow('Nom', exchange.userName),
                _buildRow('Email', exchange.userEmail),
              ],
            ),
            const SizedBox(height: 12),
            _buildSection(
              title: 'Échange',
              icon: Icons.swap_horiz,
              children: [
                _buildRow('Points échangés', '${exchange.points} pts'),
                if (reward != null) _buildRow('Récompense', reward),
                _buildRow('Code', exchange.exchangeCode),
                _buildRow(
                  'Date',
                  '${exchange.formattedDate} à ${exchange.formattedTime}',
                ),
                if (exchange.approvedAt != null)
                  _buildRow(
                    'Validé le',
                    '${exchange.approvedAt!.day.toString().padLeft(2, '0')}/'
                        '${exchange.approvedAt!.month.toString().padLeft(2, '0')}/'
                        '${exchange.approvedAt!.year} à '
                        '${exchange.approvedAt!.hour.toString().padLeft(2, '0')}:'
                        '${exchange.approvedAt!.minute.toString().padLeft(2, '0')}',
                  ),
                if (exchange.notes.isNotEmpty)
                  _buildRow('Notes', exchange.notes),
              ],
            ),
            const SizedBox(height: 12),
            _buildSection(
              title: 'Vendeur',
              icon: Icons.store,
              children: [
                _buildRow('Point de vente', vendorName),
                _buildRow('Réf. transaction', exchange.id),
              ],
            ),
            const SizedBox(height: 24),
            if (_isGenerating)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton.icon(
                onPressed: _previewReceipt,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Voir la facture'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF488950),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _saveReceipt,
                icon: const Icon(Icons.save_alt),
                label: const Text('Enregistrer la facture'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF488950),
                  side: const BorderSide(color: Color(0xFF488950)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _shareReceipt,
                icon: const Icon(Icons.share),
                label: const Text('Partager la facture'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF488950),
                  side: const BorderSide(color: Color(0xFF488950)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF488950), Color(0xFF60A066)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction terminée',
                  style: TextStyle(
                    fontFamily: AppFonts.helvetica,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.exchange.points} points échangés',
                  style: TextStyle(
                    fontFamily: AppFonts.helveticaNow,
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF488950)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppFonts.helvetica,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.helveticaNow,
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: AppFonts.helvetica,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
