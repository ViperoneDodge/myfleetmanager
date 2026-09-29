import 'package:flutter/material.dart';

import '../theme.dart';

/// Schermata di benvenuto animata mostrata all'apertura dell'app.
/// Parte identica alla schermata di avvio nativa (sfondo blu + icona al centro)
/// così il passaggio è continuo.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lift = CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack));
    final text = CurvedAnimation(parent: _c, curve: const Interval(0.35, 0.75, curve: Curves.easeOut));
    final road = CurvedAnimation(parent: _c, curve: const Interval(0.45, 1.0, curve: Curves.easeInOut));
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0257C3), Color(0xFF0257C3), Color(0xFF01357F)],
            stops: [0, 0.45, 1],
          ),
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return LayoutBuilder(builder: (context, box) {
              final w = box.maxWidth;
              return Stack(children: [
                // Icona: parte al centro (come lo splash nativo) e sale leggermente
                Align(
                  alignment: Alignment(0, -0.18 * lift.value),
                  child: Transform.scale(
                    scale: 1 + 0.12 * lift.value,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35 * lift.value),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Image.asset('assets/icon.png', width: 140, height: 140),
                      ),
                    ),
                  ),
                ),
                // Titolo e sottotitolo
                Align(
                  alignment: const Alignment(0, 0.32),
                  child: Opacity(
                    opacity: text.value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - text.value)),
                      child: const Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('MyFleetManager',
                            style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5)),
                        SizedBox(height: 6),
                        Text('Il taccuino delle scadenze dei tuoi veicoli',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: handFont, fontSize: 22, color: Colors.white70)),
                      ]),
                    ),
                  ),
                ),
                // Strada con veicolo che la percorre
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 70,
                  child: Opacity(
                    opacity: road.value.clamp(0.0, 1.0).toDouble(),
                    child: SizedBox(
                      height: 40,
                      child: Stack(children: [
                        Positioned(
                          left: 40,
                          right: 40,
                          bottom: 6,
                          child: CustomPaint(size: const Size(double.infinity, 4), painter: _RoadPainter()),
                        ),
                        Positioned(
                          left: 30 + (w - 100) * road.value,
                          bottom: 8,
                          child: const Icon(Icons.directions_car, color: Colors.white, size: 30),
                        ),
                      ]),
                    ),
                  ),
                ),
              ]);
            });
          },
        ),
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white38
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var x = 0.0; x < size.width; x += 22) {
      canvas.drawLine(Offset(x, size.height / 2), Offset(x + 12, size.height / 2), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
