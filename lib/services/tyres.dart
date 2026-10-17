class TyreSet {
  String label;
  String sizes;
  TyreSet({this.label = '', this.sizes = ''});

  List<String> get sizeList =>
      sizes.split(RegExp(r'[;\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  static final RegExp _line = RegExp(r'^([^:/\d][^:]{0,39}):\s*(.*)$');

  static List<TyreSet> parse(String text) {
    final out = <TyreSet>[];
    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final m = _line.firstMatch(line);
      if (m != null) {
        out.add(TyreSet(label: m.group(1)!.trim(), sizes: m.group(2)!.trim()));
      } else if (out.isNotEmpty && out.last.label.isEmpty) {
        out.last.sizes = '${out.last.sizes}; $line';
      } else {
        out.add(TyreSet(sizes: line));
      }
    }
    return out;
  }

  static String format(List<TyreSet> sets) => sets
      .map((s) => TyreSet(label: s.label.replaceAll(':', ' ').trim(), sizes: s.sizeList.join('; ')))
      .where((s) => s.sizes.isNotEmpty)
      .map((s) => s.label.isEmpty ? s.sizes : '${s.label}: ${s.sizes}')
      .join('\n');

  static final RegExp _size = RegExp(
      r'(?<!\d)(\d{2,3})\s*/\s*(\d{2})\s*(Z?R|-)\s*(\d{2}(?:[.,]5)?)\s*(C\b)?\s*(?:M\s*/\s*C\s*)?\(?\s*(\d{2,3}(?:\s*/\s*\d{2,3})?)?\s*([A-Z])?\)?(?![A-Z0-9])');

  static List<String> findSizes(String text) {
    final out = <String>[];
    for (final m in _size.allMatches(text.toUpperCase())) {
      final rim = m.group(4)!.replaceAll(',', '.');
      final load = m.group(6)?.replaceAll(RegExp(r'\s'), '');
      final speed = m.group(7);
      final r = m.group(3) == '-' ? '-' : ' ${m.group(3)}';
      var s = '${m.group(1)}/${m.group(2)}$r$rim${m.group(5) ?? ''}';
      if (load != null && speed != null) s = '$s $load$speed';
      if (!out.contains(s)) out.add(s);
    }
    for (final m in _old.allMatches(text.toUpperCase())) {
      final w = double.tryParse(m.group(1)!.replaceAll(',', '.')) ?? 0;
      final rim = int.tryParse(m.group(2)!) ?? 0;
      if (w < 2 || w > 14 || rim < 8 || rim > 24) continue;
      final pr = m.group(3)?.replaceAll(RegExp(r'\s'), '');
      final s = '${m.group(1)!.replaceAll(',', '.')}-${m.group(2)}${pr == null ? '' : ' $pr'}';
      if (!out.contains(s)) out.add(s);
    }
    return out;
  }

  static final RegExp _old = RegExp(
      r'(?<![\d/.,])(\d{1,2}[.,]\d{2})(?![\d/])\s*(?:-|X|R|\s)\s*(\d{2})(?!\d)(?:\s*/?\s*(\d{1,2}\s*PR))?');

  static String rimOf(String size) =>
      RegExp(r'(?:Z?R|-)\s*(\d{2}(?:\.5)?)').firstMatch(size.toUpperCase())?.group(1) ?? '';

  static List<TyreSet> byRim(List<String> sizes, String Function(String rim) label) {
    final groups = <String, List<String>>{};
    for (final s in sizes) {
      groups.putIfAbsent(rimOf(s), () => []).add(s);
    }
    if (groups.length < 2) return [if (sizes.isNotEmpty) TyreSet(sizes: sizes.join('; '))];
    final rims = groups.keys.toList()
      ..sort((a, b) => (double.tryParse(a) ?? 0).compareTo(double.tryParse(b) ?? 0));
    return [
      for (final r in rims) TyreSet(label: r.isEmpty ? '' : label(r), sizes: groups[r]!.join('; ')),
    ];
  }
}
