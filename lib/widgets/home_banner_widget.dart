import 'package:flutter/material.dart';
import '../services/advertisement_service.dart';
import '../services/django_auth_service.dart';
import '../theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeBannerWidget extends StatefulWidget {
  const HomeBannerWidget({super.key});

  @override
  State<HomeBannerWidget> createState() => _HomeBannerWidgetState();

  /// Rafraîchir la bannière depuis l'extérieur (pull-to-refresh accueil).
  static void refresh(BuildContext context) {
    context
        .findAncestorStateOfType<_HomeBannerWidgetState>()
        ?.reloadBanner();
  }
}

class _HomeBannerWidgetState extends State<HomeBannerWidget> {
  final AdvertisementService _adService = AdvertisementService(
    DjangoAuthService.instance,
  );

  HomeBannerData? _banner;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  Future<void> reloadBanner() => _loadBanner();

  Future<void> _loadBanner() async {
    setState(() => _isLoading = true);
    final banner = await _adService.getHomeBanner();
    if (!mounted) return;

    setState(() {
      _banner = banner;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _loadingPlaceholder();
    }

    if (_banner == null) {
      return _defaultPlaceholder();
    }

    final imageUrl = _banner!.imageUrlWithCacheBust;
    if (imageUrl == null || imageUrl.isEmpty) {
      return _textBanner(_banner!);
    }

    final hasLink =
        _banner!.buttonUrl != null && _banner!.buttonUrl!.isNotEmpty;

    return InkWell(
      onTap: hasLink ? () => _openLink(_banner!.buttonUrl!) : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('❌ Erreur chargement bannière: $error');
              return _textBanner(_banner!);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _loadingPlaceholder();
            },
          ),
          if (_banner!.title != null ||
              _banner!.subtitle != null ||
              _banner!.buttonText != null)
            _overlayText(_banner!),
        ],
      ),
    );
  }

  Widget _overlayText(HomeBannerData banner) {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.bottomLeft,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.6),
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (banner.title != null && banner.title!.isNotEmpty)
            Text(
              banner.title!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (banner.subtitle != null && banner.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              banner.subtitle!,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
          if (banner.buttonText != null && banner.buttonText!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                banner.buttonText!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _textBanner(HomeBannerData banner) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4332), Color(0xFF40916C)],
        ),
      ),
      child: _overlayText(banner),
    );
  }

  Widget _loadingPlaceholder() {
    return Container(
      color: const Color(0xFFE8F5E9),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryGreen,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _defaultPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF488950), Color(0xFF60A066)],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, color: Colors.white, size: 40),
            SizedBox(height: 8),
            Text(
              'Mon univers AYA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('❌ Impossible d\'ouvrir le lien de la bannière: $e');
    }
  }
}
