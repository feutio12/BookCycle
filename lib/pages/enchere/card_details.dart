// lib/pages/enchere/card_details.dart
class CardDetails {
  final String number;
  final int expMonth;
  final int expYear;
  final String cvc;

  CardDetails({
    required this.number,
    required this.expMonth,
    required this.expYear,
    required this.cvc,
  });
}