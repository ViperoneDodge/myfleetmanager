import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme.dart';

class Rule extends InheritedWidget {
  final double step;
  const Rule({super.key, required this.step, required super.child});

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Rule>()?.step ?? 30;

  static double baseFor(PaperStyle style) {
    switch (style) {
      case PaperStyle.quadretti:
        return 22;
      case PaperStyle.puntini:
        return 20;
      case PaperStyle.righe:
      case PaperStyle.liscio:
        return 30;
    }
  }

  static double stepFor(BuildContext context, PaperStyle style) {
    final base = baseFor(style);
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    return scale <= 1.0 ? base : (base * scale).roundToDouble();
  }

  static StrutStyle strut(BuildContext context, double fontSize) {
    final step = of(context);
    final scaled = MediaQuery.textScalerOf(context).scale(fontSize);
    final lines = (scaled * 0.95 / step).ceil().clamp(1, 4);
    return StrutStyle(
      fontSize: fontSize,
      height: step * lines / scaled,
      forceStrutHeight: true,
      leadingDistribution: TextLeadingDistribution.proportional,
    );
  }

  @override
  bool updateShouldNotify(Rule oldWidget) => oldWidget.step != step;
}

class RuledScroll extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;
  const RuledScroll({super.key, required this.children, required this.padding});

  @override
  Widget build(BuildContext context) {
    final nb = NotebookColors.of(context);
    final step = Rule.stepFor(context, nb.style);
    final top = (padding.top / step).round() * step;
    return Rule(
      step: step,
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          clipBehavior: Clip.none,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: CustomPaint(
              painter: _RulePainter(nb, step, top),
              child: Padding(
                padding: EdgeInsets.fromLTRB(padding.left, top, padding.right, padding.bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [for (final c in children) c is OnRule ? c : OnRule(child: c)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnRule extends SingleChildRenderObjectWidget {
  final bool center;
  const OnRule({super.key, this.center = false, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderOnRule(Rule.of(context), center);

  @override
  void updateRenderObject(BuildContext context, _RenderOnRule renderObject) {
    renderObject
      ..step = Rule.of(context)
      ..center = center;
  }
}

class _RenderOnRule extends RenderShiftedBox {
  _RenderOnRule(this._step, this._center) : super(null);

  double _step;
  set step(double v) {
    if (v == _step) return;
    _step = v;
    markNeedsLayout();
  }

  bool _center;
  set center(bool v) {
    if (v == _center) return;
    _center = v;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final c = child;
    if (c == null) {
      size = constraints.constrain(Size(constraints.maxWidth, 0));
      return;
    }
    c.layout(constraints.loosen(), parentUsesSize: true);
    final h = c.size.height;
    final rows = h <= 2 ? 0 : ((h - 2) / _step).floor() + 1;
    size = constraints.constrain(Size(constraints.maxWidth, rows * _step));
    final dy = _center ? (size.height - h) / 2 : size.height - h;
    (c.parentData as BoxParentData).offset = Offset(0, dy);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final h = child?.getMinIntrinsicHeight(width) ?? 0;
    return h <= 2 ? 0 : (((h - 2) / _step).floor() + 1) * _step;
  }

  @override
  double computeMaxIntrinsicHeight(double width) => computeMinIntrinsicHeight(width);
}

class BlankLine extends StatelessWidget {
  final int lines;
  const BlankLine({super.key, this.lines = 1});

  @override
  Widget build(BuildContext context) => SizedBox(height: Rule.of(context) * lines);
}

class _RulePainter extends CustomPainter {
  final NotebookColors nb;
  final double step;
  final double top;
  _RulePainter(this.nb, this.step, this.top);

  @override
  void paint(Canvas canvas, Size size) {
    const left = -NotebookPage.gutter;
    final right = size.width + 40;
    final line = Paint()
      ..color = nb.line
      ..strokeWidth = 1;
    final y0 = top - (top / step).floor() * step;
    switch (nb.style) {
      case PaperStyle.righe:
        for (var y = y0; y < size.height; y += step) {
          canvas.drawLine(Offset(left, y), Offset(right, y), line);
        }
        break;
      case PaperStyle.quadretti:
        for (var y = y0; y < size.height; y += step) {
          canvas.drawLine(Offset(left, y), Offset(right, y), line);
        }
        for (var x = left + step; x < right; x += step) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
        }
        break;
      case PaperStyle.puntini:
        final dot = Paint()..color = nb.line;
        for (var y = y0; y < size.height; y += step) {
          for (var x = left + step; x < right; x += step) {
            canvas.drawCircle(Offset(x, y), 1.3, dot);
          }
        }
        break;
      case PaperStyle.liscio:
        break;
    }
  }

  @override
  bool shouldRepaint(_RulePainter old) => old.nb != nb || old.step != step || old.top != top;
}

class RuledText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final double size;
  const RuledText(this.data, {super.key, this.style, this.size = 14});

  @override
  Widget build(BuildContext context) =>
      Text(data, style: style, strutStyle: Rule.strut(context, style?.fontSize ?? size));
}
