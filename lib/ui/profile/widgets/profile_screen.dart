import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../auth/view_models/auth_error_message.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/app_logo.dart';
import '../../core/ui/header_icon_button.dart';
import '../../core/ui/screen_header.dart';
import '../view_models/profile_view_model.dart';
import 'help_sheet.dart';
import 'profile_card.dart';
import 'profile_menu.dart';
import 'sign_out_button.dart';
import 'sync_status_card.dart';

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
    final message = commandErrorMessage(command);
    if (message == null) return;
    command.clearResult();
    _showSnackBar(message);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _editProfile() => context.push(Routes.editProfile);

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Expense Tracker',
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
                  ProfileCard(
                    user: user,
                    stats: viewModel.stats,
                    memberSince: viewModel.memberSince,
                    onTap: _editProfile,
                  ),
                const SizedBox(height: Dimens.gapL),
                SyncStatusCard(
                  status: viewModel.syncStatus,
                  lastSyncedAt: viewModel.lastSyncedAt,
                  now: viewModel.now,
                  onSyncNow: viewModel.syncNow.execute,
                ),
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
                    'Expense Tracker ${ProfileViewModel.appVersion} · '
                    'Amounts in ${ProfileViewModel.currency}',
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
          subtitle: 'Name, username, photo and phone',
          onTap: _editProfile,
        ),
        ProfileMenuItem(
          icon: Icons.lock_outline_rounded,
          title: 'Security',
          subtitle: 'Change your password',
          onTap: () => context.push(Routes.security),
        ),
      ],
    ),
    const SizedBox(height: Dimens.sectionGap),
    ProfileMenuSection(
      title: 'Tracking',
      items: [
        ProfileMenuItem(
          icon: Icons.category_outlined,
          title: 'Categories',
          subtitle: 'Add, rename and reorder',
          onTap: () => context.push(Routes.categories),
        ),
        ProfileMenuItem(
          icon: Icons.sms_outlined,
          title: 'Payment messages',
          subtitle: 'Add MoMo and bank payments',
          onTap: () => context.push(Routes.detectedPayments),
        ),
        ProfileMenuItem(
          icon: Icons.file_download_outlined,
          title: 'Export data',
          subtitle: 'Your transactions as a CSV file',
          onTap: () => context.push(Routes.export),
        ),
      ],
    ),
    const SizedBox(height: Dimens.sectionGap),
    ProfileMenuSection(
      title: 'App',
      items: [
        ProfileMenuItem(
          icon: Icons.tune_rounded,
          title: 'Preferences',
          subtitle: 'Theme, payday, privacy and app lock',
          onTap: () => context.push(Routes.preferences),
        ),
        ProfileMenuItem(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          subtitle: 'Reminders and budget alerts',
          onTap: () => context.push(Routes.notificationSettings),
        ),
        ProfileMenuItem(
          icon: Icons.help_outline_rounded,
          title: 'Help',
          subtitle: 'Quick answers',
          onTap: () => showHelpSheet(context),
        ),
        ProfileMenuItem(
          icon: Icons.info_outline_rounded,
          title: 'About Expense Tracker',
          onTap: _showAbout,
        ),
      ],
    ),
  ];
}
