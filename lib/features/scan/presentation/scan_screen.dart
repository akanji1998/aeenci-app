import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/config/env_config.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/components/app_button.dart';
import '../../../core/design/components/empty_state.dart';
import '../../../core/design/components/error_state.dart';
import '../../../core/design/components/skeleton.dart';
import '../../../core/mock/mock_card_signer.dart';
import '../../../core/mock/mock_data.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/attendance_scan.dart';
import 'scan_controller.dart';

/// Vue de la caméra : remplacée dans les tests (pas de caméra).
typedef ScannerViewBuilder =
    Widget Function(BuildContext context, ValueChanged<String> onCode);

final scannerViewProvider = Provider<ScannerViewBuilder>(
  (ref) =>
      (context, onCode) => CameraScanner(onCode: onCode),
);

/// Scan des présences (maquette `app-scan`), avec `attendance.scan`.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  int? _meetingId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final meetings = ref.watch(attendanceMeetingsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenScan)),
      body: meetings.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.space4),
          child: SkeletonList(),
        ),
        error: (error, _) => Center(
          child: SingleChildScrollView(
            child: ErrorState(
              error: error,
              onRetry: () => ref.invalidate(attendanceMeetingsProvider),
            ),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  icon: LucideIcons.calendarX,
                  title: l10n.scanNoMeeting,
                  message: l10n.scanNoMeetingHint,
                ),
              ),
            );
          }
          final meeting =
              list.where((m) => m.id == _meetingId).firstOrNull ?? list.first;
          return _ScanSession(
            key: ValueKey(meeting.id),
            meeting: meeting,
            meetings: list,
            onChoose: (m) => setState(() => _meetingId = m.id),
          );
        },
      ),
    );
  }
}

class _ScanSession extends ConsumerWidget {
  const _ScanSession({
    super.key,
    required this.meeting,
    required this.meetings,
    required this.onChoose,
  });

  final AttendanceMeeting meeting;
  final List<AttendanceMeeting> meetings;
  final ValueChanged<AttendanceMeeting> onChoose;

  static String _label(AppLocalizations l10n, AttendanceMeeting m) =>
      [l10n.scanMeetingLabel(m.date), ?m.location].join(' · ');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final provider = scanControllerProvider(meeting);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final scanner = ref.watch(scannerViewProvider);
    final env = ref.watch(envConfigProvider);

