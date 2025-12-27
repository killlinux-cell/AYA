import 'package:flutter/material.dart';
import 'dart:math' as math;

class SpinWheelWidget extends StatefulWidget {
  final List<WheelSection> sections;
  final Function(int) onSpinComplete;
  final bool isSpinning;

  const SpinWheelWidget({
    Key? key,
    required this.sections,
    required this.onSpinComplete,
    this.isSpinning = false,
  }) : super(key: key);

  @override
  State<SpinWheelWidget> createState() => SpinWheelWidgetState();
}

class SpinWheelWidgetState extends State<SpinWheelWidget>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  double _currentRotation = 0.0;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _spinAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _spinController, curve: Curves.easeOut));

    _spinController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onSpinComplete();
      }
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _onSpinComplete() {
    setState(() {
      _isSpinning = false;
    });

    // Calculer la section gagnante
    final double normalizedRotation = _currentRotation % (2 * math.pi);
    final double sectionAngle = (2 * math.pi) / widget.sections.length;
    final int winningIndex =
        ((2 * math.pi - normalizedRotation) / sectionAngle).floor() %
        widget.sections.length;

    widget.onSpinComplete(winningIndex);
  }

  void spin() {
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
    });

    // Rotation aléatoire entre 5 et 8 tours complets
    final double randomRotation =
        (5 + math.Random().nextDouble() * 3) * 2 * math.pi;
    _currentRotation += randomRotation;

    _spinAnimation = Tween<double>(
      begin: _currentRotation - randomRotation,
      end: _currentRotation,
    ).animate(CurvedAnimation(parent: _spinController, curve: Curves.easeOut));

    _spinController.reset();
    _spinController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Roue
          AnimatedBuilder(
            animation: _spinAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _spinAnimation.value,
                child: CustomPaint(
                  size: const Size(300, 300),
                  painter: WheelPainter(widget.sections),
                ),
              );
            },
          ),

          // Centre de la roue
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(Icons.circle, color: Color(0xFF488950), size: 30),
          ),

          // Pointeur fixe
          Positioned(
            top: 10,
            child: Container(
              width: 0,
              height: 0,
              child: CustomPaint(
                size: const Size(20, 20),
                painter: PointerPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<WheelSection> sections;

  WheelPainter(this.sections);

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.width / 2;

    final double sectionAngle = (2 * math.pi) / sections.length;

    for (int i = 0; i < sections.length; i++) {
      final double startAngle = i * sectionAngle;

      // Dessiner la section
      final Paint sectionPaint = Paint()
        ..color = sections[i].color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        startAngle,
        sectionAngle,
        true,
        sectionPaint,
      );

      // Dessiner le texte
      final double textAngle = startAngle + sectionAngle / 2;
      final double textRadius = radius * 0.7;
      final double textX = centerX + textRadius * math.cos(textAngle);
      final double textY = centerY + textRadius * math.sin(textAngle);

      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: sections[i].text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
      );
    }

    // Bordure de la roue
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(Offset(centerX, centerY), radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final Path path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WheelSection {
  final String text;
  final Color color;
  final int points;

  WheelSection({required this.text, required this.color, required this.points});
}
