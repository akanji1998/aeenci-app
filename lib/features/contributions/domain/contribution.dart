import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/date_only.dart';
import '../../../core/domain/enums.dart';

part 'contribution.freezed.dart';
part 'contribution.g.dart';

/// `GET /me/contributions` : situation d'une année de cotisation.
@freezed
abstract class Contribution with _$Contribution {
  const Contribution._();

  const factory Contribution({
    /// « 2026-2027 ».
    required String year,

    /// Montants en F CFA.
    required int dueAmount,
    required int paidAmount,
    @JsonKey(unknownEnumValue: ContributionState.unknown)
    required ContributionState state,
  }) = _Contribution;

  factory Contribution.fromJson(Map<String, dynamic> json) =>
      _$ContributionFromJson(json);

  /// Reste à payer, jamais négatif.
  int get remainingAmount => math.max(0, dueAmount - paidAmount);
}

/// `GET /me/payments` : un paiement enregistré par le trésorier.
@freezed
abstract class Payment with _$Payment {
  const factory Payment({
    required int id,
    required String receiptNumber,
    @DateOnlyConverter() required DateTime paidOn,
    @JsonKey(unknownEnumValue: PaymentPurpose.unknown)
    required PaymentPurpose purpose,
    String? contributionYear,
    required int amount,
    @JsonKey(unknownEnumValue: PaymentMethod.unknown)
    required PaymentMethod method,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);
}
