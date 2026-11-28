import 'package:flutter/material.dart';
import 'package:flutter_expensetracker/data/repositories/auth/auth_repository_local_fake.dart';
import 'package:flutter_expensetracker/domain/models/app_user.dart';
import 'package:flutter_expensetracker/domain/models/auth_exception.dart';
import 'package:flutter_expensetracker/ui/auth/view_models/login_view_model.dart';
import 'package:flutter_expensetracker/ui/auth/view_models/sign_up_view_model.dart';
import 'package:flutter_expensetracker/ui/auth/view_models/verify_email_view_model.dart';
import 'package:flutter_expensetracker/ui/auth/widgets/verify_email_screen.dart';
import 'package:flutter_expensetracker/ui/core/themes/theme.dart';
import 'package:flutter_expensetracker/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

/// Like Supabase with "Confirm email" on: sign-up and unconfirmed
/// sign-in ask for the emailed code.
class _ConfirmingAuth extends AuthRepositoryLocalFake {
  _ConfirmingAuth() : super(delay: Duration.zero);

  final List<String> codesSentTo = [];

  @override
  Future<Result<AppUser>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await super.signUp(name: name, email: email, password: password);
    await signOut();
    return const Result.error(AuthException(AuthErrorCode.confirmEmail));
  }

  @override
  Future<Result<AppUser>> signIn({
    required String identifier,
    required String password,
  }) async =>
      const Result.error(AuthException(AuthErrorCode.emailNotConfirmed));

  @override
  Future<Result<void>> resendEmailCode(String email) async {
    codesSentTo.add(email);
    return const Result.ok(null);
  }
}

void main() {
  test('sign-up that needs a code hands over to the code screen', () async {
    final auth = _ConfirmingAuth();
    final vm = SignUpViewModel(authRepository: auth);
    addTearDown(vm.dispose);

    await vm.signUp.execute((
      name: 'Mwila',
      email: ' mwila@example.com ',
      password: 'kwacha2026',
    ));

    expect(vm.signUp.completed, isTrue);
    expect(vm.errorMessage, isNull);
    expect(vm.emailToConfirm, 'mwila@example.com');
    expect(auth.isAuthenticated, isFalse);
  });

  test('signing in before confirming sends a new code', () async {
    final auth = _ConfirmingAuth();
    final vm = LoginViewModel(authRepository: auth);
    addTearDown(vm.dispose);

    await vm.login.execute((identifier: 'mwila@example.com', password: 'x'));

    expect(vm.emailToConfirm, 'mwila@example.com');
    expect(auth.codesSentTo, ['mwila@example.com']);
  });

  test('the right code signs in; a wrong one explains', () async {
    final auth = _ConfirmingAuth();
    await auth.signUp(
      name: 'Mwila',
      email: 'mwila@example.com',
      password: 'kwacha2026',
    );
    final vm = VerifyEmailViewModel(
      authRepository: auth,
      email: 'mwila@example.com',
      resendWait: Duration.zero,
    );
    addTearDown(vm.dispose);

    await vm.verify.execute('000000');
    expect(vm.errorMessage, contains('wrong or has expired'));
    expect(auth.isAuthenticated, isFalse);

    await vm.verify.execute(AuthRepositoryLocalFake.validCode);
    expect(auth.isAuthenticated, isTrue);
    expect(auth.currentUser!.name, 'Mwila');
  });

  test('codes are 6 to 10 digits', () {
    expect(VerifyEmailViewModel.validateCode(''), isNotNull);
    expect(VerifyEmailViewModel.validateCode('12345'), isNotNull);
    expect(VerifyEmailViewModel.validateCode('12ab56'), isNotNull);
    expect(VerifyEmailViewModel.validateCode('123456'), isNull);
    expect(VerifyEmailViewModel.validateCode('12345678'), isNull);
  });

  testWidgets('a new code can be sent once the wait is over', (tester) async {
    final auth = _ConfirmingAuth();
    final vm = VerifyEmailViewModel(
      authRepository: auth,
      email: 'mwila@example.com',
      resendWait: const Duration(seconds: 2),
    );
    addTearDown(vm.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: VerifyEmailScreen(viewModel: vm),
      ),
    );

    expect(find.textContaining('mwila@example.com'), findsOneWidget);
    expect(find.text('Send a new code in 2s'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Send a new code'));
    await tester.pump();
    await tester.pump();
    expect(auth.codesSentTo, ['mwila@example.com']);
    expect(find.text('New code sent to mwila@example.com.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
