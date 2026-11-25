import 'package:flutter_expensetracker/ui/profile/view_models/edit_profile_view_model.dart';
import 'package:flutter_expensetracker/ui/profile/view_models/profile_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../testing/fakes/fake_repositories.dart';

void main() {
  group('ProfileViewModel', () {
    test('exposes the user and the membership date', () {
      final auth = instantAuthRepository(
        signedIn: true,
        now: DateTime(2026, 11, 25),
      );
      final viewModel = ProfileViewModel(authRepository: auth);
      addTearDown(viewModel.dispose);

      expect(viewModel.user!.name, 'Paul Mubanga');
      expect(viewModel.memberSince, 'Member since August 2026');
    });

    test('notifies when the profile changes', () async {
      final auth = instantAuthRepository(signedIn: true);
      final viewModel = ProfileViewModel(authRepository: auth);
      addTearDown(viewModel.dispose);
      var notified = 0;
      viewModel.addListener(() => notified++);

      await auth.updateProfile(name: 'Paul M. Mubanga', phone: '');

      expect(notified, 1);
      expect(viewModel.user!.name, 'Paul M. Mubanga');
    });

    test('signOut signs the user out', () async {
      final auth = instantAuthRepository(signedIn: true);
      final viewModel = ProfileViewModel(authRepository: auth);
      addTearDown(viewModel.dispose);

      await viewModel.signOut.execute();

      expect(viewModel.signOut.completed, isTrue);
      expect(auth.isAuthenticated, isFalse);
      expect(viewModel.memberSince, isEmpty);
    });

    test('stops listening after dispose', () async {
      final auth = instantAuthRepository(signedIn: true);
      final viewModel = ProfileViewModel(authRepository: auth);
      viewModel.dispose();

      // Would throw if the disposed view model were still listening.
      await auth.updateProfile(name: 'Someone Else', phone: '');
    });
  });

  group('EditProfileViewModel', () {
    test('saves the name and a normalised phone number', () async {
      final auth = instantAuthRepository(signedIn: true);
      final viewModel = EditProfileViewModel(authRepository: auth);
      addTearDown(viewModel.dispose);

      await viewModel.save.execute((
        name: '  Paul Mubanga Jr ',
        phone: '076 123 4567',
      ));

      expect(viewModel.save.completed, isTrue);
      expect(auth.currentUser!.name, 'Paul Mubanga Jr');
      expect(auth.currentUser!.phone, '0761234567');
    });

    test('reports an error when signed out', () async {
      final auth = instantAuthRepository();
      final viewModel = EditProfileViewModel(authRepository: auth);
      addTearDown(viewModel.dispose);

      await viewModel.save.execute((name: 'Paul', phone: ''));

      expect(viewModel.errorMessage, 'Your session has ended. Sign in again.');
    });
  });
}
