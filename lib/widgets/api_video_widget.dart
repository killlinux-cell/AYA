import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'dart:math';
import '../services/advertisement_service.dart';
import '../services/django_auth_service.dart';

class ApiVideoWidget extends StatefulWidget {
  const ApiVideoWidget({super.key});

  @override
  State<ApiVideoWidget> createState() => _ApiVideoWidgetState();
}

class _ApiVideoWidgetState extends State<ApiVideoWidget> {
  final AdvertisementService _adService = AdvertisementService(
    DjangoAuthService.instance,
  );
  
  List<Advertisement> _advertisements = [];
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLoading = true;
  int _currentAdIndex = 0;
  Timer? _rotationTimer;

  @override
  void initState() {
    super.initState();
    _loadAdvertisements();
  }

  Future<void> _loadAdvertisements() async {
    try {
      final ads = await _adService.getActiveAdvertisements();
      
      if (ads.isEmpty) {
        print('⚠️ Aucune publicité active disponible');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Trier par priorité
      ads.sort((a, b) => b.priority.compareTo(a.priority));

      setState(() {
        _advertisements = ads;
        _isLoading = false;
      });

      // Initialiser la première vidéo
      _initializeVideo();
    } catch (e) {
      print('❌ Erreur chargement publicités: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeVideo() async {
    if (_advertisements.isEmpty) return;

    try {
      // Sélectionner une vidéo aléatoire (avec poids de priorité)
      final ad = _selectRandomAd();
      
      print('🎬 Chargement vidéo: ${ad.title} (${ad.videoUrl})');

      // Incrémenter le compteur de vues
      _adService.incrementView(ad.id);

      // Initialiser le lecteur vidéo
      _controller?.dispose();
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(ad.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          allowBackgroundPlayback: false,
          mixWithOthers: false,
        ),
      );

      // Ajouter un listener d'erreur
      _controller!.addListener(() {
        if (_controller!.value.hasError) {
          print('❌ Erreur vidéo détectée: ${_controller!.value.errorDescription}');
          if (mounted) {
            setState(() {
              _isInitialized = false;
            });
          }
        }
      });

      // Timeout de 10 secondes pour l'initialisation
      await _controller!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout lors du chargement de la vidéo');
        },
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Configurer la vidéo
        _controller!.setLooping(false); // ✅ Pas de boucle pour permettre la rotation
        _controller!.setVolume(0.0); // Muet
        _controller!.play();

        // Programmer le changement de vidéo après la durée configurée
        _rotationTimer?.cancel();
        _rotationTimer = Timer(
          Duration(seconds: ad.duration),
          () {
            if (mounted) {
              if (_advertisements.length > 1) {
                _nextVideo(); // Passer à la vidéo suivante
              } else {
                // Si une seule vidéo, la rejouer
                _controller!.seekTo(Duration.zero);
                _controller!.play();
              }
            }
          },
        );

        print('✅ Vidéo initialisée: ${ad.title}');
        print('🔄 Rotation dans ${ad.duration} secondes');
      }
    } catch (e) {
      print('❌ Erreur initialisation vidéo: $e');
      print('⚠️ Fallback vers affichage statique');
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  Advertisement _selectRandomAd() {
    // Sélection pondérée par priorité
    final random = Random();
    final totalPriority = _advertisements.fold(0, (sum, ad) => sum + ad.priority + 1);
    
    int randomValue = random.nextInt(totalPriority);
    int cumulativePriority = 0;
    
    for (var ad in _advertisements) {
      cumulativePriority += ad.priority + 1;
      if (randomValue < cumulativePriority) {
        return ad;
      }
    }
    
    return _advertisements[0];
  }

  void _nextVideo() {
    print('🔄 Changement de vidéo...');
    _initializeVideo(); // Sélectionne une nouvelle vidéo aléatoirement
  }

  @override
  void dispose() {
    _controller?.dispose();
    _rotationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink(); // Masquer pendant le chargement
    }

    // Si aucune publicité ou erreur vidéo, afficher image fallback
    if (_advertisements.isEmpty || !_isInitialized || _controller == null) {
      return _buildFallbackImage();
    }

    return Container(
      margin: const EdgeInsets.only(top: 20),
      height: 200, // Hauteur fixe
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: FittedBox(
            fit: BoxFit.cover, // Remplit sans étirer
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/images/advertisement.jpg',
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF488950),
                    const Color(0xFF60A066),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_library_outlined,
                      size: 48,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Publicité Aya+',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

