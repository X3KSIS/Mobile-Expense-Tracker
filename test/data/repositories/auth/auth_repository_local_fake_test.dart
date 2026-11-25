import 'package:flutter_expensetracker/data/repositories/auth/auth_repository_local_fake.dart';
import 'package:flutter_expensetracker/domain/models/app_user.dart';
import 'package:flutter_expensetracker/domain/models/auth_exception.dart';
import 'package:flutter_expensetracker/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../testing/fakes/fake_repositories.dart';

AuthErrorCode? _errorCode(Result<Object?> result) => switch (result) {
  Error(error: AuthException(:final code)) => code,
  _ => null,
};

void main() {
  group('AuthRepositoryLocalFake', () {
    test('starts signed out by default', () {
      final auth = instantAuthRepository();

      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUser, isNull);
    });

    test('any credentials, even empty, sign in to the demo account', () async {
      final auth = instantAuthRepository();
      var notified = 0;
      auth.addListener(() => notified++);

      final result = await auth.signIn(email: '', password: '');

      expect(result, isA<Ok<AppUser>>());
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUser!.name, AuthRepositoryLocalFake.demoName);
      expect(notified, 1);

      await auth.signOut();
      await auth.signIn(email: 'someone@example.com', password: 'whatever');
      expect(auth.currentUser!.email, AuthRepositoryLocalFake.demoEmail);
    });

    test('signs up a new account and signs it in', () async {
      final now = DateTime(2026, 11, 25);
      final auth = instantAuthRepository(now: now);

      final result = await auth.signUp(
        name: ' Mwila Banda ',
        email: 'Mwila@Example.com',
        password: 'x',
      );

      expect(result, isA<Ok<AppUser>>());
      final user = auth.currentUser!;
      expect(user.name, 'Mwila Banda');
      expect(user.email, 'mwila@example.com');
      expect(user.createdAt, now);

      // Signing in again with that email opens the same account.
      await auth.signOut();
      await auth.signIn(email: 'mwila@example.com', password: '');
      expect(auth.currentUser!.name, 'Mwila Banda');
    });

    test('blank sign-up fields fall back to the demo details', () async {
      final auth = instantAuthRepository();

      await auth.signUp(name: '  ', email: '', password: '');

      expect(auth.currentUser!.name, AuthRepositoryLocalFake.demoName);
      expect(auth.currentUser!.email, AuthRepositoryLocalFake.demoEmail);
    });

    test('signs out and notifies', () async {
      final auth = instantAuthRepository(signedIn: true);
      var notified = 0;
      auth.addListener(() => notified++);

      await auth.signOut();

      expect(auth.isAuthenticated, isFalse);
      expect(notified, 1);
    });

    test('updates the profile and keeps it after signing in again', () async {
      final auth = instantAuthRepository(signedIn: true);

      final result = await auth.updateProfile(
        name: 'Paul M. Mubanga',
        phone: '0761234567',
      );

      expect(result, isA<Ok<AppUser>>());
      expect(auth.currentUser!.name, 'Paul M. Mubanga');
      expect(auth.currentUser!.phone, '0761234567');

      await auth.signOut();
      await auth.signIn(email: AuthRepositoryLocalFake.demoEmail, password: '');
      expect(auth.currentUser!.name, 'Paul M. Mubanga');
    });

    test('an empty phone clears the number', () async {
      final auth = instantAuthRepository(signedIn: true);
      expect(auth.currentUser!.phone, isNotNull);

      await auth.updateProfile(name: 'Paul Mubanga', phone: '  ');

      expect(auth.currentUser!.phone, isNull);
    });

    test('updating the profile while signed out fails', () async {
      final auth = instantAuthRepository();

      final result = await auth.updateProfile(name: 'X Y', phone: '');

      expect(_errorCode(result), AuthErrorCode.notSignedIn);
    });

    test('password reset always succeeds', () async {
      final auth = instantAuthRepository();

      final result = await auth.sendPasswordResetEmail('');

      expect(result, isA<Ok<void>>());
    });
  });
}
