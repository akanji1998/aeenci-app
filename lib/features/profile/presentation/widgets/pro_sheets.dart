import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/design/app_theme.dart';
import '../../../../core/design/components/app_button.dart';
import '../../../../core/design/components/app_text_field.dart';
import '../../../../core/design/components/confirm_dialog.dart';
import '../../../../core/utils/file_picker_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/professional_profile.dart';
import '../../domain/profile_inputs.dart';
import '../profile_providers.dart';
import 'form_sheet.dart';
import 'profile_widgets.dart';

/// Comportement commun des feuilles du profil pro : enregistrement,
/// erreurs 422 sous les champs, fermeture et confirmation.
mixin _SheetSaving<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool saving = false;
  ValidationException? errors;

  String? errorFor(String field) => errors?.errorFor(field);

  Future<void> run(Future<void> Function() action, {String? done}) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      saving = true;
      errors = null;
    });
    try {
      await action();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(done ?? l10n.savedDone)));
    } on ValidationException catch (error) {
      if (mounted) setState(() => errors = error);
    } on ApiException catch (error) {
      if (mounted) showSnack(context, saveErrorMessage(l10n, error));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> confirmThenRun(
    String message,
    Future<void> Function() action,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDialog(
      context,
      title: l10n.deleteConfirmTitle,
      message: message,
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
    );
    if (confirmed && mounted) await run(action, done: l10n.savedDone);
  }

  ProfessionalProfileController get profile =>
      ref.read(professionalProfileProvider.notifier);
}

/// « En bref » : titre, domaine, ville, présentation.
class SummarySheet extends ConsumerStatefulWidget {
  const SummarySheet({super.key, required this.profile});

  final ProfessionalProfile profile;

  @override
  ConsumerState<SummarySheet> createState() => _SummarySheetState();
}

class _SummarySheetState extends ConsumerState<SummarySheet> with _SheetSaving {
  late final _headline = TextEditingController(text: widget.profile.headline);
  late final _domain = TextEditingController(text: widget.profile.domain);
  late final _city = TextEditingController(text: widget.profile.city);
  late final _summary = TextEditingController(text: widget.profile.summary);

