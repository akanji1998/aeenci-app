import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/components/app_button.dart';
import '../../../core/design/components/app_card.dart';
import '../../../core/design/components/app_text_field.dart';
import '../../../core/design/components/async_view.dart';
import '../../../core/design/components/confirm_dialog.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/education.dart';
import '../domain/profile_inputs.dart';
import 'profile_providers.dart';
import 'widgets/form_sheet.dart';
import 'widgets/profile_widgets.dart';

/// Parcours scolaire : liste, ajout, modification, suppression.
class EducationScreen extends ConsumerWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final levels = ref.watch(educationLevelsProvider).value?.data ?? const [];
    String levelLabel(String value) =>
        levels.where((l) => l.value == value).firstOrNull?.label ?? value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.educationTitle)),
      body: AsyncView<List<Education>>(
        value: ref.watch(educationsProvider),
        onRetry: () => ref.invalidate(educationsProvider),
        builder: (context, list) => ListView(
          padding: const EdgeInsets.all(AppSpacing.space4),
          children: [
            Text(l10n.educationIntro, style: context.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.space4),
            if (list.isEmpty)
              AppCard(child: Text(l10n.educationEmpty))
            else
              for (final education in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                  child: _EducationCard(
                    education: education,
                    levelLabel: levelLabel(education.level),
                    onTap: () => _openSheet(context, education: education),
                  ),
                ),
            const SizedBox(height: AppSpacing.space2),
            AppButton.secondary(
              label: l10n.educationAdd,
              icon: LucideIcons.plus,
              expand: true,
              onPressed: () => _openSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext context, {Education? education}) =>
      showFormSheet(context, (_) => EducationSheet(education: education));
}

class _EducationCard extends StatelessWidget {
  const _EducationCard({
    required this.education,
    required this.levelLabel,
    required this.onTap,
  });

  final Education education;
  final String levelLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final e = education;
    final years = e.startYear == null && e.endYear == null
        ? null
        : l10n.educationYears(
            e.startYear?.toString() ?? '…',
            e.endYear?.toString() ?? l10n.inProgress,
          );
    return Semantics(
      button: true,
      hint: l10n.educationEdit,
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space1,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  levelLabel,
                  style: AppTypography.label.toTextStyle(color: c.blue),
                ),
                if (years != null)
                  Text(years, style: context.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(e.school, style: context.textTheme.titleMedium),
            Text(e.fieldOfStudy, style: context.textTheme.bodyMedium),
            if (e.diploma != null)
              Text(e.diploma!, style: context.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Feuille d'ajout ou de modification d'une formation.
class EducationSheet extends ConsumerStatefulWidget {
  const EducationSheet({super.key, this.education});

  final Education? education;

  @override
  ConsumerState<EducationSheet> createState() => _EducationSheetState();
}

class _EducationSheetState extends ConsumerState<EducationSheet> {
  late String? _level = widget.education?.level;
  late final _school = TextEditingController(text: widget.education?.school);
  late final _study = TextEditingController(
    text: widget.education?.fieldOfStudy,
  );
  late final _diploma = TextEditingController(text: widget.education?.diploma);
  late final _start = TextEditingController(
    text: widget.education?.startYear?.toString(),
  );
  late final _end = TextEditingController(
    text: widget.education?.endYear?.toString(),
  );
  bool _saving = false;
  ValidationException? _errors;
  final Map<String, String> _localErrors = {};

  @override
  void dispose() {
    for (final c in [_school, _study, _diploma, _start, _end]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _error(String field) =>
      _localErrors[field] ?? _errors?.errorFor(field);

  /// Année vide → `null` ; sinon 4 chiffres.
  int? _year(TextEditingController controller, String field) {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    final year = int.tryParse(text);
    if (year == null || text.length != 4) {
      _localErrors[field] = AppLocalizations.of(context).invalidYear;
    }
    return year;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    _localErrors.clear();
    final start = _year(_start, 'start_year');
    final end = _year(_end, 'end_year');
    if (_localErrors.isNotEmpty) {
      setState(() => _errors = null);
      return;
    }
    setState(() {
      _saving = true;
      _errors = null;
    });
    try {
      await ref
          .read(educationsProvider.notifier)
          .save(
            EducationInput(
              level: _level ?? '',
              school: _school.text,
              fieldOfStudy: _study.text,
              diploma: _diploma.text,
              startYear: start,
              endYear: end,
            ),
            id: widget.education?.id,
          );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.savedDone)));
    } on ValidationException catch (error) {
      if (mounted) setState(() => _errors = error);
    } on ApiException catch (error) {
      if (mounted) showSnack(context, saveErrorMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final education = widget.education!;
    final confirmed = await confirmDialog(
      context,
      title: l10n.educationDelete,
      message: l10n.educationDeleteConfirm(education.school),
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
    );
    if (!confirmed || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref.read(educationsProvider.notifier).delete(education.id);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        showSnack(context, saveErrorMessage(l10n, error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final levels = ref.watch(educationLevelsProvider).value?.data ?? const [];
    final editing = widget.education != null;
    return FormSheet(
      title: editing ? l10n.educationEdit : l10n.educationAdd,
      saving: _saving,
      onSave: _save,
      onDelete: editing ? _delete : null,
      deleteLabel: l10n.educationDelete,
      children: [
        FieldGap(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExcludeSemantics(
                child: Text(
                  l10n.fieldLevel,
                  style: context.textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              DropdownButtonFormField<String>(
                initialValue: levels.any((l) => l.value == _level)
                    ? _level
                    : null,
                isExpanded: true,
                decoration: InputDecoration(errorText: _error('level')),
                hint: Text(l10n.fieldLevel),
                items: [
                  for (final level in levels)
                    DropdownMenuItem(
                      value: level.value,
                      child: Text(level.label),
                    ),
                ],
                onChanged: (value) => setState(() => _level = value),
              ),
            ],
          ),
        ),
        FieldGap(
          child: AppTextField(
            label: l10n.fieldSchool,
            controller: _school,
            errorText: _error('school'),
          ),
        ),
        FieldGap(
          child: AppTextField(
            label: l10n.fieldStudy,
            controller: _study,
            errorText: _error('field_of_study'),
          ),
        ),
        FieldGap(
          child: AppTextField(
            label: l10n.fieldDiploma,
            controller: _diploma,
            errorText: _error('diploma'),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FieldGap(
                child: AppTextField(
                  label: l10n.fieldStartYear,
                  hint: l10n.yearHint,
                  controller: _start,
                  keyboardType: TextInputType.number,
                  errorText: _error('start_year'),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: FieldGap(
                child: AppTextField(
                  label: l10n.fieldEndYear,
                  hint: l10n.endYearHint,
                  controller: _end,
                  keyboardType: TextInputType.number,
                  errorText: _error('end_year'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
