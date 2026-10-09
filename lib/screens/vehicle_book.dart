import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'vehicle_detail_screen.dart';

class VehicleBook extends StatefulWidget {
  final List<String> ids;
  final String initialId;
  const VehicleBook({super.key, required this.ids, required this.initialId});

  @override
  State<VehicleBook> createState() => _VehicleBookState();
}

class _VehicleBookState extends State<VehicleBook> with SingleTickerProviderStateMixin {
  static const double _axis = 28;
  late int _index;
  late final AnimationController _flip =
      AnimationController(vsync: this, lowerBound: -1, upperBound: 1, value: 0);
  double _width = 1;

  @override
  void initState() {
    super.initState();
    _index = widget.ids.indexOf(widget.initialId).clamp(0, widget.ids.length - 1);
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  bool get _hasNext => _index < widget.ids.length - 1;
  bool get _hasPrev => _index > 0;

  void _onUpdate(DragUpdateDetails d) {
    if (_flip.isAnimating) return;
    final v = _flip.value - (d.primaryDelta ?? 0) / _width;
    _flip.value = v.clamp(_hasPrev ? -1.0 : 0.0, _hasNext ? 1.0 : 0.0);
  }

  Future<void> _onEnd(DragEndDetails d) async {
    if (_flip.isAnimating) return;
    final p = _flip.value;
    final vx = d.primaryVelocity ?? 0;
    var target = 0.0;
    if (p > 0 && (p > 0.35 || vx < -600)) target = 1;
    if (p < 0 && (p < -0.35 || vx > 600)) target = -1;
    await _flip.animateTo(target,
        duration: Duration(milliseconds: (320 * (target - p).abs()).round().clamp(120, 320)),
        curve: Curves.easeOut);
    if (!mounted || target == 0) return;
    _flip.value = 0;
    setState(() => _index += target.toInt());
  }

  Widget _turning(Widget page, double angle) {
    final shade = (math.sin(angle.abs()) * 0.35).clamp(0.0, 0.35);
    return Transform(
      alignment: Alignment.centerLeft,
      origin: const Offset(_axis, 0),
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..rotateY(angle),
      child: Stack(fit: StackFit.passthrough, children: [
        ClipRect(clipper: _SpineClip(angle != 0), child: page),
        if (angle != 0)
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRect(
                clipper: const _SpineClip(true),
                child: ColoredBox(color: Colors.black.withValues(alpha: shade)),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _body(int i) => VehicleDetailScreen(
        key: ValueKey('book_${widget.ids[i]}'),
        vehicleId: widget.ids[i],
        bodyOnly: true,
      );

  @override
  Widget build(BuildContext context) {
    final id = widget.ids[_index];
    return VehicleDetailScreen(
      key: ValueKey('book_page_$id'),
      vehicleId: id,
      wrapBody: (body) => LayoutBuilder(builder: (context, box) {
        _width = box.maxWidth <= 0 ? 1 : box.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: _onUpdate,
          onHorizontalDragEnd: _onEnd,
          child: AnimatedBuilder(
            animation: _flip,
            child: body,
            builder: (context, current) {
              final p = _flip.value;
              final turningCurrent = p > 0 && _hasNext;
              final turningPrev = p < 0 && _hasPrev;
              return Stack(fit: StackFit.expand, children: [
                if (turningCurrent) KeyedSubtree(key: const ValueKey('next'), child: _body(_index + 1)),
                KeyedSubtree(
                  key: const ValueKey('current'),
                  child: _turning(current!, turningCurrent ? -p * math.pi / 2 : 0),
                ),
                if (turningPrev)
                  KeyedSubtree(
                    key: const ValueKey('prev'),
                    child: _turning(_body(_index - 1), -(1 + p) * math.pi / 2),
                  ),
              ]);
            },
          ),
        );
      }),
    );
  }
}

class _SpineClip extends CustomClipper<Rect> {
  final bool active;
  const _SpineClip(this.active);

  @override
  Rect getClip(Size size) => active
      ? Rect.fromLTRB(_VehicleBookState._axis + 6, 0, size.width, size.height)
      : Rect.fromLTRB(-1000, -1000, size.width + 1000, size.height + 1000);

  @override
  bool shouldReclip(_SpineClip oldClipper) => oldClipper.active != active;
}
