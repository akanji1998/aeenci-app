import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/components/app_button.dart';
import '../../../core/design/components/app_card.dart';
import '../../../core/design/components/async_view.dart';
import '../../../core/utils/device_services.dart';
import '../../../core/utils/file_picker_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/professional_profile.dart';
import '../domain/profile_rules.dart';
import 'profile_providers.dart';
import 'widgets/form_sheet.dart';
import 'widgets/pro_sheets.dart';
import 'widgets/profile_widgets.dart';

/// Profil professionnel : ce que verront les recruteurs dans la vitrine.
class ProProfileScreen extends ConsumerWidget {
  const ProProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.proTitle)),
      body: AsyncView<ProfessionalProfile>(
        value: ref.watch(professionalProfileProvider),
        onRetry: () => ref.invalidate(professionalProfileProvider),
        builder: (context, profile) => ListView(
          padding: const EdgeInsets.all(AppSpacing.space4),
          children: [
            _CompletionCard(profile: profile),
            _SummarySection(profile: profile),
            _SkillsSection(profile: profile),
            _LanguagesSection(profile: profile),
            _ExperiencesSection(profile: profile),
            _CvSection(profile: profile),
            _LinkedinSection(profile: profile),
          ],
        ),
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.profile});

  final ProfessionalProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final percent = profileCompletion(profile);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space4),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.proCompletionLabel(percent),
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.space2),
            ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: percent / 100,
                  minHeight: 8,
                  color: c.blue,
                  backgroundColor: c.line,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(l10n.proCompletionHint, style: context.textTheme.bodySmall),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppButton.text(
                label: l10n.proShowcaseLink,
                compact: true,
                onPressed: () => context.go(AppRoutes.profile),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.profile});

  final ProfessionalProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String orNone(String? v) => v == null || v.isEmpty ? l10n.notProvided : v;
    return ProfileSection(
      title: l10n.proSummaryTitle,
      action: AppButton.text(
        label: l10n.edit,
        compact: true,
        onPressed: () =>
            showFormSheet(context, (_) => SummarySheet(profile: profile)),
      ),
      children: [
        KeyValue(label: l10n.fieldHeadline, value: orNone(profile.headline)),
        KeyValue(label: l10n.fieldDomain, value: orNone(profile.domain)),
        KeyValue(label: l10n.fieldCity, value: orNone(profile.city)),
        KeyValue(label: l10n.fieldSummary, value: orNone(profile.summary)),
      ],
    );
  }
}

class _SkillsSection extends ConsumerStatefulWidget {
  const _SkillsSection({required this.profile});

  final ProfessionalProfile profile;

  @override
  ConsumerState<_SkillsSection> createState() => _SkillsSectionState();
}

