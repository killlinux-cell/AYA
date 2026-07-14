import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../services/advertisement_service.dart';
import '../services/django_auth_service.dart';

class ApiVideoWidget extends StatefulWidget {
  const ApiVideoWidget({super.key});

  @override
  State<ApiVideoWidget> createState() => _ApiVideoWidgetState();

  /// Rafraîchir les vidéos depuis l'extérieur (pull-to-refresh accueil).
  static void refresh(BuildContext context) {
    context.findAncestorStateOfType<_ApiVideoWidgetState>()?.reloadAds();
  }
}

class _ApiVideoWidgetState extends State<ApiVideoWidget> {
  final AdvertisementService _adService = AdvertisementService(
    DjangoAuthService.instance,
  );

  List<Advertisement> _advertisements = [];
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLoading = true;
  bool _useGifFallback = false;
  String? _gifUrl;
  Timer? _rotationTimer;

  @override
  void initState() {
    super.initState();
    _loadAdvertisements();
  }

  Future<void> reloadAds() async {
    _rotationTimer?.cancel();
    await _disposeController();
    setState(() {
      _advertisements = [];
      _isInitialized = false;
      _isLoading = true;
      _useGifFallback = false;
      _gifUrl = null;
    });
    await _loadAdvertisements();
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  Future<void> _loadAdvertisements() async {
    try {
      final ads = await _adService.getActiveAdvertisements();

      if (ads.isEmpty) {
        print('⚠️ Aucune publicité active disponible');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isInitialized = false;
          });
        }
        return;
      }

      ads.sort((a, b) => b.priority.compareTo(a.priority));

      if (mounted) {
        setState(() {
          _advertisements = ads;
          // Garder le loader jusqu'à ce que la vidéo / GIF soit prête
          _isLoading = true;
          _isInitialized = false;
        });
      }

      await _initializeMedia();
    } catch (e) {
      print('❌ Erreur chargement publicités: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialized = false;
        });
      }
    }
  }

  bool _isGifUrl(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
    return path.endsWith('.gif') || path.contains('.gif?');
  }

  Future<File> _cacheVideoLocally(Advertisement ad) async {
    final dir = await getTemporaryDirectory();
    final safeName = ad.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('${dir.path}/aya_ad_$safeName.mp4');

    // Réutiliser le cache local s'il existe déjà
    if (await file.exists() && await file.length() > 0) {
      print('🎬 Cache vidéo trouvé: ${file.path}');
      return file;
    }

    print('⬇️ Téléchargement vidéo pub: ${ad.videoUrl}');
    final response = await http
        .get(Uri.parse(ad.videoUrl))
        .timeout(const Duration(seconds: 90));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode} pour la vidéo');
    }
    if (response.bodyBytes.isEmpty) {
      throw Exception('Fichier vidéo vide');
    }

    await file.writeAsBytes(response.bodyBytes, flush: true);
    print('✅ Vidéo mise en cache (${response.bodyBytes.length} octets)');
    return file;
  }

  Future<void> _initializeMedia() async {
    if (_advertisements.isEmpty) return;

    try {
      final ad = _selectRandomAd();
      print('🎬 Chargement pub: ${ad.title} (${ad.videoUrl})');
      _adService.incrementView(ad.id);

      // GIF : lecture native Flutter (boucle)
      if (_isGifUrl(ad.videoUrl)) {
        await _disposeController();
        if (!mounted) return;
        setState(() {
          _useGifFallback = true;
          _gifUrl = ad.videoUrl;
          _isInitialized = true;
          _isLoading = false;
        });
        _scheduleRotation(ad.duration);
        return;
      }

      // MP4 / vidéo : cache local pour contourner l'absence d'Accept-Ranges
      final file = await _cacheVideoLocally(ad);

      await _disposeController();
      _controller = VideoPlayerController.file(file);

      _controller!.addListener(() {
        if (_controller?.value.hasError == true) {
          print(
            '❌ Erreur vidéo détectée: ${_controller!.value.errorDescription}',
          );
          if (mounted) {
            setState(() {
              _isInitialized = false;
              _isLoading = false;
            });
          }
        }
      });

      await _controller!.initialize().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception('Timeout lors de l\'initialisation vidéo');
        },
      );

      if (!mounted) return;

      await _controller!.setLooping(false);
      await _controller!.setVolume(0.0);
      await _controller!.play();

      setState(() {
        _useGifFallback = false;
        _gifUrl = null;
        _isInitialized = true;
        _isLoading = false;
      });

      _scheduleRotation(ad.duration);
      print('✅ Vidéo initialisée: ${ad.title}');
    } catch (e) {
      print('❌ Erreur initialisation média: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _isLoading = false;
        });
      }
    }
  }

  void _scheduleRotation(int durationSeconds) {
    _rotationTimer?.cancel();
    final seconds = durationSeconds <= 0 ? 8 : durationSeconds;
    _rotationTimer = Timer(Duration(seconds: seconds), () {
      if (!mounted) return;
      if (_advertisements.length > 1) {
        _initializeMedia();
      } else if (_controller != null && _controller!.value.isInitialized) {
        _controller!.seekTo(Duration.zero);
        _controller!.play();
        _scheduleRotation(seconds);
      } else if (_useGifFallback) {
        _scheduleRotation(seconds);
      }
    });
  }

  Advertisement _selectRandomAd() {
    final random = Random();
    final totalPriority = _advertisements.fold(
      0,
      (sum, ad) => sum + ad.priority + 1,
    );

    var randomValue = random.nextInt(totalPriority);
    var cumulativePriority = 0;

    for (final ad in _advertisements) {
      cumulativePriority += ad.priority + 1;
      if (randomValue < cumulativePriority) {
        return ad;
      }
    }

    return _advertisements[0];
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF488950),
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_advertisements.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_useGifFallback && _gifUrl != null) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            _gifUrl!,
            fit: BoxFit.contain,
            width: double.infinity,
            errorBuilder: (_, __, ___) => _buildFallbackImage(),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const SizedBox(
                height: 120,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF488950),
                    strokeWidth: 2,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return _buildFallbackImage();
    }

    final videoSize = _controller!.value.size;
    final aspectRatio = (videoSize.width > 0 && videoSize.height > 0)
        ? videoSize.width / videoSize.height
        : 16 / 9;

    // Affiche la vidéo dans ses proportions d'origine (sans étirement).
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF488950), Color(0xFF60A066)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 48,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 8),
            Text(
              'Publicité Aya+',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
