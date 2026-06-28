import 'package:flutter/material.dart';
import '../utils/country_flags.dart';

class WorldCupFlag extends StatelessWidget {
  final String? countryCode;
  final double width;
  final double height;

  const WorldCupFlag({
    super.key,
    required this.countryCode,
    this.width = 36,
    this.height = 26,
  });

  @override
  Widget build(BuildContext context) {
    final url = countryFlagUrl(countryCode, width: width.round());

    if (url == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(Icons.flag, size: width * 0.45, color: Colors.grey.shade500),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: Icon(Icons.flag, size: width * 0.45, color: Colors.grey),
        ),
      ),
    );
  }
}
