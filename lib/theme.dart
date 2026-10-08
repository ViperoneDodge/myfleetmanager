import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n.dart';

enum PaperStyle { righe, quadretti, puntini, liscio }

String paperStyleLabel(PaperStyle p) {
  switch (p) {
    case PaperStyle.righe:
      return tr('paper.lines');
    case PaperStyle.quadretti:
      return tr('paper.grid');
    case PaperStyle.puntini:
      return tr('paper.dots');
    case PaperStyle.liscio:
      return tr('paper.plain');
  }
}

class AppPalette {
  final String key;
  final Color seed;
  const AppPalette(this.key, this.seed);

  String get name => tr('palette.$key');
}

const List<AppPalette> palettes = [
  AppPalette('blue', Color(0xFF0257C3)),
  AppPalette('forest', Color(0xFF2E7D32)),
  AppPalette('racing', Color(0xFFC62828)),
  AppPalette('orange', Color(0xFFEF6C00)),
  AppPalette('petrol', Color(0xFF00796B)),
  AppPalette('violet', Color(0xFF6A1B9A)),
  AppPalette('graphite', Color(0xFF455A64)),
  AppPalette('leather', Color(0xFF795548)),
];

class ThemeSettings {
  ThemeMode mode;
  int palette;
  PaperStyle paper;

  ThemeSettings({this.mode = ThemeMode.system, this.palette = 0, this.paper = PaperStyle.righe});

  AppPalette get pal => palettes[palette.clamp(0, palettes.length - 1).toInt()];

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'palette': palette,
        'paper': paper.name,
      };

  factory ThemeSettings.fromJson(Map<String, dynamic>? j) {
    if (j == null) return ThemeSettings();
    ThemeMode mode = ThemeMode.system;
    for (final m in ThemeMode.values) {
      if (m.name == j['mode']) mode = m;
    }
    PaperStyle paper = PaperStyle.righe;
    for (final p in PaperStyle.values) {
      if (p.name == j['paper']) paper = p;
    }
    return ThemeSettings(
      mode: mode,
      palette: (j['palette'] as num?)?.toInt() ?? 0,
      paper: paper,
    );
  }
}

class NotebookColors extends ThemeExtension<NotebookColors> {
  final Color cover;
  final Color onCover;
  final Color paper;
  final Color line;
  final Color margin;
  final Color hole;
  final Color ringLight;
  final Color ringDark;
  final PaperStyle style;

  const NotebookColors({
    required this.cover,
    required this.onCover,
    required this.paper,
    required this.line,
    required this.margin,
    required this.hole,
    required this.ringLight,
    required this.ringDark,
    required this.style,
  });

  static NotebookColors of(BuildContext context) =>
      Theme.of(context).extension<NotebookColors>()!;

  @override
  NotebookColors copyWith({
    Color? cover,
    Color? onCover,
    Color? paper,
    Color? line,
    Color? margin,
    Color? hole,
    Color? ringLight,
    Color? ringDark,
    PaperStyle? style,
  }) =>
      NotebookColors(
        cover: cover ?? this.cover,
        onCover: onCover ?? this.onCover,
        paper: paper ?? this.paper,
        line: line ?? this.line,
        margin: margin ?? this.margin,
        hole: hole ?? this.hole,
        ringLight: ringLight ?? this.ringLight,
        ringDark: ringDark ?? this.ringDark,
        style: style ?? this.style,
      );

  @override
  NotebookColors lerp(ThemeExtension<NotebookColors>? other, double t) {
    if (other is! NotebookColors) return this;
    return NotebookColors(
      cover: Color.lerp(cover, other.cover, t)!,
      onCover: Color.lerp(onCover, other.onCover, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      line: Color.lerp(line, other.line, t)!,
      margin: Color.lerp(margin, other.margin, t)!,
      hole: Color.lerp(hole, other.hole, t)!,
      ringLight: Color.lerp(ringLight, other.ringLight, t)!,
      ringDark: Color.lerp(ringDark, other.ringDark, t)!,
      style: t < 0.5 ? style : other.style,
    );
  }
}

const String handFont = 'PatrickHand';

ThemeData buildTheme(ThemeSettings s, Brightness b) {
  final seed = s.pal.seed;
  final dark = b == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: b);
  final hsl = HSLColor.fromColor(seed);
  final cover = dark
      ? hsl.withLightness(0.13).withSaturation((hsl.saturation * 0.5).clamp(0.0, 1.0).toDouble()).toColor()
      : hsl.withLightness(0.30).toColor();
  final nb = NotebookColors(
    cover: cover,
    onCover: Colors.white,
    paper: dark ? const Color(0xFF202328) : const Color(0xFFFFFDF4),
    line: dark ? const Color(0xFF323B47) : const Color(0xFFC5DAEC),
    margin: dark ? const Color(0xFF7A3434) : const Color(0xFFE88B8B),
    hole: dark ? const Color(0xFF0C0D0F) : hsl.withLightness(0.18).toColor(),
    ringLight: dark ? const Color(0xFFB8BEC6) : const Color(0xFFF1F3F5),
    ringDark: dark ? const Color(0xFF5B6168) : const Color(0xFF8A9199),
    style: s.paper,
  );

