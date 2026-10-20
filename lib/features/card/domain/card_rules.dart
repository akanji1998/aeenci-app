import 'member_card.dart';

/// Délai avant expiration en dessous duquel l'application redemande la
/// carte dès qu'elle est en ligne (contrat v3 : moins de 7 jours).
const cardRenewalWindow = Duration(days: 7);

/// La carte doit être redemandée à l'API.
bool shouldRenewCard(MemberCard card, DateTime now) =>
    card.qrExpiresAt.difference(now) < cardRenewalWindow;

/// Le QR code a expiré : les scanners du bureau le refuseront.
bool isCardExpired(MemberCard card, DateTime now) =>
    !now.isBefore(card.qrExpiresAt);
