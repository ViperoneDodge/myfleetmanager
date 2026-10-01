import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../version.dart';

/// Contatti dello sviluppatore: segnalazioni, privacy, avvisi.
class SupportService {
  static const String email = 'appmyfleetmanager@gmail.com';

  /// Informativa privacy pubblicata con GitHub Pages (cartella docs/ del repository).
  static const String privacyUrl = 'https://viperonedodge.github.io/myfleetmanager/privacy.html';

  /// Impronta SHA-256 del codice sviluppatore: il codice in chiaro non è nel sorgente.
  static const String devCodeHash = '8746c457f5dfb41265e767fb6cf6a2ae656240aeddd30d686273e78f424bd291';

  /// Modello e versione Android del telefono (per le segnalazioni).
  static Future<String> deviceDescription() async {
    try {
      if (Platform.isAndroid) {
        final a = await DeviceInfoPlugin().androidInfo;
        return '${a.manufacturer} ${a.model} · Android ${a.version.release} (API ${a.version.sdkInt})';
      }
      if (Platform.isIOS) {
        final i = await DeviceInfoPlugin().iosInfo;
        return '${i.utsname.machine} · iOS ${i.systemVersion}';
      }
    } catch (_) {}
    return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  }

  /// Apre l'app email del telefono con destinatario, oggetto e testo già pronti.
  static Future<bool> openEmail({required String subject, required String body}) async {
    final uri = Uri.parse('mailto:$email'
        '?subject=${Uri.encodeComponent(subject)}'
        '&body=${Uri.encodeComponent(body)}');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openPrivacy() async {
    try {
      return await launchUrl(Uri.parse(privacyUrl), mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Avviso automatico allo sviluppatore (es. Pro sbloccata con il codice di test).
  /// Usa FormSubmit (formsubmit.co), gratuito e senza server: al primo invio
  /// arriva una email di attivazione da confermare una sola volta.
  static Future<void> notifyDeveloper(String subject, Map<String, String> fields) async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final req = await client.postUrl(Uri.parse('https://formsubmit.co/ajax/$email'));
      req.headers.contentType = ContentType.json;
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      req.write(jsonEncode({
        '_subject': subject,
        '_template': 'table',
        ...fields,
        'Versione app': appVersion,
        'Telefono': await deviceDescription(),
        'Data': DateTime.now().toIso8601String(),
      }));
      final res = await req.close().timeout(const Duration(seconds: 20));
      await res.drain<void>();
      client.close();
    } catch (_) {
      // Offline: l'avviso non è indispensabile, lo sblocco resta valido.
    }
  }
}
