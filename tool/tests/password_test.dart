import 'package:flutter_test/flutter_test.dart';
import 'package:myfleetmanager/services/auth_service.dart';

void main() {
  test('controlli prima di cambiare la password', () {
    expect(AuthService.passwordChangeError('', 'nuovaPass1', 'nuovaPass1'), 'login.fillAll');
    expect(AuthService.passwordChangeError('vecchia1', 'corta', 'corta'), 'pw.short');
    expect(AuthService.passwordChangeError('vecchia1', 'nuovaPass1', 'nuovaPass2'), 'pw.mismatch');
    expect(AuthService.passwordChangeError('stessaPass1', 'stessaPass1', 'stessaPass1'), 'pw.same');
    expect(AuthService.passwordChangeError('vecchia1', 'nuovaPass1', 'nuovaPass1'), isNull);
  });
}
