import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/grand_prix_service.dart';
import '../services/django_auth_service.dart';
import '../services/loading_service.dart';
import '../theme/app_colors.dart';

class BonusSectionWidget extends StatefulWidget {
  const BonusSectionWidget({super.key});

  @override
  State<BonusSectionWidget> createState() => _BonusSectionWidgetState();

  // Méthode statique pour rafraîchir depuis l'extérieur
  static void refresh(BuildContext context) {
    final state = context.findAncestorStateOfType<_BonusSectionWidgetState>();
    state?.refreshGrandPrix();
  }
}

class _BonusSectionWidgetState extends State<BonusSectionWidget> {
  bool _isLoadingGrandPrix = false;
  bool _hasGrandPrix = false;
  bool _hasParticipated = false;
  String? _participationDate;
  bool _isDrawPassed = false;
  bool _isWinner = false;
  String? _prizeWon;

  // Méthode publique pour rafraîchir depuis l'extérieur
  void refreshGrandPrix() {
    print(
      '🔍 BonusSectionWidget: refreshGrandPrix() appelé depuis l\'extérieur',
    );
    _refreshGrandPrixData();
  }

  // Méthode helper pour naviguer de manière sécurisée
  void _safePop() {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  // Méthode helper pour afficher un dialog de manière sécurisée
  void _safeShowDialog(Widget dialog) {
    if (mounted) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => dialog,
        );
      } catch (e) {
        print('❌ _safeShowDialog: Erreur lors de l\'affichage du dialog: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    print('🔍 BonusSectionWidget: initState() appelé');
    // Attendre que l'authentification soit prête avant de vérifier
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshGrandPrixData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('🔍 BonusSectionWidget: didChangeDependencies() appelé');
    // Rafraîchir les données du grand prix quand l'utilisateur revient
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshGrandPrixData();
    });
  }

  Future<void> _refreshGrandPrixData() async {
    print('🔍 BonusSectionWidget: _refreshGrandPrixData() appelé');
    // Attendre un peu pour que l'authentification soit prête
    await Future.delayed(const Duration(milliseconds: 1000));
    _checkGrandPrixAvailability();
  }

  Future<void> _checkGrandPrixAvailability() async {
    setState(() {
      _isLoadingGrandPrix = true;
    });

    // Afficher le chargement global
    LoadingService.instance.showApiLoading(
      context: context,
      message: 'Vérification du Grand Prix...',
    );

    try {
      final authService = DjangoAuthService.instance;

      // Vérifier si l'utilisateur est authentifié
      if (authService.accessToken == null) {
        print('❌ Utilisateur non authentifié');
        setState(() {
          _hasGrandPrix = false;
          _isLoadingGrandPrix = false;
        });
        LoadingService.instance.hideLoading();
        return;
      }

      final grandPrixService = GrandPrixService(authService);
      print(
        '🔍 _checkGrandPrixAvailability: Appel de getCurrentGrandPrix()...',
      );
      final grandPrix = await grandPrixService.getCurrentGrandPrix();
      print('🔍 _checkGrandPrixAvailability: getCurrentGrandPrix() terminé');

      // Vérifier si l'utilisateur a déjà participé et les résultats
      bool hasParticipated = false;
      String? participationDate;
      bool isDrawPassed = false;
      bool isWinner = false;
      String? prizeWon;

      if (grandPrix != null && grandPrix.isActive) {
        try {
          final participations = await grandPrixService.getUserParticipations();
          hasParticipated = participations.any(
            (participation) => participation.grandPrixName == grandPrix.name,
          );
          if (hasParticipated) {
            final participation = participations.firstWhere(
              (participation) => participation.grandPrixName == grandPrix.name,
            );
            participationDate = participation.participatedAt.toString();
            isWinner = participation.isWinner;
            prizeWon = participation.prizeWon?.name;
          }

          // Vérifier si la date du tirage est passée
          isDrawPassed = DateTime.now().isAfter(grandPrix.drawDate);

          print(
            '🔍 _checkGrandPrixAvailability: Participation vérifiée - hasParticipated: $hasParticipated, isDrawPassed: $isDrawPassed, isWinner: $isWinner',
          );
        } catch (e) {
          print('⚠️ Erreur lors de la vérification de la participation: $e');
        }
      }

      setState(() {
        // Vérifier si le grand prix existe ET est actif
        _hasGrandPrix = grandPrix != null && grandPrix.isActive;
        _hasParticipated = hasParticipated;
        _participationDate = participationDate;
        _isDrawPassed = isDrawPassed;
        _isWinner = isWinner;
        _prizeWon = prizeWon;
        _isLoadingGrandPrix = false;

        // Logs de débogage détaillés
        print('🔍 _checkGrandPrixAvailability:');
        print('   - grandPrix != null: ${grandPrix != null}');
        if (grandPrix != null) {
          print('   - grandPrix.name: ${grandPrix.name}');
          print('   - grandPrix.isActive: ${grandPrix.isActive}');
          print('   - grandPrix.startDate: ${grandPrix.startDate}');
          print('   - grandPrix.endDate: ${grandPrix.endDate}');
          print(
            '   - grandPrix.participationCost: ${grandPrix.participationCost}',
          );
        } else {
          print(
            '   - grandPrix est null - Aucun grand prix retourné par l\'API',
          );
        }
        print('   - _hasGrandPrix: $_hasGrandPrix');
        print('   - _hasParticipated: $_hasParticipated');
        print('   - _participationDate: $_participationDate');
        print(
          '   - Résultat final: ${grandPrix != null ? "Grand prix trouvé" : "Aucun grand prix"} ${grandPrix != null && grandPrix.isActive ? "et actif" : "mais inactif ou null"} ${hasParticipated ? "et déjà participé" : "et pas encore participé"}',
        );
      });

      // Masquer le chargement
      LoadingService.instance.hideLoading();
    } catch (e) {
      print('❌ Erreur lors de la vérification du grand prix: $e');
      setState(() {
        _hasGrandPrix = false;
        _isLoadingGrandPrix = false;
      });

      // Masquer le chargement en cas d'erreur
      LoadingService.instance.hideLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userPoints = authProvider.currentUser?.availablePoints ?? 0;
        final hasEnoughPoints = userPoints >= 100;

        return _buildBonusSection(context, userPoints, hasEnoughPoints);
      },
    );
  }

  Widget _buildBonusSection(
    BuildContext context,
    int userPoints,
    bool hasEnoughPoints,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasEnoughPoints
              ? [AppColors.primaryGreen, AppColors.primaryGreenLight]
              : [AppColors.accentRed, AppColors.accentRedLight],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                (hasEnoughPoints
                        ? AppColors.primaryGreen
                        : AppColors.accentRed)
                    .withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  hasEnoughPoints ? Icons.star : Icons.card_giftcard,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasEnoughPoints ? 'Bonus VIP' : 'Bonus spécial',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      hasEnoughPoints
                          ? 'Félicitations ! Vous êtes VIP'
                          : 'Offres limitées !',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              // Bouton de rafraîchissement
              IconButton(
                onPressed: () {
                  print('🔄 Rafraîchissement manuel du grand prix');
                  _refreshGrandPrixData();
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Rafraîchir',
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Affichage des points actuels
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Vos points:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$userPoints pts',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Contenu conditionnel selon les points
          if (hasEnoughPoints) ...[
            // Bonus VIP disponibles
            _buildVipBonus(context),
          ] else ...[
            // Message d'encouragement
            _buildEncouragementMessage(context, userPoints),
          ],
        ],
      ),
    );
  }

  Widget _buildVipBonus(BuildContext context) {
    return Column(
      children: [
        // Carte du grand prix VIP
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Color(0xFF488950),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grand prix VIP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Défi accepté ! Collectez 100 points et tentez de remporter le trésor !',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'VIP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF488950),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Autres bonus VIP
        _buildBonusItem(
          icon: Icons.local_offer,
          title: 'Réduction exclusive 20%',
          description: 'Sur tous vos échanges',
          color: Colors.white,
        ),

        const SizedBox(height: 8),

        _buildBonusItem(
          icon: Icons.card_giftcard,
          title: 'Cadeau surprise',
          description: 'À chaque 50 points supplémentaires',
          color: Colors.white,
        ),

        const SizedBox(height: 8),

        _buildBonusItem(
          icon: Icons.priority_high,
          title: 'Priorité VIP',
          description: 'Service client prioritaire',
          color: Colors.white,
        ),

        const SizedBox(height: 16),

        // Boutons d'action VIP
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _showVipBenefits(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Mes avantages',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildGrandPrixButton(context, true)),
          ],
        ),
      ],
    );
  }

  /// Construit le bouton du grand prix selon l'état
  Widget _buildGrandPrixButton(BuildContext context, bool hasEnoughPoints) {
    // Utiliser le paramètre hasEnoughPoints passé en argument
    final enoughPoints = hasEnoughPoints;

    // Logs de débogage détaillés
    print('🔍 _buildGrandPrixButton:');
    print('   - _isLoadingGrandPrix: $_isLoadingGrandPrix');
    print('   - _hasGrandPrix: $_hasGrandPrix');
    print('   - _hasParticipated: $_hasParticipated');
    print('   - _isDrawPassed: $_isDrawPassed');
    print('   - _isWinner: $_isWinner');
    print('   - hasEnoughPoints: $hasEnoughPoints');
    print('   - enoughPoints: $enoughPoints');
    print('   - Condition 1 (!_isLoadingGrandPrix): ${!_isLoadingGrandPrix}');
    print('   - Condition 2 (!_hasGrandPrix): ${!_hasGrandPrix}');
    print('   - Condition 3 (!enoughPoints): ${!enoughPoints}');
    print('   - Condition 4 (_hasParticipated): $_hasParticipated');
    print('   - Condition 5 (_isDrawPassed): $_isDrawPassed');
    if (_isLoadingGrandPrix) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Chargement...',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    if (!_hasGrandPrix) {
      return ElevatedButton(
        onPressed: () {
          _showNoGrandPrixDialog(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.withOpacity(0.7),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Aucun grand prix',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (_hasParticipated) {
      // Si l'utilisateur a participé, afficher l'état approprié selon le tirage
      if (_isDrawPassed) {
        if (_isWinner) {
          // Gagnant !
          return ElevatedButton(
            onPressed: () {
              _showWinnerDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700), // Or
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, size: 16),
                SizedBox(width: 8),
                Text(
                  'Félicitations ! Vous avez gagné !',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        } else {
          // Pas gagnant mais tirage fait
          return ElevatedButton(
            onPressed: () {
              _showDrawResultsDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.withOpacity(0.7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 16),
                SizedBox(width: 8),
                Text(
                  'Tirage terminé',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }
      } else {
        // Participation en cours, tirage pas encore fait
        return ElevatedButton(
          onPressed: () {
            _showAlreadyParticipatedDialog(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF488950).withOpacity(0.8),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 16),
              SizedBox(width: 8),
              Text(
                'Déjà participé',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }
    }

    if (!enoughPoints) {
      return ElevatedButton(
        onPressed: () {
          _showInsufficientPointsDialog(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.withOpacity(0.8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Points insuffisants',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ElevatedButton(
      onPressed: () {
        _participateInGrandPrix(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF488950),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        'Je veux le trésor !',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEncouragementMessage(BuildContext context, int userPoints) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: AppColors.accentRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Devenez VIP !',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Défi accepté ! Collectez 100 points et tentez de remporter le trésor !',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Barre de progression
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progression VIP',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${userPoints}/100',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: userPoints / 100,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Bouton d'action
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              _showHowToEarnPoints(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFa93236),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Comment gagner des points',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBonusItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showVipBenefits(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.star, color: Color(0xFF488950)),
              SizedBox(width: 8),
              Text('Avantages VIP'),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBenefitItem(
                  icon: Icons.local_offer,
                  title: 'Réduction exclusive 20%',
                  description: 'Sur tous vos échanges de points',
                ),
                _buildBenefitItem(
                  icon: Icons.card_giftcard,
                  title: 'Cadeau surprise',
                  description: 'À chaque 50 points supplémentaires gagnés',
                ),
                _buildBenefitItem(
                  icon: Icons.priority_high,
                  title: 'Service prioritaire',
                  description: 'Support client en priorité',
                ),
                _buildBenefitItem(
                  icon: Icons.emoji_events,
                  title: 'Grand prix VIP',
                  description: 'Participation aux concours exclusifs',
                ),
                _buildBenefitItem(
                  icon: Icons.notifications_active,
                  title: 'Notifications exclusives',
                  description: 'Offres spéciales en avant-première',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  void _showHowToEarnPoints(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.trending_up, color: Color(0xFFa93236)),
              SizedBox(width: 8),
              Text('Comment gagner des points', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEarningMethod(
                  icon: Icons.qr_code_scanner,
                  title: 'Scanner des QR codes',
                  description: 'Gagnez 10-50 points par scan',
                  points: '+10 à +50 pts',
                ),
                _buildEarningMethod(
                  icon: Icons.games,
                  title: 'Jouer aux jeux',
                  description: 'Gagnez des points en jouant',
                  points: '+5 à +20 pts',
                ),
                _buildEarningMethod(
                  icon: Icons.store,
                  title: 'Échanger avec les vendeurs',
                  description: 'Utilisez vos points chez nos partenaires',
                  points: 'Variable',
                ),
                _buildEarningMethod(
                  icon: Icons.card_giftcard,
                  title: 'Bonus quotidiens',
                  description: 'Connectez-vous chaque jour',
                  points: '+5 pts/jour',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  /// Fonctionnalité de participation au grand prix VIP
  void _participateInGrandPrix(BuildContext context) async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Récupérer les informations du grand prix depuis l'API
      final grandPrixInfo = await _getCurrentGrandPrix();

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      if (grandPrixInfo == null) {
        _showErrorDialog(context, 'Aucun grand prix actif actuellement');
        return;
      }

      _showGrandPrixDialog(context, grandPrixInfo);
    } catch (e) {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      _showErrorDialog(context, 'Erreur lors du chargement du grand prix: $e');
    }
  }

  Future<Map<String, dynamic>?> _getCurrentGrandPrix() async {
    try {
      // Utiliser le service réel pour récupérer le grand prix
      final authService = DjangoAuthService.instance;
      final grandPrixService = GrandPrixService(authService);

      final grandPrix = await grandPrixService.getCurrentGrandPrix();

      if (grandPrix == null) {
        print('ℹ️ Aucun grand prix actif actuellement');
        return null;
      }

      // Convertir le GrandPrix en Map pour la compatibilité avec l'interface existante
      return {
        'id': grandPrix.id,
        'name': grandPrix.name,
        'description': grandPrix.description,
        'participation_cost': grandPrix.participationCost,
        'has_participated': grandPrix.hasParticipated,
        'start_date': grandPrix.startDate.toIso8601String(),
        'end_date': grandPrix.endDate.toIso8601String(),
        'draw_date': grandPrix.drawDate.toIso8601String(),
        'is_active': grandPrix.isActive,
        'is_upcoming': grandPrix.isUpcoming,
        'is_finished': grandPrix.isFinished,
        'prizes': grandPrix.prizes
            .map(
              (prize) => {
                'position': prize.position,
                'name': prize.name,
                'description': prize.description,
                'value': prize.value,
              },
            )
            .toList(),
      };
    } catch (e) {
      print('❌ Erreur lors de la récupération du grand prix: $e');
      return null;
    }
  }

  void _showGrandPrixDialog(
    BuildContext context,
    Map<String, dynamic> grandPrixInfo,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.emoji_events, color: Color(0xFF488950)),
                  SizedBox(width: 8),
                  Text('Grand Prix VIP'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Description du grand prix
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF488950).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF488950).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🏆 ${grandPrixInfo['name']}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF488950),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            grandPrixInfo['description'],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Coût de participation
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Coût de participation : ${grandPrixInfo['participation_cost']} pts',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Récompenses
                    const Text(
                      'Récompenses du mois :',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...(grandPrixInfo['prizes'] as List).map(
                      (prize) => _buildPrizeItem(
                        position:
                            '${prize['position']}${prize['position'] == 1 ? 'er' : 'ème'}',
                        prize: prize['name'],
                        description: 'Valeur : ${prize['value']}€',
                        color: prize['position'] == 1
                            ? Colors.amber
                            : prize['position'] == 2
                            ? Colors.grey
                            : Colors.orange,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Règles
                    const Text(
                      'Règles du concours :',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Seuls les membres VIP (100+ points) peuvent participer\n'
                      '• 1 participation par mois\n'
                      '• Le tirage au sort a lieu le dernier jour du mois\n'
                      '• Les gagnants sont notifiés par email\n'
                      '• Les récompenses sont envoyées sous 7 jours',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),

                    const SizedBox(height: 16),

                    // Statut de participation
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: grandPrixInfo['has_participated']
                            ? Colors.red.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            grandPrixInfo['has_participated']
                                ? Icons.check_circle
                                : Icons.info,
                            color: grandPrixInfo['has_participated']
                                ? Colors.red
                                : Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              grandPrixInfo['has_participated']
                                  ? 'Vous avez déjà participé à ce grand prix'
                                  : 'Vous n\'avez pas encore participé ce mois-ci',
                              style: TextStyle(
                                fontSize: 12,
                                color: grandPrixInfo['has_participated']
                                    ? Colors.red
                                    : Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                if (!grandPrixInfo['has_participated'])
                  ElevatedButton(
                    onPressed: () {
                      _confirmParticipation(context, grandPrixInfo);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF488950),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Participer maintenant'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPrizeItem({
    required String position,
    required String prize,
    required String description,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                position,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prize,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmParticipation(
    BuildContext context,
    Map<String, dynamic> grandPrixInfo,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF488950)),
              SizedBox(width: 8),
              Text('Confirmer la participation'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Êtes-vous sûr de vouloir participer au ${grandPrixInfo['name']} ?',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Coût : ${grandPrixInfo['participation_cost']} points',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Vous ne pourrez participer qu\'une seule fois ce mois-ci.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Fermer la confirmation
                await _processParticipation(context, grandPrixInfo);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF488950),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processParticipation(
    BuildContext context,
    Map<String, dynamic> grandPrixInfo,
  ) async {
    print('🎯 _processParticipation: Début de la participation');

    try {
      // Afficher un indicateur de chargement
      _safeShowDialog(const Center(child: CircularProgressIndicator()));
      print('🔄 _processParticipation: Dialog de chargement affiché');

      // Utiliser le service réel pour participer au grand prix
      final authService = DjangoAuthService.instance;
      final grandPrixService = GrandPrixService(authService);

      print('🔄 _processParticipation: Appel de participateInGrandPrix()...');
      final result = await grandPrixService.participateInGrandPrix();
      print(
        '✅ _processParticipation: participateInGrandPrix() terminé - Success: ${result.success}',
      );

      // Vérifier si le widget est encore monté
      if (!mounted) {
        print(
          '⚠️ _processParticipation: Widget désactivé, arrêt du traitement',
        );
        return;
      }

      // Fermer l'indicateur de chargement
      _safePop();
      print('🔄 _processParticipation: Dialog de chargement fermé');

      if (result.success) {
        print('✅ _processParticipation: Participation réussie');

        // Fermer le dialog du grand prix
        _safePop();
        print('🔄 _processParticipation: Dialog du grand prix fermé');

        // Mettre à jour les points de l'utilisateur
        if (result.userPoints != null) {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          authProvider.updateUserPoints(result.userPoints!);
          print(
            '🔄 _processParticipation: Points utilisateur mis à jour: ${result.userPoints}',
          );
        }

        // Marquer la participation localement
        setState(() {
          _hasParticipated = true;
          _participationDate = DateTime.now().toIso8601String();
        });
        print('🔄 _processParticipation: Participation marquée localement');

        // Rafraîchir les données du grand prix
        _refreshGrandPrixData();
        print('🔄 _processParticipation: Données du grand prix rafraîchies');

        // Afficher le message de succès et revenir au home
        _showParticipationSuccessAndReturnHome(context, grandPrixInfo);
        print('✅ _processParticipation: Dialog de succès affiché');
      } else {
        print(
          '❌ _processParticipation: Erreur de participation: ${result.error}',
        );
        _showErrorDialog(
          context,
          result.error ?? 'Erreur lors de la participation',
        );
      }
    } catch (e) {
      print('❌ _processParticipation: Exception: $e');

      if (!mounted) {
        print(
          '⚠️ _processParticipation: Widget désactivé après erreur, arrêt du traitement',
        );
        return;
      }

      // Fermer l'indicateur de chargement
      _safePop();
      print(
        '🔄 _processParticipation: Dialog de chargement fermé après erreur',
      );

      _showErrorDialog(context, 'Erreur lors de la participation: $e');
    }
  }

  void _showParticipationSuccessAndReturnHome(
    BuildContext context,
    Map<String, dynamic> grandPrixInfo,
  ) {
    print(
      '🎉 _showParticipationSuccessAndReturnHome: Affichage du dialog de succès',
    );

    // Vérifier si le widget est encore monté
    if (!mounted) {
      print(
        '⚠️ _showParticipationSuccessAndReturnHome: Widget désactivé, arrêt de l\'affichage',
      );
      return;
    }

    _safeShowDialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Color(0xFF488950)),
            SizedBox(width: 8),
            Text('Participation confirmée !'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Félicitations ! Vous participez maintenant au ${grandPrixInfo['name']}.',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${grandPrixInfo['participation_cost']} points débités',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Le tirage au sort aura lieu le dernier jour du mois. Les gagnants seront notifiés par email.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              print(
                '🎉 _showParticipationSuccessAndReturnHome: Bouton "Parfait !" cliqué',
              );
              _safePop();
              print(
                '🎉 _showParticipationSuccessAndReturnHome: Dialog fermé, retour au home',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF488950),
              foregroundColor: Colors.white,
            ),
            child: const Text('Parfait !'),
          ),
        ],
      ),
    );
  }

  void _showAlreadyParticipatedDialog(BuildContext context) {
    if (!mounted) {
      print(
        '⚠️ _showAlreadyParticipatedDialog: Widget désactivé, arrêt de l\'affichage',
      );
      return;
    }

    _safeShowDialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF488950)),
            SizedBox(width: 8),
            Text('Déjà participé'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Vous avez déjà participé à ce Grand Prix !',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (_participationDate != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF488950).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      color: Color(0xFF488950),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Participation le ${_formatDate(_participationDate!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF488950),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Le tirage au sort aura lieu le dernier jour du mois. Les gagnants seront notifiés par email.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => _safePop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF488950),
              foregroundColor: Colors.white,
            ),
            child: const Text('Parfait !'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  void _showWinnerDialog(BuildContext context) {
    if (!mounted) {
      print('⚠️ _showWinnerDialog: Widget désactivé, arrêt de l\'affichage');
      return;
    }

    _safeShowDialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Color(0xFFFFD700)),
            SizedBox(width: 8),
            Text('Félicitations !'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎉 Vous avez gagné au Grand Prix !',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_prizeWon != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD700), width: 2),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.card_giftcard,
                      color: Color(0xFFFFD700),
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _prizeWon!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD700),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'Vous serez contacté par email pour recevoir votre prix dans les 7 jours ouvrés.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => _safePop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            child: const Text('Génial !'),
          ),
        ],
      ),
    );
  }

  void _showDrawResultsDialog(BuildContext context) {
    if (!mounted) {
      print(
        '⚠️ _showDrawResultsDialog: Widget désactivé, arrêt de l\'affichage',
      );
      return;
    }

    _safeShowDialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Tirage terminé'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Le tirage au sort a eu lieu.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.grey, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Malheureusement, vous n\'avez pas gagné cette fois. Bonne chance pour le prochain Grand Prix !',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Les gagnants ont été notifiés par email.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => _safePop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('D\'accord'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    if (!mounted) {
      print('⚠️ _showErrorDialog: Widget désactivé, arrêt de l\'affichage');
      return;
    }

    _safeShowDialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Erreur'),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => _safePop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Dialog pour informer qu'il n'y a pas de grand prix actif
  void _showNoGrandPrixDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(width: 8),
              Text('Aucun grand prix actif'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Il n\'y a actuellement aucun grand prix en cours.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Les grands prix sont organisés périodiquement. Revenez bientôt pour participer aux prochains concours !',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF488950),
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Dialog pour informer que les points sont insuffisants
  void _showInsufficientPointsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Points insuffisants'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Vous devez avoir au moins 100 points pour participer aux grands prix.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Scannez des QR codes pour gagner des points et revenez participer !',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF488950),
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class _buildBenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _buildBenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF488950), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _buildEarningMethod extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String points;

  const _buildEarningMethod({
    required this.icon,
    required this.title,
    required this.description,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFa93236), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFa93236).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              points,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFFa93236),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
