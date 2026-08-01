/// Parsing for UPI QR payloads.
///
/// Indian merchant QR codes carry a `upi://pay?...` deep link as defined by the
/// NPCI UPI linking specification, e.g.
///
///   upi://pay?pa=starbucks@okhdfcbank&pn=Starbucks%20Coffee&am=250.00&cu=INR&tn=Order%2012
///
/// Fields used here:
///   pa - payee VPA (required)            pn - payee name
///   am - amount in RUPEES (optional)     tn - transaction note
///   cu - currency (INR)                  mc - merchant category code
///
/// A QR with no `am` is an open-amount merchant code: the payer types the
/// amount. Anything that is not a UPI link is rejected rather than guessed at,
/// so a random QR cannot start a payment.
library;

class UpiPayment {
  /// Payee virtual payment address, e.g. `starbucks@okhdfcbank`.
  final String payeeAddress;

  /// Human-readable payee name; falls back to the VPA handle.
  final String payeeName;

  /// Amount in rupees, or null when the QR leaves it open.
  final double? amount;

  final String currency;
  final String note;
  final String merchantCode;

  const UpiPayment({
    required this.payeeAddress,
    required this.payeeName,
    this.amount,
    this.currency = 'INR',
    this.note = '',
    this.merchantCode = '',
  });

  /// True when the QR fixed the amount (payer cannot change it).
  bool get hasFixedAmount => amount != null && amount! > 0;

  /// Amount in paise, the unit the backend API expects.
  int? get amountPaise =>
      amount == null ? null : (amount! * 100).round();

  /// Parses a scanned QR payload, returning null when it is not a UPI payment.
  static UpiPayment? tryParse(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;

    final uri = Uri.tryParse(value);
    if (uri == null) return null;

    // Accept upi://pay and the https://…?pa=… form some issuers emit.
    final isUpiScheme = uri.scheme.toLowerCase() == 'upi';
    final hasPayeeParam = uri.queryParameters.containsKey('pa');
    if (!isUpiScheme && !hasPayeeParam) return null;

    final params = uri.queryParameters;
    final payee = (params['pa'] ?? '').trim();
    // A VPA must look like handle@psp; reject anything else so a malformed or
    // spoofed QR cannot produce a payment target.
    if (!RegExp(r'^[\w.\-]{2,}@[\w.\-]{2,}$').hasMatch(payee)) return null;

    double? amount;
    final rawAmount = (params['am'] ?? '').trim();
    if (rawAmount.isNotEmpty) {
      final parsed = double.tryParse(rawAmount);
      // Ignore non-positive or absurd amounts rather than trusting the QR.
      if (parsed != null && parsed > 0 && parsed < 10000000) {
        amount = parsed;
      }
    }

    final name = (params['pn'] ?? '').trim();
    return UpiPayment(
      payeeAddress: payee,
      payeeName: name.isNotEmpty ? name : payee.split('@').first,
      amount: amount,
      currency: (params['cu'] ?? 'INR').trim().toUpperCase(),
      note: (params['tn'] ?? '').trim(),
      merchantCode: (params['mc'] ?? '').trim(),
    );
  }
}
