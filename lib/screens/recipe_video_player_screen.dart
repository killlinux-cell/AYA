import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../services/recipe_service.dart';
import '../theme/app_colors.dart';

class RecipeVideoPlayerScreen extends StatefulWidget {
  final RecipeVideoItem recipe;

  const RecipeVideoPlayerScreen({super.key, required this.recipe});

  @override
  State<RecipeVideoPlayerScreen> createState() =>
      _RecipeVideoPlayerScreenState();
}

class _RecipeVideoPlayerScreenState extends State<RecipeVideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    RecipeService().incrementView(widget.recipe.id);
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/aya_recipe_${widget.recipe.id}.mp4');
      if (!await file.exists() || await file.length() == 0) {
        final response = await http
            .get(Uri.parse(widget.recipe.videoUrl))
            .timeout(const Duration(seconds: 90));
        if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
          throw Exception('Téléchargement impossible');
        }
        await file.writeAsBytes(response.bodyBytes, flush: true);
      }

      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de lire la vidéo';
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.recipe.title),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Center(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const CircularProgressIndicator(color: AppColors.primaryGreen);
    }
    if (_error != null || _controller == null) {
      return Text(
        _error ?? 'Erreur',
        style: const TextStyle(color: Colors.white),
      );
    }

    final size = _controller!.value.size;
    final ratio = (size.width > 0 && size.height > 0)
        ? size.width / size.height
        : 16 / 9;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AspectRatio(
          aspectRatio: ratio,
          child: VideoPlayer(_controller!),
        ),
        const SizedBox(height: 16),
        IconButton(
          iconSize: 48,
          color: Colors.white,
          onPressed: () {
            setState(() {
              if (_controller!.value.isPlaying) {
                _controller!.pause();
              } else {
                _controller!.play();
              }
            });
          },
          icon: Icon(
            _controller!.value.isPlaying
                ? Icons.pause_circle
                : Icons.play_circle,
          ),
        ),
        if (widget.recipe.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Text(
              widget.recipe.description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
          ),
      ],
    );
  }
}
