import '../../../core/domain/enums.dart';
import 'contribution.dart';

/// Paiement du droit d'adhésion, s'il figure dans l'historique.
Payment? admissionPayment(List<Payment> payments) =>
    payments.where((p) => p.purpose == PaymentPurpose.admission).firstOrNull;

/// Années de cotisation, de la plus récente à la plus ancienne.
List<Contribution> contributionYears(List<Contribution> all) =>
    [...all]..sort((a, b) => b.year.compareTo(a.year));
