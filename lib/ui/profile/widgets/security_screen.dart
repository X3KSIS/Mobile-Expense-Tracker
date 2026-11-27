import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../utils/validators.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../../core/ui/form_error_slot.dart';
import '../../core/ui/labeled_text_field.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/screen_header.dart';
import '../view_models/security_view_model.dart';

/// Change the password: the current one to confirm, then the new one
/// twice.
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key, required this.viewModel});

  final SecurityViewModel viewModel;

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.changePassword.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.viewModel.changePassword.removeListener(_onChanged);
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted || !widget.viewModel.changePassword.completed) return;
    final messenger = ScaffoldMessenger.of(context);
    context.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Password changed')));
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.viewModel.changePassword.execute((
      current: _current.text,
      next: _next.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: viewModel.changePassword,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(
              Dimens.screenPadding,
              Dimens.gapL,
              Dimens.screenPadding,
              Dimens.screenPadding,
            ),
            children: [
              const ScreenHeader(title: 'Security'),
              const SizedBox(height: Dimens.sectionGap),
              Text(
                'Change the password for ${viewModel.email}.',
                style: context.text.body,
              ),
              const SizedBox(height: Dimens.sectionGap),
              FormErrorSlot(message: viewModel.errorMessage),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PasswordTextField(
                      controller: _current,
                      label: 'Current password',
                      textInputAction: TextInputAction.next,
                      validator: Validators.existingPassword,
                      onChanged: (_) => viewModel.clearError(),
                    ),
                    const SizedBox(height: Dimens.gapL),
                    PasswordTextField(
                      controller: _next,
                      label: 'New password',
                      helper:
                          'Use 8 or more characters with a letter and a '
                          'number.',
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: Validators.newPassword,
                      onChanged: (_) => viewModel.clearError(),
                    ),
                    const SizedBox(height: Dimens.gapL),
                    PasswordTextField(
                      controller: _confirm,
                      label: 'Confirm new password',
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: (value) =>
                          Validators.confirmPassword(value, _next.text),
                      onChanged: (_) => viewModel.clearError(),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Dimens.sectionGap + 10),
              PrimaryButton(
                label: 'Change password',
                loading: viewModel.changePassword.running,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
