import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/centered_scroll_body.dart';
import '../../core/ui/form_error_slot.dart';
import '../../core/ui/labeled_text_field.dart';
import '../../core/ui/primary_button.dart';
import '../view_models/auth_error_message.dart';
import '../view_models/verify_email_view_model.dart';
import 'auth_header.dart';
import 'auth_switch_prompt.dart';

/// Enter the code emailed after sign-up to confirm the address. Success
/// signs in, and the router moves to Home.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.viewModel});

  final VerifyEmailViewModel viewModel;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.resend.addListener(_onResendChanged);
  }

  @override
  void dispose() {
    widget.viewModel.resend.removeListener(_onResendChanged);
    _code.dispose();
    super.dispose();
  }

  void _onResendChanged() {
    final command = widget.viewModel.resend;
    if (!mounted || command.running || command.result == null) return;
    final message = command.completed
        ? 'New code sent to ${widget.viewModel.email}.'
        : commandErrorMessage(command) ?? "Couldn't send a new code.";
    command.clearResult();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.viewModel.verify.execute(_code.text.trim());
  }

  void _backToSignIn() => context.go(Routes.login);

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            viewModel,
            viewModel.verify,
            viewModel.resend,
          ]),
          builder: (context, _) {
            final busy = viewModel.verify.running;
            return CenteredScrollBody(
              padding: const EdgeInsets.all(Dimens.screenPadding),
              children: [
                AuthHeader(
                  title: 'Confirm your email',
                  subtitle:
                      'We emailed ${viewModel.email}. Enter the code from '
                      'it below, or open its link and then sign in.',
                ),
                const SizedBox(height: Dimens.sectionGap + 10),
                FormErrorSlot(message: viewModel.errorMessage),
                Form(
                  key: _formKey,
                  child: LabeledTextField(
                    label: 'Code',
                    controller: _code,
                    hint: '6-digit code',
                    prefixIcon: Icons.pin_outlined,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: VerifyEmailViewModel.validateCode,
                    onChanged: (_) => viewModel.clearError(),
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(height: Dimens.sectionGap + 6),
                PrimaryButton(
                  label: 'Confirm email',
                  loading: busy,
                  onPressed: _submit,
                ),
                const SizedBox(height: Dimens.gapM),
                Center(
                  child: TextButton(
                    onPressed: viewModel.canResend && !busy
                        ? viewModel.resend.execute
                        : null,
                    child: Text(
                      viewModel.secondsUntilResend > 0
                          ? 'Send a new code in '
                                '${viewModel.secondsUntilResend}s'
                          : 'Send a new code',
                    ),
                  ),
                ),
                const SizedBox(height: Dimens.gapS),
                AuthSwitchPrompt(
                  question: 'Already confirmed?',
                  actionLabel: 'Sign in',
                  onPressed: busy ? null : _backToSignIn,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
