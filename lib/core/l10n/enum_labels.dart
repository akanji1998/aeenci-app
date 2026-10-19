// Libellés français des énumérations du contrat (textes dans app_fr.arb).

import '../../l10n/generated/app_localizations.dart';
import '../domain/enums.dart';

extension GenderLabel on Gender {
  String label(AppLocalizations l10n) => switch (this) {
    Gender.female => l10n.genderFemale,
    Gender.male => l10n.genderMale,
    Gender.unknown => l10n.enumUnknown,
  };
}

extension AdmissionStateLabel on AdmissionState {
  String label(AppLocalizations l10n) => switch (this) {
    AdmissionState.pending => l10n.admissionPending,
    AdmissionState.approved => l10n.admissionApproved,
    AdmissionState.rejected => l10n.admissionRejected,
    AdmissionState.unknown => l10n.enumUnknown,
  };
}

extension MemberStatusLabel on MemberStatus {
  String label(AppLocalizations l10n) => switch (this) {
    MemberStatus.member => l10n.statusMember,
    MemberStatus.former => l10n.statusFormer,
    MemberStatus.elder => l10n.statusElder,
    MemberStatus.unknown => l10n.enumUnknown,
  };
}

extension EngagementLabel on Engagement {
  String label(AppLocalizations l10n) => switch (this) {
    Engagement.active => l10n.engagementActive,
    Engagement.dormant => l10n.engagementDormant,
    Engagement.unknown => l10n.enumUnknown,
  };
}

extension MemberCategoryLabel on MemberCategory {
  String label(AppLocalizations l10n) => switch (this) {
    MemberCategory.student => l10n.categoryStudent,
    MemberCategory.youngProfessional => l10n.categoryYoungProfessional,
    MemberCategory.professional => l10n.categoryProfessional,
    MemberCategory.unknown => l10n.enumUnknown,
  };
}

extension ShowcaseStatusLabel on ShowcaseStatus {
  String label(AppLocalizations l10n) => switch (this) {
    ShowcaseStatus.private => l10n.showcasePrivate,
    ShowcaseStatus.pending => l10n.showcasePending,
    ShowcaseStatus.published => l10n.showcasePublished,
    ShowcaseStatus.unknown => l10n.enumUnknown,
  };
}

extension ContributionStateLabel on ContributionState {
  String label(AppLocalizations l10n) => switch (this) {
    ContributionState.unpaid => l10n.contributionUnpaid,
    ContributionState.partial => l10n.contributionPartial,
    ContributionState.paid => l10n.contributionPaid,
    ContributionState.exempt => l10n.contributionExempt,
    ContributionState.unknown => l10n.enumUnknown,
  };
}

extension PaymentPurposeLabel on PaymentPurpose {
  String label(AppLocalizations l10n) => switch (this) {
    PaymentPurpose.admission => l10n.paymentPurposeAdmission,
    PaymentPurpose.contribution => l10n.paymentPurposeContribution,
    PaymentPurpose.unknown => l10n.enumUnknown,
  };
}

extension PaymentMethodLabel on PaymentMethod {
  String label(AppLocalizations l10n) => switch (this) {
    PaymentMethod.cash => l10n.paymentMethodCash,
    PaymentMethod.orangeMoney => l10n.paymentMethodOrangeMoney,
    PaymentMethod.mtnMomo => l10n.paymentMethodMtnMomo,
    PaymentMethod.moovMoney => l10n.paymentMethodMoovMoney,
    PaymentMethod.wave => l10n.paymentMethodWave,
    PaymentMethod.bankTransfer => l10n.paymentMethodBankTransfer,
    PaymentMethod.other => l10n.paymentMethodOther,
    PaymentMethod.unknown => l10n.enumUnknown,
  };
}

extension MobileMoneyOperatorLabel on MobileMoneyOperator {
  String label(AppLocalizations l10n) => switch (this) {
    MobileMoneyOperator.orangeMoney => l10n.paymentMethodOrangeMoney,
    MobileMoneyOperator.mtnMomo => l10n.paymentMethodMtnMomo,
    MobileMoneyOperator.moovMoney => l10n.paymentMethodMoovMoney,
    MobileMoneyOperator.wave => l10n.paymentMethodWave,
    MobileMoneyOperator.unknown => l10n.enumUnknown,
  };
}

extension EventTypeLabel on EventType {
  String label(AppLocalizations l10n) => switch (this) {
    EventType.joe => l10n.eventTypeJoe,
    EventType.employmentDay => l10n.eventTypeEmploymentDay,
    EventType.impact => l10n.eventTypeImpact,
    EventType.other => l10n.eventTypeOther,
    EventType.unknown => l10n.enumUnknown,
  };
}

extension AttendanceStateLabel on AttendanceState {
  String label(AppLocalizations l10n) => switch (this) {
    AttendanceState.present => l10n.attendancePresent,
    AttendanceState.excused => l10n.attendanceExcused,
    AttendanceState.absent => l10n.attendanceAbsent,
    AttendanceState.unknown => l10n.enumUnknown,
  };
}

extension NotificationCategoryLabel on NotificationCategory {
  String label(AppLocalizations l10n) => switch (this) {
    NotificationCategory.account => l10n.notificationCategoryAccount,
    NotificationCategory.events => l10n.notificationCategoryEvents,
    NotificationCategory.meetings => l10n.notificationCategoryMeetings,
    NotificationCategory.contributions =>
      l10n.notificationCategoryContributions,
    NotificationCategory.news => l10n.notificationCategoryNews,
    NotificationCategory.opportunities =>
      l10n.notificationCategoryOpportunities,
    NotificationCategory.announcements =>
      l10n.notificationCategoryAnnouncements,
    NotificationCategory.unknown => l10n.enumUnknown,
  };
}

extension OpportunityTypeLabel on OpportunityType {
  String label(AppLocalizations l10n) => switch (this) {
    OpportunityType.job => l10n.opportunityTypeJob,
    OpportunityType.internship => l10n.opportunityTypeInternship,
    OpportunityType.scholarship => l10n.opportunityTypeScholarship,
    OpportunityType.training => l10n.opportunityTypeTraining,
    OpportunityType.other => l10n.opportunityTypeOther,
    OpportunityType.unknown => l10n.enumUnknown,
  };
}

extension ApplyMethodLabel on ApplyMethod {
  String label(AppLocalizations l10n) => switch (this) {
    ApplyMethod.url => l10n.applyMethodUrl,
    ApplyMethod.email => l10n.applyMethodEmail,
    ApplyMethod.viaBureau => l10n.applyMethodViaBureau,
    ApplyMethod.unknown => l10n.enumUnknown,
  };
}

extension ScanOutcomeLabel on ScanOutcome {
  String label(AppLocalizations l10n) => switch (this) {
    ScanOutcome.recorded => l10n.scanRecorded,
    ScanOutcome.alreadyRecorded => l10n.scanAlreadyRecorded,
    ScanOutcome.invalid => l10n.scanInvalid,
    ScanOutcome.expired => l10n.scanExpired,
    ScanOutcome.notMember => l10n.scanNotMember,
    ScanOutcome.unknown => l10n.enumUnknown,
  };
}
