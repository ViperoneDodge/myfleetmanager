import 'package:flutter/material.dart';

import '../theme.dart';

/// Schermata di benvenuto animata mostrata all'apertura dell'app.
/// La schermata di avvio nativa è solo blu: il logo compare qui con un'animazione
/// (evita il doppio logo sovrapposto che si vedeva su alcuni telefoni).
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
    final appear = CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.25, curve: Curves.easeOut));
    final pop = CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack));
    final text = CurvedAnimation(parent: _c, curve: const Interval(0.35, 0.75, curve: Curves.easeOut));
    final road = CurvedAnimation(parent: _c, curve: const Interval(0.45, 1.0, curve: Curves.easeInOut));
    return Scaffold(
      backgroundColor: const Color(0xFF0257C3),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0257C3), Color(0xFF0257C3), Color(0xFF01357F)],
            stops: [0, 0.45, 1],
          ),
        ),
        // SafeArea + colonna: logo, testo e strada non possono sovrapporsi
        // né finire sotto notch / barra di navigazione, su nessun telefono.
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              return LayoutBuilder(builder: (context, box) {
                final w = box.maxWidth;
                final iconSize = (box.maxHeight * 0.2).clamp(80.0, 140.0).toDouble();
                return Column(children: [
                  const Spacer(flex: 3),
                  Opacity(
                    opacity: appear.value.clamp(0.0, 1.0).toDouble(),
                    child: Transform.scale(
                      scale: 0.7 + 0.3 * pop.value,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(iconSize * 0.23),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35 * appear.value),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(iconSize * 0.23),
                          child: Image.asset('assets/icon.png', width: iconSize, height: iconSize),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Opacity(
                    opacity: text.value.clamp(0.0, 1.0).toDouble(),
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - text.value)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(mainAxisSize: MainAxisSize.min, children: const [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('MyFleetManager',
                                maxLines: 1,
                                style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5)),
                          ),
                          SizedBox(height: 6),
                          Text('Il taccuino delle scadenze dei tuoi veicoli',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontFamily: handFont, fontSize: 22, color: Colors.white70)),
                        ]),
                      ),
                    ),
                  ),
                  const Spacer(flex: 4),
                  // Strada con veicolo che la percorre
                  Opacity(
                    opacity: road.value.clamp(0.0, 1.0).toDouble(),
                    child: SizedBox(
                      height: 40,
                      width: w,
                      child: Stack(children: [
                        Positioned(
                          left: 40,
                          right: 40,
                          bottom: 6,
                          child: CustomPaint(
                              size: const Size(double.infinity, 4), painter: _RoadPainter()),
                        ),
                        Positioned(
                          left: 30 + (w - 100) * road.value,
                          bottom: 8,
                          child: const Icon(Icons.directions_car, color: Colors.white, size: 30),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 32),
                ]);
              });
            },
          ),
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
