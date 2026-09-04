import 'package:flutter/material.dart';
import '../constants/exchange_catalog.dart';

class UserExchangeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> exchange;

  const UserExchangeDetailScreen({super.key, required this.exchange});

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} à '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final points = (exchange['points'] as num?)?.toInt() ?? 0;
    final reward = exchange['reward'] as String? ?? getRewardForPoints(points);
    final isCompleted =
        exchange['is_completed'] == true || exchange['completed_at'] != null;
    final statusLabel = exchange['status_display'] as String? ??
        (isCompleted ? 'Complété' : 'En attente');
    final vendorName = exchange['vendor_name'] as String?;
    final vendorCode = exchange['vendor_code'] as String?;
    final notes = (exchange['notes'] as String?)?.trim();
    final code = exchange['exchange_code'] as String? ?? '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Détail de l\'échange'),
        backgroundColor: const Color(0xFF488950),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF488950).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$points points',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF488950),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (reward != null) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Récompense',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.card_giftcard,
                        color: Color(0xFF488950),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          reward,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _infoCard(
            title: 'Informations',
            rows: [
              _row('Code échange', code),
              _row(
                'Créé le',
                _formatDate(exchange['created_at']?.toString()),
              ),
              if (exchange['approved_at'] != null)
                _row(
                  'Validé le',
                  _formatDate(exchange['approved_at']?.toString()),
                ),
              if (exchange['completed_at'] != null)
                _row(
                  'Complété le',
                  _formatDate(exchange['completed_at']?.toString()),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _infoCard(
            title: 'Vendeur',
            rows: [
              _row(
                'Point de vente',
                (vendorName != null && vendorName.isNotEmpty)
                    ? vendorName
                    : (isCompleted ? 'Non renseigné' : 'En attente de validation'),
              ),
              if (vendorCode != null && vendorCode.isNotEmpty)
                _row('Code vendeur', vendorCode),
            ],
          ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            _infoCard(
              title: 'Notes',
              rows: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    notes,
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoCard({required String title, required List<Widget> rows}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF212121),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
