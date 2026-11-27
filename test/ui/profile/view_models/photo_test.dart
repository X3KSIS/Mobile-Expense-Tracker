import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_expensetracker/ui/core/ui/user_avatar.dart';
import 'package:flutter_expensetracker/ui/profile/view_models/edit_profile_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../testing/fakes/fake_repositories.dart';

void main() {
  test('a photo is saved at once and can be removed', () async {
    final auth = instantAuthRepository(signedIn: true);
    final vm = EditProfileViewModel(authRepository: auth);
    addTearDown(vm.dispose);
    final photo = Uint8List.fromList([1, 2, 3]);

    await vm.setPhoto.execute(photo);
    expect(vm.photo, photo);
    expect(auth.currentUser!.photo, photo);

    await vm.setPhoto.execute(null);
    expect(vm.photo, isNull);
  });

  testWidgets('the avatar shows initials until there is a photo', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: UserAvatar(initials: 'PM')),
    );
    expect(find.text('PM'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