  @override
  void dispose() {
    for (final c in [_headline, _domain, _city, _summary]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _value(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FormSheet(
      title: l10n.proSummaryTitle,
      saving: saving,
      onSave: () => run(
        () => profile.updateFields({
          'headline': _value(_headline),
          'domain': _value(_domain),
          'city': _value(_city),
          'summary': _value(_summary),
        }),
      ),
      children: [
        FieldGap(
          child: AppTextField(
            label: l10n.fieldHeadline,
            hint: l10n.fieldHeadlineHint,
            controller: _headline,
            errorText: errorFor('headline'),
          ),
        ),
        FieldGap(
          child: AppTextField(
            label: l10n.fieldDomain,
            controller: _domain,
            errorText: errorFor('domain'),
          ),
        ),
        FieldGap(
          child: AppTextField(
            label: l10n.fieldCity,
            controller: _city,
            errorText: errorFor('city'),
          ),
        ),
        FieldGap(
          child: AppTextField(
            label: l10n.fieldSummary,
            hint: l10n.fieldSummaryHint,
            controller: _summary,
            maxLines: 5,
            errorText: errorFor('summary'),
          ),
        ),
      ],
    );
  }
}

/// Ajout d'une langue.
class LanguageSheet extends ConsumerStatefulWidget {
  const LanguageSheet({super.key, required this.profile});

  final ProfessionalProfile profile;

  @override
  ConsumerState<LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends ConsumerState<LanguageSheet>
    with _SheetSaving {
  final _name = TextEditingController();
  final _level = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _name.dispose();
    _level.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _localError = l10n.fieldRequired);
      return;
    }
    setState(() => _localError = null);
    final level = _level.text.trim();
    final languages = [
      ...widget.profile.languages,
      Language(name: name, level: level.isEmpty ? null : level),
    ];
    run(
      () => profile.updateFields({
        'languages': [for (final l in languages) l.toJson()],
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FormSheet(
      title: l10n.languageAdd,
      saving: saving,
      onSave: _save,
      children: [
        FieldGap(
          child: AppTextField(
            label: l10n.languageName,
            controller: _name,
            errorText: _localError ?? errorFor('languages'),
          ),
        ),
        FieldGap(
          child: AppTextField(
            label: l10n.languageLevel,
            hint: l10n.languageLevelHint,
            controller: _level,
          ),
        ),
      ],
    );
  }
}

/// Ajout ou modification d'une expérience.
class ExperienceSheet extends ConsumerStatefulWidget {
  const ExperienceSheet({super.key, this.experience});

  final Experience? experience;

  @override
  ConsumerState<ExperienceSheet> createState() => _ExperienceSheetState();
}

class _ExperienceSheetState extends ConsumerState<ExperienceSheet>
    with _SheetSaving {
  late final _title = TextEditingController(text: widget.experience?.title);
  late final _organization = TextEditingController(
    text: widget.experience?.organization,
  );
  late final _location = TextEditingController(
    text: widget.experience?.location,
  );
  late final _description = TextEditingController(
    text: widget.experience?.description,
  );
  late DateTime? _start = widget.experience?.startedOn;
  late DateTime? _end = widget.experience?.endedOn;
  late bool _current =
      widget.experience != null && widget.experience!.endedOn == null;
  String? _startError;

  @override
  void dispose() {
    for (final c in [_title, _organization, _location, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<DateTime?> _pickMonth(DateTime? initial) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(1970),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
    );
    // Seuls le mois et l'année comptent.
    return picked == null ? null : DateTime(picked.year, picked.month);
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final start = _start;
    if (start == null) {
      setState(() => _startError = l10n.fieldRequired);
      return;
    }
    setState(() => _startError = null);
    final input = ExperienceInput(
      title: _title.text,
      organization: _organization.text,
      location: _location.text,
      startedOn: start,
      endedOn: _current ? null : _end,
      description: _description.text,
    );
    run(() => profile.saveExperience(input, id: widget.experience?.id));
  }

  Widget _monthField(
    String label,
    DateTime? value,
    String? error,
    ValueChanged<DateTime> onPicked,
  ) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final text = value == null
        ? l10n.pickMonth
        : DateFormat.yMMMM(l10n.localeName).format(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Text(label, style: context.textTheme.titleSmall),
        ),
        const SizedBox(height: AppSpacing.space2),
        Semantics(
          button: true,
          label: '$label : $text',
          excludeSemantics: true,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              alignment: AlignmentDirectional.centerStart,
              side: BorderSide(color: error == null ? c.line : c.danger),
            ),
            icon: const Icon(LucideIcons.calendar),
            label: Text(text),
            onPressed: () async {
              final picked = await _pickMonth(value);
              if (picked != null) onPicked(picked);
            },
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space1),
            child: Text(
              error,
              style: context.textTheme.bodySmall?.copyWith(color: c.danger),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final experience = widget.experience;
    return FormSheet(
      title: experience == null ? l10n.experienceAdd : l10n.experienceEdit,
      saving: saving,
      onSave: _save,
      onDelete: experience == null
          ? null
          : () => confirmThenRun(
              l10n.experienceDeleteConfirm(experience.title),
              () => profile.deleteExperience(experience.id),
            ),
      children: [
        FieldGap(
          child: AppTextField(
            label: l10n.fieldPosition,
            controller: _title,
            errorText: errorFor('title'),
          ),
        ),
        FieldGap(
          child: AppTextField(
            label: l10n.fieldOrganization,
            controller: _organization,
            errorText: errorFor('organization'),
          ),
        ),
        FieldGap(
          child: AppTextField(
            label: l10n.fieldLocation,
            controller: _location,
            errorText: errorFor('location'),
          ),
        ),
        FieldGap(
          child: _monthField(
            l10n.fieldStart,
            _start,
            _startError ?? errorFor('started_on'),
            (d) => setState(() => _start = d),
          ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _current,
          title: Text(l10n.currentPosition),
          onChanged: (v) => setState(() => _current = v ?? false),
        ),
        if (!_current)
          FieldGap(
            child: _monthField(
              l10n.fieldEnd,
              _end,
              errorFor('ended_on'),
              (d) => setState(() => _end = d),
            ),
          ),
        FieldGap(
          child: AppTextField(
            label: l10n.fieldDescription,
            controller: _description,
            maxLines: 4,
            errorText: errorFor('description'),
          ),
        ),
      ],
    );
  }
}

/// Ajout ou modification d'une réalisation, avec un fichier facultatif.
class PortfolioSheet extends ConsumerStatefulWidget {
  const PortfolioSheet({super.key, this.item});

  final PortfolioItem? item;

  @override
  ConsumerState<PortfolioSheet> createState() => _PortfolioSheetState();
}

class _PortfolioSheetState extends ConsumerState<PortfolioSheet>
    with _SheetSaving {
  late final _title = TextEditingController(text: widget.item?.title);
  late final _description = TextEditingController(
    text: widget.item?.description,
  );
  late final _url = TextEditingController(text: widget.item?.url);
  PickedFile? _file;
  String? _fileError;

  @override
  void dispose() {
    for (final c in [_title, _description, _url]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    final l10n = AppLocalizations.of(context);
    final file = await ref.read(filePickerServiceProvider).pickDocument();
    if (file == null || !mounted) return;
    setState(() {
      if (file.size > maxUploadBytes) {
        _fileError = l10n.fileTooLarge;
        _file = null;
      } else {
        _fileError = null;
        _file = file;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final item = widget.item;
    final c = context.colors;
    final fileError = _fileError ?? errorFor('file');
    return FormSheet(
      title: item == null ? l10n.portfolioAdd : l10n.portfolioEdit,
      saving: saving,
      onSave: () => run(
        () => profile.savePortfolioItem(
          PortfolioInput(
            title: _title.text,
            description: _description.text,
            url: _url.text,
            filePath: _file?.path,
          ),
          id: item?.id,
        ),
      ),
      onDelete: item == null
          ? null
          : () => confirmThenRun(
              l10n.portfolioDeleteConfirm(item.title),
              () => profile.deletePortfolioItem(item.id),
            ),
      children: [
        FieldGap(
          child: AppTextField(
            label: l10n.fieldTitle,
            controller: _title,
            errorText: errorFor('title'),
          ),
        ),
        FieldGap(
          child: AppTextField(
            label: l10n.fieldDescription,
            controller: _description,
            maxLines: 3,
            errorText: errorFor('description'),
          ),
        ),
        FieldGap(
          child: AppTextField(
            label: l10n.fieldLink,
            controller: _url,
            keyboardType: TextInputType.url,
            errorText: errorFor('url'),
          ),
        ),
        FieldGap(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.fieldFile, style: context.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.space2),
              AppButton.secondary(
                label: l10n.pickFile,
                icon: LucideIcons.paperclip,
                compact: true,
                onPressed: saving ? null : _pick,
              ),
              if (_file != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.space1),
                  child: Text(
                    l10n.fileChosen(_file!.name),
                    style: context.textTheme.bodySmall,
                  ),
                ),
              Text(l10n.cvHintDocument, style: context.textTheme.bodySmall),
              if (fileError != null)
                Text(
                  fileError,
                  style: context.textTheme.bodySmall?.copyWith(color: c.danger),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Lien LinkedIn (vide : retiré).
class LinkedinSheet extends ConsumerStatefulWidget {
  const LinkedinSheet({super.key, required this.profile});

  final ProfessionalProfile profile;

  @override
  ConsumerState<LinkedinSheet> createState() => _LinkedinSheetState();
}

class _LinkedinSheetState extends ConsumerState<LinkedinSheet>
    with _SheetSaving {
  late final _url = TextEditingController(text: widget.profile.linkedinUrl);

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FormSheet(
      title: l10n.linkedinTitle,
      saving: saving,
      onSave: () => run(
        () => profile.updateFields({
          'linkedin_url': _url.text.trim().isEmpty ? null : _url.text.trim(),
        }),
      ),
      children: [
        FieldGap(
          child: AppTextField(
            label: l10n.linkedinTitle,
            hint: l10n.linkedinHint,
            controller: _url,
            keyboardType: TextInputType.url,
            errorText: errorFor('linkedin_url'),
          ),
        ),
      ],
    );
  }
}
