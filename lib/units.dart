import 'dart:ui' as ui;

import 'package:intl/intl.dart';

import 'l10n.dart';

class Units {
  static String power = 'kw';
  static String distance = 'km';
  static String currency = '';

  static const List<String> powers = ['kw', 'cv', 'both'];
  static const List<String> distances = ['km', 'mi'];
  static const List<String> currencies = [
    'EUR', 'USD', 'GBP', 'CHF', 'SEK', 'NOK', 'DKK', 'ISK', 'PLN', 'CZK', 'HUF', 'RON', 'BGN', 'UAH', 'TRY',
    'CNY', 'JPY', 'KRW', 'INR', 'IDR', 'VND', 'THB',
  ];

  static void load(Map<String, dynamic>? j) {
    final p = j?['unitPower'];
    final d = j?['unitDistance'];
    final c = j?['unitCurrency'];
    power = powers.contains(p) ? p as String : 'kw';
    distance = distances.contains(d) ? d as String : 'km';
    currency = currencies.contains(c) ? c as String : '';
    _money = null;
  }

  static Map<String, dynamic> toJson() => {
        'unitPower': power,
        'unitDistance': distance,
        if (currency.isNotEmpty) 'unitCurrency': currency,
      };

  static bool get miles => distance == 'mi';
}

const double kmPerMile = 1.609344;
const double cvPerKw = 1.35962;

String _thousands(int n) {
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}

int kmToShown(int km) => Units.miles ? (km / kmPerMile).round() : km;

int shownToKm(int value) => Units.miles ? (value * kmPerMile).round() : value;

String get distanceUnit => Units.miles ? 'mi' : 'km';

String fmtKm(int km) => '${_thousands(kmToShown(km))} $distanceUnit';

double? parseDecimal(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

String fmtDecimal(double v) {
  final r = (v * 10).round() / 10;
  return r == r.roundToDouble() ? r.round().toString() : r.toStringAsFixed(1);
}

String kwToCvText(String kw) {
  final v = parseDecimal(kw);
  return v == null ? '' : (v * cvPerKw).round().toString();
}

String cvToKwText(String cv) {
  final v = parseDecimal(cv);
  return v == null ? '' : fmtDecimal(v / cvPerKw);
}

String fmtPower(String kw) {
  final v = parseDecimal(kw);
  if (v == null) return kw;
  final k = '${fmtDecimal(v)} kW';
  final c = '${(v * cvPerKw).round()} ${tr('unit.cv')}';
  switch (Units.power) {
    case 'cv':
      return c;
    case 'both':
      return '$k · $c';
    default:
      return k;
  }
}

NumberFormat? _money;

String get _deviceLocale => Intl.verifiedLocale(
    ui.PlatformDispatcher.instance.locale.toString(), NumberFormat.localeExists,
    onFailure: (_) => 'it_IT')!;

String get deviceCurrency => NumberFormat.simpleCurrency(locale: _deviceLocale).currencyName ?? 'EUR';

String currencySymbol(String code) => NumberFormat.simpleCurrency(locale: _deviceLocale, name: code).currencySymbol;

NumberFormat get moneyFormat {
  final f = _money;
  if (f != null) return f;
  return _money = NumberFormat.simpleCurrency(
      locale: _deviceLocale, name: Units.currency.isEmpty ? null : Units.currency);
}

void setMoneyLocale(String locale) => _money = NumberFormat.simpleCurrency(locale: locale);

String fmtMoney(int cents) => moneyFormat.format(cents / 100);

String centsText(int? cents) {
  if (cents == null) return '';
  final f = NumberFormat.decimalPatternDigits(locale: moneyFormat.locale, decimalDigits: 2)..turnOffGrouping();
  return f.format(cents / 100);
}

int? parseCents(String text) {
  var t = text.replaceAll(RegExp(r'[^0-9.,]'), '');
  if (t.isEmpty) return null;
  final dot = t.lastIndexOf('.');
  final comma = t.lastIndexOf(',');
  final sep = dot > comma ? dot : comma;
  if (sep >= 0 && t.length - sep - 1 <= 2) {
    t = '${t.substring(0, sep).replaceAll(RegExp(r'[.,]'), '')}.${t.substring(sep + 1)}';
  } else {
    t = t.replaceAll(RegExp(r'[.,]'), '');
  }
  final v = double.tryParse(t);
  return v == null ? null : (v * 100).round();
}
