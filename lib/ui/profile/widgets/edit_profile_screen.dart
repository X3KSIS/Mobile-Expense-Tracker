import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../utils/phone.dart';
import '../../../utils/validators.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/form_error_slot.dart';
import '../../core/ui/labeled_text_field.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/screen_header.dart';
import '../view_models/edit_profile_view_model.dart';
import 'profile_photo_picker.dart';

/// Edit the user's photo, name and phone number. Email is read-only.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.viewModel});

  final EditProfileViewModel viewModel;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    final user = widget.viewModel.user;
    final phone = user?.phone;
    _name = TextEditingController(text: user?.name ?? '');
    _email = TextEditingController(text: user?.email ?? '');
    _phone = TextEditingController(
      text: phone == null ? '' : formatPhone(phone),
    );
    widget.viewModel.save.addListener(_onSaveChanged);
    widget.viewModel.setPhoto.addListener(_onPhotoChanged);
  }

  @override
  void didUpdateWidget(covariant EditProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.save.removeListener(_onSaveChanged);
      widget.viewModel.save.addListener(_onSaveChanged);
    }
  }

  @override
  void dispose() {
    widget.viewModel.save.removeListener(_onSaveChanged);
    widget.viewModel.setPhoto.removeListener(_onPhotoChanged);
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _onSaveChanged() {
    if (!widget.viewModel.save.completed || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    context.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  void _onPhotoChanged() {
    final command = widget.viewModel.setPhoto;
    if (!mounted || command.running || command.result == null) return;
    final message = command.completed
        ? 'Photo saved'
        : "Couldn't save the photo. Please try again.";
    command.clearResult();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Picks a photo from the gallery, shrunk to at most 512px so it is
  /// small to store and sync.
  Future<void> _choosePhoto() async {
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open your photos.")),
      );
      return;
    }
    if (file == null) return;
    final bytes = await file.readAsBytes();
    widget.viewModel.setPhoto.execute(bytes);
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.viewModel.save.execute((name: _name.text, phone: _phone.text));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            viewModel,
            viewModel.save,
            viewModel.setPhoto,
          ]),
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(
              Dimens.screenPadding,
              Dimens.gapL,
              Dimens.screenPadding,
              Dimens.screenPadding,
            ),
            children: [
              const ScreenHeader(title: 'Personal details'),
              const SizedBox(height: Dimens.sectionGap + 6),
              ProfilePhotoPicker(
                initials: viewModel.initials,
                photo: viewModel.photo,
                busy: viewModel.setPhoto.running,
                onChoose: _choosePhoto,
                onRemove: () => viewModel.setPhoto.execute(null),
              ),
              const SizedBox(height: Dimens.sectionGap),
              FormErrorSlot(message: viewModel.errorMessage),
              _EditProfileForm(
                formKey: _formKey,
                name: _name,
                email: _email,
                phone: _phone,
                onChanged: (_) => viewModel.clearError(),
                onSubmit: _submit,
              ),
              const SizedBox(height: Dimens.sectionGap + 10),
              PrimaryButton(
                label: 'Save changes',
                loading: viewModel.save.running,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditProfileForm extends StatelessWidget {
  const _EditProfileForm({
    required this.formKey,
    required this.name,
    required this.email,
    required this.phone,
    required this.onChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController phone;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledTextField(
            label: 'Full name',
            controller: name,
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
            prefixIcon: Icons.mail_outline_rounded,
            helper: "Your email can't be changed yet.",
            enabled: false,
          ),
          const SizedBox(height: Dimens.gapL),
          LabeledTextField(
            label: 'Phone number (optional)',
            controller: phone,
            hint: '097 123 4567',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumber],
            validator: Validators.optionalPhone,
            onChanged: onChanged,
            onFieldSubmitted: (_) => onSubmit(),
          ),
        ],
      ),
    );
  }
}