class _SkillsSectionState extends ConsumerState<_SkillsSection> {
  final _input = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _save(List<String> skills) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(professionalProfileProvider.notifier).updateFields({
        'skills': skills,
      });
      _input.clear();
    } on ValidationException catch (error) {
      if (mounted) setState(() => _error = saveErrorMessage(l10n, error));
    } on ApiException catch (error) {
      if (mounted) showSnack(context, saveErrorMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _add() {
    final skill = _input.text.trim();
    final skills = widget.profile.skills;
    if (skill.isEmpty) return;
    if (skills.any((s) => s.toLowerCase() == skill.toLowerCase())) {
      _input.clear();
      return;
    }
    _save([...skills, skill]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final skills = widget.profile.skills;
    return ProfileSection(
      title: l10n.skillsTitle,
      children: [
        if (skills.isEmpty)
          Text(l10n.skillsEmpty, style: context.textTheme.bodySmall)
        else
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: [
              for (final skill in skills)
                InputChip(
                  label: Text(skill),
                  shape: const StadiumBorder(),
                  deleteButtonTooltipMessage: l10n.skillRemove(skill),
                  onDeleted: _busy
                      ? null
                      : () => _save([...skills]..remove(skill)),
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.space3),
        Semantics(
          label: l10n.skillNew,
          child: TextField(
            controller: _input,
            enabled: !_busy,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _add(),
            decoration: InputDecoration(
              hintText: l10n.skillHint,
              errorText: _error,
              suffixIcon: IconButton(
                tooltip: l10n.add,
                icon: const Icon(LucideIcons.plus),
                onPressed: _busy ? null : _add,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LanguagesSection extends ConsumerWidget {
  const _LanguagesSection({required this.profile});

  final ProfessionalProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final languages = profile.languages;

    Future<void> remove(Language language) async {
      final rest = [...languages]..remove(language);
      try {
        await ref.read(professionalProfileProvider.notifier).updateFields({
          'languages': [for (final l in rest) l.toJson()],
        });
      } on ApiException catch (error) {
        if (context.mounted) showSnack(context, saveErrorMessage(l10n, error));
      }
    }

    return ProfileSection(
      title: l10n.languagesTitle,
      children: [
        if (languages.isEmpty)
          Text(l10n.languagesEmpty, style: context.textTheme.bodySmall),
        for (final language in languages)
          Row(
            children: [
              Expanded(
                child: Text(
                  language.level == null
                      ? language.name
                      : '${language.name} · ${language.level}',
                  style: context.textTheme.bodyMedium,
                ),
              ),
              IconButton(
                tooltip: l10n.languageRemove(language.name),
                icon: const Icon(LucideIcons.x),
                onPressed: () => remove(language),
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.space2),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppButton.secondary(
            label: l10n.languageAdd,
            icon: LucideIcons.plus,
            compact: true,
            onPressed: () =>
                showFormSheet(context, (_) => LanguageSheet(profile: profile)),
          ),
        ),
      ],
    );
  }
}

class _ExperiencesSection extends StatelessWidget {
  const _ExperiencesSection({required this.profile});

  final ProfessionalProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final month = DateFormat.yMMMM(l10n.localeName);
    final experiences = [...profile.experiences]
      ..sort((a, b) => b.startedOn.compareTo(a.startedOn));
    return ProfileSection(
      title: l10n.experiencesTitle,
      children: [
        if (experiences.isEmpty)
          Text(l10n.experiencesEmpty, style: context.textTheme.bodySmall),
        for (final e in experiences)
          Semantics(
            button: true,
            hint: l10n.experienceEdit,
            child: InkWell(
              onTap: () =>
                  showFormSheet(context, (_) => ExperienceSheet(experience: e)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.space2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.title, style: context.textTheme.titleMedium),
                      Text(
                        [e.organization, ?e.location].join(' · '),
                        style: context.textTheme.bodyMedium,
                      ),
                      Text(
                        l10n.experiencePeriod(
                          month.format(e.startedOn),
                          e.endedOn == null
                              ? l10n.today
                              : month.format(e.endedOn!),
                        ),
                        style: context.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.space2),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppButton.secondary(
            label: l10n.experienceAdd,
            icon: LucideIcons.plus,
            compact: true,
            onPressed: () =>
                showFormSheet(context, (_) => const ExperienceSheet()),
          ),
        ),
      ],
    );
  }
}

class _CvSection extends ConsumerStatefulWidget {
  const _CvSection({required this.profile});

  final ProfessionalProfile profile;

  @override
  ConsumerState<_CvSection> createState() => _CvSectionState();
}

class _CvSectionState extends ConsumerState<_CvSection> {
  bool _busy = false;

  Future<void> _upload() async {
    final l10n = AppLocalizations.of(context);
    final file = await ref.read(filePickerServiceProvider).pickPdf();
    if (file == null || !mounted) return;
    if (file.size > maxUploadBytes) {
      showSnack(context, l10n.cvTooLarge);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(professionalProfileProvider.notifier).uploadCv(file.path);
      if (mounted) showSnack(context, l10n.cvUploaded);
    } on ApiException catch (error) {
      if (mounted) showSnack(context, saveErrorMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = widget.profile;
    final cv = profile.cvUrl;
    final devices = ref.read(deviceServicesProvider);
    return ProfileSection(
      title: l10n.cvTitle,
      children: [
        Row(
          children: [
            const ExcludeSemantics(child: Icon(LucideIcons.fileText)),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cv == null ? l10n.cvNone : l10n.cvPresent,
                    style: context.textTheme.titleMedium,
                  ),
                  Text(l10n.cvHint, style: context.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            AppButton.secondary(
              label: cv == null ? l10n.cvUpload : l10n.cvReplace,
              icon: LucideIcons.upload,
              compact: true,
              loading: _busy,
              onPressed: _upload,
            ),
            if (cv != null)
              AppButton.text(
                label: l10n.cvView,
                compact: true,
                onPressed: () => devices.openUrl(cv),
              ),
          ],
        ),
        const Divider(height: AppSpacing.space6),
        Text(l10n.portfolioTitle, style: context.textTheme.titleMedium),
        if (profile.portfolio.isEmpty)
          Text(l10n.portfolioEmpty, style: context.textTheme.bodySmall),
        for (final item in profile.portfolio)
          Semantics(
            button: true,
            hint: l10n.portfolioEdit,
            child: InkWell(
              onTap: () =>
                  showFormSheet(context, (_) => PortfolioSheet(item: item)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.space2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: context.textTheme.bodyLarge),
                      if (item.description != null)
                        Text(
                          item.description!,
                          style: context.textTheme.bodySmall,
                        ),
                      if (item.url != null)
                        Text(item.url!, style: context.textTheme.bodySmall),
                      if (item.fileUrl != null)
                        Text(
                          l10n.portfolioFile,
                          style: context.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.space2),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppButton.secondary(
            label: l10n.portfolioAdd,
            icon: LucideIcons.plus,
            compact: true,
            onPressed: () =>
                showFormSheet(context, (_) => const PortfolioSheet()),
          ),
        ),
      ],
    );
  }
}

class _LinkedinSection extends StatelessWidget {
  const _LinkedinSection({required this.profile});

  final ProfessionalProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsGroup(
      children: [
        NavRow(
          title: profile.linkedinUrl == null
              ? l10n.linkedinNone
              : l10n.linkedinTitle,
          subtitle: profile.linkedinUrl,
          onTap: () =>
              showFormSheet(context, (_) => LinkedinSheet(profile: profile)),
        ),
      ],
    );
  }
}
