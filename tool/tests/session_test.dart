import 'package:flutter_test/flutter_test.dart';
import 'package:myfleetmanager/models.dart';
import 'package:myfleetmanager/services/auth_service.dart';

void main() {
  test('sessione Google salvata e riletta, sessioni vecchie senza ripristino', () async {
    final s = Session(mode: AccountMode.cloud, key: 'uid-demo', displayName: 'demo@example.com', email: 'demo@example.com');
    expect(s.google, isFalse);
    final g = s.withGoogle();
    final back = Session.fromJson(g.toJson())!;
    expect(back.google, isTrue);
    expect(back.key, 'uid-demo');
    expect(back.email, 'demo@example.com');
    expect(Session.fromJson(s.toJson())!.google, isFalse);
    expect(s.toJson().containsKey('google'), isFalse);
    expect(await silentGoogle(s), isFalse);
    expect(lastSilent, 'account non Google');
  });
}
