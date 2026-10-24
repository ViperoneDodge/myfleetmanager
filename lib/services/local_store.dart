import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

class LocalStore {
  Directory? _dir;

  Future<Directory> _base() async {
    _dir ??= await getApplicationDocumentsDirectory();
    return _dir!;
  }

  Future<File> _file(String name) async => File('${(await _base()).path}/$name');

  Future<Map<String, dynamic>?> _readJson(String name) async {
    if (kIsWeb) {
      try {
        final txt = (await SharedPreferences.getInstance()).getString(name);
        if (txt == null || txt.trim().isEmpty) return null;
        return Map<String, dynamic>.from(jsonDecode(txt) as Map);
      } catch (_) {
        return null;
      }
    }
    try {
      final f = await _file(name);
      if (!await f.exists()) return null;
      final txt = await f.readAsString();
      if (txt.trim().isEmpty) return null;
      return Map<String, dynamic>.from(jsonDecode(txt) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> _delete(String name) async {
    if (kIsWeb) {
      await (await SharedPreferences.getInstance()).remove(name);
      return;
    }
    final f = await _file(name);
    if (await f.exists()) await f.delete();
  }

  Future<void> _writeJson(String name, Map<String, dynamic> data) async {
    if (kIsWeb) {
      try {
        await (await SharedPreferences.getInstance()).setString(name, jsonEncode(data));
      } catch (_) {}
      return;
    }
    final f = await _file(name);
    final tmp = await _file('$name.tmp');
    await tmp.writeAsString(jsonEncode(data), flush: true);
    await tmp.rename(f.path);
  }

  Future<Map<String, dynamic>> readAccounts() async =>
      await _readJson('accounts.json') ?? <String, dynamic>{};

  Future<void> writeAccounts(Map<String, dynamic> a) =>
      _writeJson('accounts.json', a);

  Future<Session?> readSession() async =>
      Session.fromJson(await _readJson('session.json'));

  Future<void> writeSession(Session? s) async {
    if (s == null) {
      await _delete('session.json');
      return;
    }
    await _writeJson('session.json', s.toJson());
  }

  Future<Map<String, dynamic>?> readSettings() => _readJson('settings.json');

  Future<void> writeSettings(Map<String, dynamic> s) => _writeJson('settings.json', s);

  Future<Directory> docsDir() async {
    final d = Directory('${(await _base()).path}/documenti');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<UserData> readUserData(Session s) async {
    final j = await _readJson('data_${s.storageKey}.json');
    return j == null ? UserData() : UserData.fromJson(j);
  }

  Future<void> deleteUserData(Session s) async {
    try {
      await _delete('data_${s.storageKey}.json');
      await _delete('notif_${s.storageKey}.json');
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> readNotifLog(Session s) => _readJson('notif_${s.storageKey}.json');

  Future<void> writeNotifLog(Session s, Map<String, dynamic> j) async {
    try {
      await _writeJson('notif_${s.storageKey}.json', j);
    } catch (_) {}
  }

  Future<void> writeUserData(Session s, UserData d) =>
      _writeJson('data_${s.storageKey}.json', d.toJson());
}