  final base = ThemeData(colorScheme: scheme, useMaterial3: true, brightness: b);
  final hand = base.textTheme.apply(fontFamily: handFont);
  return base.copyWith(
    scaffoldBackgroundColor: cover,
    textTheme: base.textTheme.copyWith(
      headlineLarge: hand.headlineLarge,
      headlineMedium: hand.headlineMedium,
      headlineSmall: hand.headlineSmall?.copyWith(fontSize: 30),
      titleLarge: hand.titleLarge?.copyWith(fontSize: 26),
      titleMedium: hand.titleMedium?.copyWith(fontSize: 21),
    ),
    appBarTheme: const AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle.light,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: handFont, fontSize: 28, color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: Color.alphaBlend(scheme.primary.withValues(alpha: dark ? 0.08 : 0.04), nb.paper),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cover,
      indicatorColor: nb.paper,
      surfaceTintColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? scheme.primary : Colors.white70,
          )),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontFamily: handFont,
            fontSize: 16,
            color: states.contains(WidgetState.selected) ? Colors.white : Colors.white70,
          )),
    ),
    extensions: [nb],
  );
}

class NotebookPage extends StatelessWidget {
  final Widget child;
  final bool lines;
  const NotebookPage({super.key, required this.child, this.lines = true});

  static const double gutter = 34;
  static const double maxPageWidth = 820;

  @override
  Widget build(BuildContext context) {
    final nb = NotebookColors.of(context);
    return LayoutBuilder(builder: (context, box) {
      final extra = box.maxWidth > maxPageWidth ? (box.maxWidth - maxPageWidth) / 2 : 0.0;
      return Padding(
      padding: EdgeInsets.fromLTRB(16 + extra, 2, 8 + extra, 8),
      child: CustomPaint(
        painter: _PagePainter(nb, lines),
        foregroundPainter: _RingsPainter(nb),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: gutter),
            child: child,
          ),
        ),
      ),
    );
    });
  }
}

class _PagePainter extends CustomPainter {
  final NotebookColors nb;
  final bool lines;
  _PagePainter(this.nb, this.lines);

  static const _radius = BorderRadius.only(
    topLeft: Radius.circular(4),
    bottomLeft: Radius.circular(4),
    topRight: Radius.circular(14),
    bottomRight: Radius.circular(14),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    for (var i = 2; i >= 1; i--) {
      final r = _radius.toRRect(rect.translate(i * 2.5, i * 2.0));
      canvas.drawRRect(r, Paint()..color = Color.lerp(nb.paper, nb.cover, 0.25 * i)!);
    }
    final page = _radius.toRRect(rect);
    canvas.drawShadow(Path()..addRRect(page), Colors.black, 3, false);
    canvas.drawRRect(page, Paint()..color = nb.paper);

    canvas.save();
    canvas.clipRRect(page);
    final line = Paint()
      ..color = nb.line
      ..strokeWidth = 1;
    const step = 30.0;
    switch (lines ? nb.style : PaperStyle.liscio) {
      case PaperStyle.righe:
        for (var y = 56.0; y < size.height; y += step) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
        }
        break;
      case PaperStyle.quadretti:
        const q = 22.0;
        for (var y = q; y < size.height; y += q) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
        }
        for (var x = q; x < size.width; x += q) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
        }
        break;
      case PaperStyle.puntini:
        const q = 20.0;
        final dot = Paint()..color = nb.line;
        for (var y = q; y < size.height; y += q) {
          for (var x = q; x < size.width; x += q) {
            canvas.drawCircle(Offset(x, y), 1.3, dot);
          }
        }
        break;
      case PaperStyle.liscio:
        break;
    }
    final m = Paint()
      ..color = nb.margin
      ..strokeWidth = 1.2;
    const mx = NotebookPage.gutter - 4;
    canvas.drawLine(const Offset(mx, 0), Offset(mx, size.height), m);
    canvas.drawLine(const Offset(mx + 3, 0), Offset(mx + 3, size.height), m);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PagePainter old) => old.nb != nb || old.lines != lines;
}

class _RingsPainter extends CustomPainter {
  final NotebookColors nb;
  _RingsPainter(this.nb);

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 38.0;
    final holePaint = Paint()..color = nb.hole;
    final count = ((size.height - 24) / spacing).floor();
    final start = (size.height - (count - 1) * spacing) / 2;
    for (var i = 0; i < count; i++) {
      final y = start + i * spacing;
      canvas.drawCircle(Offset(12, y), 4.2, holePaint);
      final path = Path()
        ..moveTo(12, y)
        ..cubicTo(8, y - 11, -12, y - 11, -13, y - 1);
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4.2
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [nb.ringLight, nb.ringDark],
        ).createShader(Rect.fromLTWH(-14, y - 12, 28, 14));
      canvas.drawPath(path, Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 5.5
        ..color = Colors.black.withValues(alpha: 0.25));
      canvas.drawPath(path, ring);
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) => old.nb != nb;
}

class ScreenScale extends StatelessWidget {
  final Widget child;
  const ScreenScale({super.key, required this.child});

  static double factorFor(double shortestSide) {
    if (shortestSide >= 840) return 1.2;
    if (shortestSide >= 600) return 1.1;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final f = factorFor(mq.size.shortestSide);
    if (f == 1.0) return child;
    return MediaQuery(
      data: mq.copyWith(textScaler: _ScaledText(mq.textScaler, f)),
      child: child,
    );
  }
}

class _ScaledText extends TextScaler {
  final TextScaler base;
  final double factor;
  const _ScaledText(this.base, this.factor);

  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;

  @override
  double get textScaleFactor => scale(1);

  @override
  bool operator ==(Object other) =>
      other is _ScaledText && other.base == base && other.factor == factor;

  @override
  int get hashCode => Object.hash(base, factor);
}
