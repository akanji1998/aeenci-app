import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/components/app_button.dart';
import '../../../core/design/components/app_text_field.dart';
import '../../../core/design/components/member_avatar.dart';
import '../../../core/domain/enums.dart';
import '../../../core/l10n/enum_labels.dart';
import '../../../core/utils/file_picker_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/session_controller.dart';
import '../../card/presentation/card_status_label.dart';
import '../data/profile_repository.dart';
import '../domain/member.dart';
import '../domain/profile_inputs.dart';
import 'profile_providers.dart';
import 'widgets/profile_widgets.dart';

/// Ma fiche : photo, identité (lecture seule), contacts, adhésion.
class ProfileSheetScreen extends ConsumerWidget {
  const ProfileSheetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(sessionControllerProvider);
    final member = session is SessionMember ? session.member : null;
    final educations = ref.watch(educationsProvider).value?.data;
    final date = DateFormat.yMMMMd(l10n.localeName);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sheetTitle)),
      body: member == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.space4),
              children: [
                _PhotoSection(member: member),
                ProfileSection(
                  title: l10n.identityTitle,
                  children: [
                    KeyValue(
                      label: l10n.identityName,
                      value: '${member.lastName} ${member.firstNames}',
                    ),
                    KeyValue(
                      label: l10n.identityBirth,
                      value:
                          '${date.format(member.birthDate)} · '
                          '${member.birthPlace}',
                    ),
                    KeyValue(
                      label: l10n.identityNationality,
                      value: member.nationality,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(l10n.identityNote, style: context.textTheme.bodySmall),
                  ],
                ),
                _ContactsSection(member: member),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space4),
                  child: SettingsGroup(
                    children: [
                      NavRow(
                        title: l10n.educationTitle,
                        subtitle: educations == null
                            ? null
                            : l10n.educationCount(educations.length),
                        onTap: () => context.go(AppRoutes.profileEducation),
                      ),
                    ],
                  ),
                ),
                ProfileSection(
                  title: l10n.membershipTitle,
                  children: [
                    KeyValue(
                      label: l10n.membershipStatus,
                      value: cardStatusLabel(
                        l10n,
                        status: member.status ?? MemberStatus.member,
                        engagement: member.engagement,
                        gender: member.gender,
                      ),
                    ),
                    KeyValue(
                      label: l10n.membershipCategory,
                      value: member.category.label(l10n),
                    ),
                    if (member.memberNumber != null)
                      KeyValue(
                        label: l10n.membershipNumber,
                        value: member.memberNumber!,
                      ),
                    if (member.joinedAt != null)
                      KeyValue(
                        label: l10n.membershipSince,
                        value: date.format(member.joinedAt!),
                      ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      l10n.membershipNote,
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _PhotoSection extends ConsumerStatefulWidget {
  const _PhotoSection({required this.member});

  final Member member;

  @override
  ConsumerState<_PhotoSection> createState() => _PhotoSectionState();
}

class _PhotoSectionState extends ConsumerState<_PhotoSection> {
  bool _busy = false;

  Future<void> _change() async {
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: Text(l10n.photoFromGallery),
              onTap: () => Navigator.of(context).pop(PhotoSource.gallery),
            ),
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: Text(l10n.photoFromCamera),
              onTap: () => Navigator.of(context).pop(PhotoSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final file = await ref.read(filePickerServiceProvider).pickPhoto(source);
    if (file == null || !mounted) return;
    if (file.size > maxUploadBytes) {
      showSnack(context, l10n.photoTooLarge);
      return;
    }
    setState(() => _busy = true);
    try {
      final member = await ref
          .read(profileRepositoryProvider)
          .updatePhoto(file.path);
      await ref.read(sessionControllerProvider.notifier).updateMember(member);
      if (mounted) showSnack(context, l10n.photoUpdated);
    } on ApiException catch (error) {
      if (mounted) showSnack(context, saveErrorMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final member = widget.member;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space4),
      child: Row(
        children: [
          MemberAvatar(
            name: '${member.firstNames} ${member.lastName}',
            photoUrl: member.photoUrl,
            size: 80,
          ),
          const SizedBox(width: AppSpacing.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppButton.secondary(
                  label: l10n.changePhoto,
                  icon: LucideIcons.camera,
                  compact: true,
                  loading: _busy,
                  onPressed: _change,
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(l10n.photoHint, style: context.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactsSection extends ConsumerStatefulWidget {
  const _ContactsSection({required this.member});

  final Member member;

  @override
  ConsumerState<_ContactsSection> createState() => _ContactsSectionState();
}

class _ContactsSectionState extends ConsumerState<_ContactsSection> {
  bool _editing = false;
  bool _saving = false;
  ValidationException? _errors;
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();

  @override
  void dispose() {
    for (final c in [_phone, _whatsapp, _email, _address, _city]) {
      c.dispose();
    }
    super.dispose();
  }

  void _startEditing() {
    final m = widget.member;
    _phone.text = m.phone;
    _whatsapp.text = m.whatsapp ?? '';
    _email.text = m.email;
    _address.text = m.address ?? '';
    _city.text = m.city;
    setState(() {
      _editing = true;
      _errors = null;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _errors = null;
    });
    try {
      final member = await ref
          .read(profileRepositoryProvider)
          .updateContacts(
            ContactUpdate(
              phone: _phone.text,
              whatsapp: _whatsapp.text,
              email: _email.text,
              address: _address.text,
              city: _city.text,
            ),
          );
      await ref.read(sessionControllerProvider.notifier).updateMember(member);
      if (!mounted) return;
      setState(() => _editing = false);
      showSnack(context, l10n.savedDone);
    } on ValidationException catch (error) {
      if (mounted) setState(() => _errors = error);
    } on ApiException catch (error) {
      if (mounted) showSnack(context, saveErrorMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final m = widget.member;
    String orNone(String? v) => v == null || v.isEmpty ? l10n.notProvided : v;

    if (!_editing) {
      return ProfileSection(
        title: l10n.contactsTitle,
        action: AppButton.text(
          label: l10n.edit,
          compact: true,
          onPressed: _startEditing,
        ),
        children: [
          KeyValue(label: l10n.fieldPhone, value: m.phone),
          KeyValue(label: l10n.fieldWhatsapp, value: orNone(m.whatsapp)),
          KeyValue(label: l10n.fieldEmail, value: m.email),
          KeyValue(label: l10n.fieldAddress, value: orNone(m.address)),
          KeyValue(label: l10n.fieldCity, value: m.city),
        ],
      );
    }

    Widget field(
      String label,
      TextEditingController controller,
      String key, {
      TextInputType? keyboard,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: AppTextField(
        label: label,
        controller: controller,
        keyboardType: keyboard,
        errorText: _errors?.errorFor(key),
        textInputAction: TextInputAction.next,
      ),
    );

    return ProfileSection(
      title: l10n.contactsTitle,
      children: [
        field(l10n.fieldPhone, _phone, 'phone', keyboard: TextInputType.phone),
        field(
          l10n.fieldWhatsapp,
          _whatsapp,
          'whatsapp',
          keyboard: TextInputType.phone,
        ),
        field(
          l10n.fieldEmail,
          _email,
          'email',
          keyboard: TextInputType.emailAddress,
        ),
        field(l10n.fieldAddress, _address, 'address'),
        field(l10n.fieldCity, _city, 'city'),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            AppButton.text(
              label: l10n.cancel,
              onPressed: _saving
                  ? null
                  : () => setState(() {
                      _editing = false;
                      _errors = null;
                    }),
            ),
            AppButton(label: l10n.save, loading: _saving, onPressed: _save),
          ],
        ),
      ],
    );
  }
}
