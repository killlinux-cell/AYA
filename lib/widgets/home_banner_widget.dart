import 'package:flutter/material.dart';
import '../services/advertisement_service.dart';
import '../services/django_auth_service.dart';
import '../theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeBannerWidget extends StatefulWidget {
  const HomeBannerWidget({super.key});

  @override
  State<HomeBannerWidget> createState() => _HomeBannerWidgetState();
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

  Future<void> _loadBanner() async {
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _placeholder();
    }

    if (_banner == null || _banner!.imageUrl == null) {
      return _placeholder();
    }

    final hasLink =
        _banner!.buttonUrl != null && _banner!.buttonUrl!.isNotEmpty;

    return InkWell(
      onTap: hasLink ? () => _openLink(_banner!.buttonUrl!) : null,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              _banner!.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _placeholder(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _placeholder();
              },
            ),
          ),
          if (_banner!.title != null || _banner!.subtitle != null)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.bottomLeft,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.0),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_banner!.title != null)
                    Text(
                      _banner!.title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (_banner!.subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _banner!.subtitle!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  if (_banner!.buttonText != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _banner!.buttonText!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Image.asset(
      'assets/images/advertisement.jpg',
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return const SizedBox(height: 180);
      },
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
