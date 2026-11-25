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

    test('signs in the demo account, ignoring case and spaces', () async {
      final auth = instantAuthRepository();
      var notified = 0;
      auth.addListener(() => notified++);

      final result = await auth.signIn(
        email: '  DEMO@expensetrack.app ',
        password: AuthRepositoryLocalFake.demoPassword,
      );

      expect(result, isA<Ok<AppUser>>());
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUser!.name, 'Paul Mubanga');
      expect(notified, 1);
    });

    test('rejects a wrong password', () async {
      final auth = instantAuthRepository();

      final result = await auth.signIn(
        email: AuthRepositoryLocalFake.demoEmail,
        password: 'wrong-password',
      );

      expect(_errorCode(result), AuthErrorCode.invalidCredentials);
      expect(auth.isAuthenticated, isFalse);
    });

    test('rejects an unknown email', () async {
      final auth = instantAuthRepository();

      final result = await auth.signIn(
        email: 'nobody@example.com',
        password: 'password123',
      );

      expect(_errorCode(result), AuthErrorCode.invalidCredentials);
    });

    test('signs up a new account and signs it in', () async {
      final now = DateTime(2026, 11, 25);
      final auth = instantAuthRepository(now: now);

      final result = await auth.signUp(
        name: ' Mwila Banda ',
        email: 'Mwila@Example.com',
        password: 'kwacha2026',
      );

      expect(result, isA<Ok<AppUser>>());
      final user = auth.currentUser!;
      expect(user.name, 'Mwila Banda');
      expect(user.email, 'mwila@example.com');
      expect(user.createdAt, now);

      await auth.signOut();
      final again = await auth.signIn(
        email: 'mwila@example.com',
        password: 'kwacha2026',
      );
      expect(again, isA<Ok<AppUser>>());
    });

    test('refuses to sign up an email that already exists', () async {
      final auth = instantAuthRepository();

      final result = await auth.signUp(
        name: 'Someone',
        email: AuthRepositoryLocalFake.demoEmail,
        password: 'kwacha2026',
      );

      expect(_errorCode(result), AuthErrorCode.emailAlreadyInUse);
      expect(auth.isAuthenticated, isFalse);
    });

    test('refuses a password shorter than 8 characters', () async {
      final auth = instantAuthRepository();

      final result = await auth.signUp(
        name: 'Someone',
        email: 'someone@example.com',
        password: 'short1',
      );

      expect(_errorCode(result), AuthErrorCode.weakPassword);
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
      await auth.signIn(
        email: AuthRepositoryLocalFake.demoEmail,
        password: AuthRepositoryLocalFake.demoPassword,
      );
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

      final result = await auth.sendPasswordResetEmail('nobody@example.com');

      expect(result, isA<Ok<void>>());
    });
  });
}