    // Retour immédiat : vibration et son à chaque nouveau résultat.
    ref.listen(provider.select((s) => s.feedback?.serial), (previous, next) {
      final feedback = ref.read(provider).feedback;
      if (next == null || next == previous || feedback == null) return;
      if (feedback.ok) {
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.click);
      } else {
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.alert);
      }
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space2,
        AppSpacing.space4,
        AppSpacing.space8,
      ),
      children: [
        Text(
          l10n.scanMeetingEyebrow.toUpperCase(),
          style: AppTypography.label.toTextStyle(color: c.inkMuted),
        ),
        const SizedBox(height: AppSpacing.space1),
        if (meetings.length == 1)
          Text(_label(l10n, meeting), style: context.textTheme.titleMedium)
        else
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: [
              for (final m in meetings)
                ChoiceChip(
                  label: Text(_label(l10n, m)),
                  selected: m.id == meeting.id,
                  onSelected: (_) => onChoose(m),
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.space3),
        Semantics(
          label: l10n.scanCameraLabel,
          child: AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: ColoredBox(
                color: c.ink,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    scanner(context, controller.onDetected),
                    IgnorePointer(
                      child: CustomPaint(painter: _Corners(c.green)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        if (state.feedback case final feedback?)
          _FeedbackBanner(feedback: feedback)
        else
          Text(
            l10n.scanAim,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium,
          ),
        if (!state.canVerify) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(l10n.scanNoKey, style: context.textTheme.bodySmall),
        ],
        const SizedBox(height: AppSpacing.space4),
        Semantics(
          liveRegion: true,
          child: Text(
            l10n.scanCount(state.recordedCount),
            textAlign: TextAlign.center,
            style: context.textTheme.titleLarge,
          ),
        ),
        if (state.pending > 0) ...[
          Text(
            l10n.scanPending(state.pending),
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium,
          ),
          if (state.offline)
            Text(
              l10n.scanOffline,
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall,
            ),
          AppButton.text(label: l10n.scanSendNow, onPressed: controller.flush),
        ],
        if (state.sendError case final error?)
          Text(
            l10n.scanSendError(errorMessage(l10n, error)),
            style: context.textTheme.bodySmall?.copyWith(color: c.danger),
          ),
        if (env.useMocks) ...[
          const SizedBox(height: AppSpacing.space2),
          AppButton.secondary(
            label: l10n.scanSimulate,
            icon: LucideIcons.scanLine,
            onPressed: () async => controller.onDetected(await _nextMockCard()),
          ),
        ],
        const SizedBox(height: AppSpacing.space4),
        Text(l10n.scanFooter, style: context.textTheme.bodySmall),
      ],
    );
  }
}

var _mockScans = 0;

/// Cartes de démonstration, à tour de rôle : membre, bureau, membre de
/// nouveau, candidat, carte expirée, code quelconque.
Future<String> _nextMockCard() async {
  final now = DateTime.now();
  Future<String> card(MockPersona persona, {bool expired = false}) =>
      signMockCard(
        memberId: persona.meJson['id']! as int,
        memberNumber: (persona.meJson['member_number'] as String?) ?? 'TEST',
        issuedAt: now.subtract(const Duration(days: 40)),
        expiresAt: expired
            ? now.subtract(const Duration(days: 10))
            : now.add(const Duration(days: 20)),
      );
  return switch (_mockScans++ % 6) {
    0 => card(MockPersona.member),
    1 => card(MockPersona.bureau),
    2 => card(MockPersona.member),
    3 => card(MockPersona.candidate),
    4 => card(MockPersona.bureau, expired: true),
    _ => Future.value('https://exemple.com/pas-une-carte'),
  };
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.feedback});

  final ScanFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final f = feedback;
    final who = f.fullName ?? f.memberNumber;
    final (title, body) = switch (f.kind) {
      ScanFeedbackKind.recorded => (
        l10n.scanRecorded,
        [?f.fullName, ?f.memberNumber].join(' · '),
      ),
      ScanFeedbackKind.accepted => (
        l10n.scanAccepted,
        l10n.scanAcceptedBody(f.memberNumber ?? ''),
      ),
      ScanFeedbackKind.readUnverified => (
        l10n.scanUnverified,
        l10n.scanUnverifiedBody,
      ),
      ScanFeedbackKind.alreadyRecorded => (
        l10n.scanAlreadyRecorded,
        who == null ? l10n.scanAlreadyBody : l10n.scanAlreadyNamed(who),
      ),
      ScanFeedbackKind.invalid => (l10n.scanCodeInvalid, l10n.scanInvalidBody),
      ScanFeedbackKind.expired => (
        l10n.scanExpired,
        [?f.memberNumber, l10n.scanExpiredBody].join(' · '),
      ),
      ScanFeedbackKind.notMember => (
        l10n.scanNotMember,
        [?who, l10n.scanNotMemberBody].join(' · '),
      ),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: f.ok ? c.greenSoft : c.redSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: f.ok ? c.green : c.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                f.ok ? LucideIcons.check : LucideIcons.triangleAlert,
                color: f.ok ? c.onGreen : c.surfaceRaised,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.textTheme.titleMedium),
                  if (body.isNotEmpty)
                    Text(body, style: context.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Les quatre coins du viseur.
class _Corners extends CustomPainter {
  const _Corners(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final inset = size.width * 0.18;
    const arm = 36.0;
    final rect = Rect.fromLTRB(
      inset,
      inset,
      size.width - inset,
      size.height - inset,
    );
    for (final (corner, dx, dy) in [
      (rect.topLeft, 1.0, 1.0),
      (rect.topRight, -1.0, 1.0),
      (rect.bottomLeft, 1.0, -1.0),
      (rect.bottomRight, -1.0, -1.0),
    ]) {
      canvas
        ..drawLine(corner, corner.translate(arm * dx, 0), paint)
        ..drawLine(corner, corner.translate(0, arm * dy), paint);
    }
  }

  @override
  bool shouldRepaint(_Corners oldDelegate) => oldDelegate.color != color;
}

/// Caméra arrière, QR codes seulement.
class CameraScanner extends StatefulWidget {
  const CameraScanner({super.key, required this.onCode});

  final ValueChanged<String> onCode;

  @override
  State<CameraScanner> createState() => _CameraScannerState();
}

class _CameraScannerState extends State<CameraScanner> {
  final _controller = MobileScannerController(formats: [BarcodeFormat.qrCode]);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return MobileScanner(
      controller: _controller,
      onDetect: (capture) {
        for (final code in capture.barcodes) {
          final value = code.rawValue;
          if (value != null) widget.onCode(value);
        }
      },
      errorBuilder: (context, error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space6),
          child: Text(
            error.errorCode == MobileScannerErrorCode.permissionDenied
                ? l10n.scanCameraDenied
                : l10n.scanCameraError,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: c.surfaceRaised,
            ),
          ),
        ),
      ),
    );
  }
}
