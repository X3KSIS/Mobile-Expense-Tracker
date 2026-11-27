import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../../utils/validators.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/centered_scroll_body.dart';
import '../../core/ui/form_error_slot.dart';
import '../../core/ui/header_icon_button.dart';
import '../../core/ui/labeled_text_field.dart';
import '../../core/ui/primary_button.dart';
import '../view_models/sign_up_view_model.dart';
import 'auth_header.dart';
import 'auth_switch_prompt.dart';

/// Create an account with name, email and password.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, required this.viewModel});

  final SignUpViewModel viewModel;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.viewModel.signUp.execute((
      name: _name.text,
      email: _email.text,
      password: _password.text,
    ));
  }

  void _backToLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: viewModel.signUp,
          builder: (context, _) {
            final busy = viewModel.signUp.running;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Dimens.screenPadding,
                    Dimens.gapL,
                    Dimens.screenPadding,
                    0,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: HeaderIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Back to sign in',
                      onPressed: busy ? () {} : _backToLogin,
                    ),
                  ),
                ),
                Expanded(
                  child: CenteredScrollBody(
                    padding: const EdgeInsets.all(Dimens.screenPadding),
                    children: [
                      const AuthHeader(
                        title: 'Create your account',
                        subtitle:
                            'Track income, expenses and budgets in kwacha.',
                      ),
                      const SizedBox(height: Dimens.sectionGap + 10),
                      FormErrorSlot(message: viewModel.errorMessage),
                      _SignUpForm(
                        formKey: _formKey,
                        name: _name,
                        email: _email,
                        password: _password,
                        confirm: _confirm,
                        onChanged: (_) => viewModel.clearError(),
                        onSubmit: _submit,
                      ),
                      const SizedBox(height: Dimens.sectionGap + 10),
                      PrimaryButton(
                        label: 'Create account',
                        loading: busy,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: Dimens.gapL),
                      AuthSwitchPrompt(
                        question: 'Already have an account?',
                        actionLabel: 'Sign in',
                        onPressed: busy ? null : _backToLogin,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SignUpForm extends StatelessWidget {
  const _SignUpForm({
    required this.formKey,
    required this.name,
    required this.email,
    required this.password,
    required this.confirm,
    required this.onChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController confirm;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LabeledTextField(
              label: 'Full name',
              controller: name,
              hint: 'e.g. Mwila Banda',
              prefixIcon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: Validators.name,
              onChanged: onChanged,
            ),
            const SizedBox(height: Dimens.gapL),
            LabeledTextField(
              label: 'Email',
              controller: email,
              hint: 'you@example.com',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: Validators.email,
              onChanged: onChanged,
            ),
            const SizedBox(height: Dimens.gapL),
            PasswordTextField(
              controller: password,
              hint: 'At least 8 characters',
              helper: 'Use 8 or more characters with a letter and a number.',
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: Validators.newPassword,
              onChanged: onChanged,
            ),
            const SizedBox(height: Dimens.gapL),
            PasswordTextField(
              controller: confirm,
              label: 'Confirm password',
              hint: 'Type it again',
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              validator: (value) =>
                  Validators.confirmPassword(value, password.text),
              onChanged: onChanged,
              onFieldSubmitted: (_) => onSubmit(),
            ),
          ],
        ),
      ),
    );
  }
}
