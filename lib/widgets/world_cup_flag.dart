import 'package:flutter/material.dart';
import '../utils/country_flags.dart';

class WorldCupFlag extends StatelessWidget {
  final String? countryCode;
  final double width;
  final double height;
  final bool circular;

  const WorldCupFlag({
    super.key,
    required this.countryCode,
    this.width = 36,
    this.height = 26,
    this.circular = false,
  });

  @override
  Widget build(BuildContext context) {
    final url = countryFlagUrl(countryCode, width: width.round());
    final emoji = countryFlagEmoji(countryCode);
    final radius = circular ? width / 2 : 4.0;

    if (url == null) {
      return _fallbackBox(emoji, radius);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _fallbackBox(emoji, radius, loading: true);
        },
        errorBuilder: (_, __, ___) => _fallbackBox(emoji, radius),
      ),
    );
  }

  Widget _fallbackBox(String? emoji, double radius, {bool loading = false}) {
    if (emoji != null && !loading) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Center(
          child: Text(emoji, style: TextStyle(fontSize: height * 0.55)),
        ),
      );
    }
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: loading
          ? const Padding(
              padding: EdgeInsets.all(4),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.flag, size: width * 0.45, color: Colors.grey.shade500),
    );
  }
}
