import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/services.dart' show rootBundle;

/// Traduzioni dell'app. Ogni lingua è un file JSON in assets/l10n/<codice>.json
/// (formato chiave → testo). Se manca una frase si usa l'inglese, poi l'italiano.
/// Per aggiungere una lingua: creare il file JSON e aggiungere il codice in [available].
class L10n {
  /// Nome di ogni lingua scritto nella lingua stessa.
  static const Map<String, String> names = {
    'it': 'Italiano',
    'en': 'English',
    'fr': 'Français',
    'de': 'Deutsch',
    'es': 'Español',
    'pt': 'Português',
    'nl': 'Nederlands',
    'hr': 'Hrvatski',
    'sl': 'Slovenščina',
    'pl': 'Polski',
    'cs': 'Čeština',
    'sk': 'Slovenčina',
    'hu': 'Magyar',
    'ro': 'Română',
    'bg': 'Български',
    'el': 'Ελληνικά',
    'sv': 'Svenska',
    'da': 'Dansk',
    'fi': 'Suomi',
    'et': 'Eesti',
    'lv': 'Latviešu',
    'lt': 'Lietuvių',
    'mt': 'Malti',
    'ga': 'Gaeilge',
  };

  /// Lingue con il file di traduzione incluso nell'app.
  static const List<String> available = ['it', 'en', 'fr', 'de', 'es', 'hr'];

  static String code = 'it';
  static Map<String, String> _cur = {};
  static Map<String, String> _en = {};
  static Map<String, String> _it = {};

  /// Lingua da usare: quella scelta nelle impostazioni, altrimenti quella del
  /// telefono se disponibile, altrimenti inglese.
  static String resolve(String? preferred) {
    if (preferred != null && available.contains(preferred)) return preferred;
    final device = PlatformDispatcher.instance.locale.languageCode;
    return available.contains(device) ? device : 'en';
  }

  static Future<void> load(String c) async {
    if (_it.isEmpty) _it = await _read('it');
    if (_en.isEmpty) _en = await _read('en');
    _cur = c == 'it' ? _it : (c == 'en' ? _en : await _read(c));
    code = c;
  }

  static Future<Map<String, String>> _read(String c) async {
    try {
      final txt = await rootBundle.loadString('assets/l10n/$c.json');
      final m = Map<String, dynamic>.from(jsonDecode(txt) as Map);
      return m.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }
}

/// Testo tradotto. I segnaposto {nome} vengono sostituiti con [args].
String tr(String key, [Map<String, Object?>? args]) {
  var s = L10n._cur[key] ?? L10n._en[key] ?? L10n._it[key] ?? key;
  if (args != null) {
    args.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  }
  return s;
}

/// Come [tr] ma sceglie singolare/plurale: chiavi "<key>_one" e "<key>_other",
/// con il numero nel segnaposto {n}.
String trn(String key, int n, [Map<String, Object?>? args]) =>
    tr(n == 1 ? '${key}_one' : '${key}_other', {'n': n, ...?args});
