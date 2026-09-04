import 'package:flutter/material.dart';
import '../services/django_exchange_service.dart';
import '../services/django_auth_service.dart';
import '../constants/exchange_catalog.dart';
import 'user_exchange_detail_screen.dart';

class UserExchangeHistoryScreen extends StatefulWidget {
  const UserExchangeHistoryScreen({super.key});

  @override
  State<UserExchangeHistoryScreen> createState() =>
      _UserExchangeHistoryScreenState();
}

class _UserExchangeHistoryScreenState extends State<UserExchangeHistoryScreen> {
  final DjangoExchangeService _exchangeService =
      DjangoExchangeService(DjangoAuthService.instance);

  List<Map<String, dynamic>> _exchanges = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadExchanges();
  }

  Future<void> _loadExchanges() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final userId = DjangoAuthService.instance.currentUser?.id ?? '0';
      final exchanges = await _exchangeService.getUserExchangeHistoryWithAuth(
        userId.toString(),
      );

      if (mounted) {
        setState(() {
          _exchanges = exchanges;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur lors du chargement: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Mes Échanges',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF488950),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExchanges,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadExchanges,
        color: const Color(0xFF488950),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF488950)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Chargement de vos échanges...',
                      style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
                    ),
                  ],
                ),
              )
            : _error.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur de chargement',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadExchanges,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Réessayer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF488950),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _exchanges.isEmpty
                    ? Center(
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
                              'Aucun échange pour le moment',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Vos échanges de points apparaîtront ici\naprès validation par un vendeur',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _exchanges.length,
                        itemBuilder: (context, index) {
                          final exchange = _exchanges[index];
                          return _buildExchangeCard(exchange);
                        },
                      ),
      ),
    );
  }

  Widget _buildExchangeCard(Map<String, dynamic> exchange) {
    final points = (exchange['points'] as num?)?.toInt() ?? 0;
    final reward =
        exchange['reward'] as String? ?? getRewardForPoints(points);
    final createdAt = exchange['created_at'] ?? exchange['completed_at'];
    final isCompleted =
        exchange['is_completed'] == true || exchange['completed_at'] != null;
    final vendorName = exchange['vendor_name'] as String?;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UserExchangeDetailScreen(exchange: exchange),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF488950).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$points points',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF488950),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isCompleted ? 'Complété' : 'En attente',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ],
                ),
              ],
            ),
            if (reward != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.card_giftcard,
                    size: 20,
                    color: Color(0xFF488950),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Récompense gagnée',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reward,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF488950),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (vendorName != null && vendorName.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.store, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vendorName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  _formatDate(createdAt?.toString()),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Voir le détail',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }
}
