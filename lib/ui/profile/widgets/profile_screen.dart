import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/app_logo.dart';
import '../../core/ui/header_icon_button.dart';
import '../../core/ui/screen_header.dart';
import '../view_models/profile_view_model.dart';
import 'profile_card.dart';
import 'profile_menu.dart';
import 'sign_out_button.dart';

/// The signed-in user's profile, account settings and sign-out.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.viewModel});

  final ProfileViewModel viewModel;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.signOut.addListener(_onSignOutChanged);
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.signOut.removeListener(_onSignOutChanged);
      widget.viewModel.signOut.addListener(_onSignOutChanged);
    }
  }

  @override
  void dispose() {
    widget.viewModel.signOut.removeListener(_onSignOutChanged);
    super.dispose();
  }

  /// A successful sign-out is handled by the router; only errors show here.
  void _onSignOutChanged() {
    final command = widget.viewModel.signOut;
    if (!command.error) return;
    command.clearResult();
    _showSnackBar("Couldn't sign out. Please try again.");
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _comingSoon(String feature) => _showSnackBar('$feature is coming soon');

  void _editProfile() => context.push(Routes.editProfile);

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'ExpenseTrack',
      applicationVersion: ProfileViewModel.appVersion,
      applicationIcon: const AppLogo(size: Dimens.avatarSize),
      children: const [Text('Know where your kwacha goes.')],
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([viewModel, viewModel.signOut]),
          builder: (context, _) {
            final user = viewModel.user;
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                Dimens.screenPadding,
                Dimens.gapL,
                Dimens.screenPadding,
                Dimens.screenPadding,
              ),
              children: [
                ScreenHeader(
                  title: 'Profile',
                  trailing: HeaderIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit profile',
                    onPressed: _editProfile,
                  ),
                ),
                const SizedBox(height: Dimens.sectionGap + 2),
                if (user != null)
                  ProfileCard(user: user, memberSince: viewModel.memberSince),
                const SizedBox(height: Dimens.sectionGap + 6),
                ..._sections(),
                const SizedBox(height: Dimens.sectionGap + 6),
                SignOutButton(
                  loading: viewModel.signOut.running,
                  onConfirmed: viewModel.signOut.execute,
                ),
                const SizedBox(height: Dimens.gapL),
                Center(
                  child: Text(
                    'ExpenseTrack ${ProfileViewModel.appVersion}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _sections() => [
    ProfileMenuSection(
      title: 'Account',
      items: [
        ProfileMenuItem(
          icon: Icons.person_outline_rounded,
          title: 'Personal details',
          subtitle: 'Name and phone number',
          onTap: _editProfile,
        ),
        ProfileMenuItem(
          icon: Icons.lock_outline_rounded,
          title: 'Security',
          subtitle: 'Password and sign-in',
          onTap: () => _comingSoon('Security settings'),
        ),
        ProfileMenuItem(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          subtitle: 'Bill reminders and budget alerts',
          onTap: () => _comingSoon('Notification settings'),
        ),
      ],
    ),
    const SizedBox(height: Dimens.sectionGap),
    ProfileMenuSection(
      title: 'Preferences',
      items: [
        const ProfileMenuItem(
          icon: Icons.payments_outlined,
          title: 'Currency',
          value: ProfileViewModel.currency,
        ),
        ProfileMenuItem(
          icon: Icons.category_outlined,
          title: 'Categories',
          subtitle: 'Names, icons and colours',
          onTap: () => _comingSoon('Categories'),
        ),
        ProfileMenuItem(
          icon: Icons.file_download_outlined,
          title: 'Export data',
          subtitle: 'Download your transactions',
          onTap: () => _comingSoon('Export'),
        ),
      ],
    ),
    const SizedBox(height: Dimens.sectionGap),
    ProfileMenuSection(
      title: 'Support',
      items: [
        ProfileMenuItem(
          icon: Icons.help_outline_rounded,
          title: 'Help and support',
          onTap: () => _comingSoon('Help and support'),
        ),
        ProfileMenuItem(
          icon: Icons.info_outline_rounded,
          title: 'About ExpenseTrack',
          onTap: _showAbout,
        ),
      ],
    ),
  ];
}
