import 'package:flutter_expensetracker/ui/profile/view_models/security_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../testing/fakes/fake_repositories.dart';

void main() {
  test('changes the password once the current one is right', () async {
    final auth = instantAuthRepository(signedIn: true);
    final vm = SecurityViewModel(authRepository: auth);
    addTearDown(vm.dispose);

    await vm.changePassword.execute((current: 'wrong', next: 'newpass2026'));
    expect(vm.errorMessage, contains("current password isn't right"));

    await vm.changePassword.execute((
      current: 'kwacha2026',
      next: 'kwacha2026',
    ));
    expect(vm.errorMessage, contains('different'));

    await vm.changePassword.execute((
      current: 'kwacha2026',
      next: 'newpass2026',
    ));
    expect(vm.changePassword.completed, isTrue);
    expect(auth.currentPassword, 'newpass2026');
  });
}
