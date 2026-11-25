import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/form_error_banner.dart';
import '../../core/ui/labeled_text_field.dart';
import '../../core/ui/primary_button.dart';
import '../view_models/login_view_model.dart';
import 'auth_header.dart';
import 'auth_switch_prompt.dart';

/// Email and password sign-in, with "Forgot password?" and a link to
/// sign up.
///
/// Interface only for now: the form is not validated and any input signs
/// in (see `AuthRepositoryLocalFake`).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.viewModel});

  final LoginViewModel viewModel;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.resetPassword.addListener(_onResetChanged);
  }

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.resetPassword.removeListener(_onResetChanged);
      widget.viewModel.resetPassword.addListener(_onResetChanged);
    }
  }

  @override
  void dispose() {
    widget.viewModel.resetPassword.removeListener(_onResetChanged);
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _onResetChanged() {
    final command = widget.viewModel.resetPassword;
    if (command.running || command.result == null) return;
    final email = _email.text.trim();
    final message = command.completed
        ? "We've sent a password reset link to "
              '${email.isEmpty ? 'your email' : email}.'
        : "Couldn't send the reset link. Please try again.";
    command.clearResult();
    _showSnackBar(message);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    // TODO(auth): validate the form (Validators.email, existingPassword)
    // once real authentication is wired in.
    widget.viewModel.login.execute((
      email: _email.text,
      password: _password.text,
    ));
  }

  void _forgotPassword() => widget.viewModel.resetPassword.execute(_email.text);

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            viewModel.login,
            viewModel.resetPassword,
          ]),
          builder: (context, _) {
            final busy = viewModel.login.running;
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                Dimens.screenPadding,
                Dimens.sectionGap * 2,
                Dimens.screenPadding,
                Dimens.screenPadding,
              ),
              children: [
                const AuthHeader(
                  title: 'Welcome back',
                  subtitle: 'Sign in to keep track of where your kwacha goes.',
                ),
                const SizedBox(height: Dimens.sectionGap + 10),
                if (viewModel.errorMessage case final message?) ...[
                  FormErrorBanner(message: message),
                  const SizedBox(height: Dimens.sectionGap),
                ],
                _LoginForm(
                  formKey: _formKey,
                  email: _email,
                  password: _password,
                  onChanged: (_) => viewModel.clearError(),
                  onSubmit: _submit,
                  onForgotPassword: viewModel.resetPassword.running || busy
                      ? null
                      : _forgotPassword,
                ),
                const SizedBox(height: Dimens.sectionGap + 6),
                PrimaryButton(
                  label: 'Sign in',
                  loading: busy,
                  onPressed: _submit,
                ),
                const SizedBox(height: Dimens.gapL),
                AuthSwitchPrompt(
                  question: "Don't have an account?",
                  actionLabel: 'Sign up',
                  onPressed: busy ? null : () => context.push(Routes.signUp),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.email,
    required this.password,
    required this.onChanged,
    required this.onSubmit,
    required this.onForgotPassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback? onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LabeledTextField(
              label: 'Email',
              controller: email,
              hint: 'you@example.com',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              onChanged: onChanged,
            ),
            const SizedBox(height: Dimens.gapL),
            PasswordTextField(
              controller: password,
              hint: 'Your password',
              textInputAction: TextInputAction.done,
              onChanged: onChanged,
              onFieldSubmitted: (_) => onSubmit(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onForgotPassword,
                child: const Text('Forgot password?'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
