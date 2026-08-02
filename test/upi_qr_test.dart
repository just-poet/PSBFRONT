import 'package:flutter_test/flutter_test.dart';
import 'package:finix_dashboard/services/upi_qr.dart';

/// The parser is the trust boundary for QR payments: whatever it accepts
/// becomes a payment target. These tests pin both what it must accept and,
/// more importantly, what it must reject.
void main() {
  group('UpiPayment.tryParse — valid payloads', () {
    test('parses a full merchant QR', () {
      final p = UpiPayment.tryParse(
        'upi://pay?pa=starbucks@okhdfcbank&pn=Starbucks%20Coffee&am=250.50&cu=INR&tn=Order%2012',
      );
      expect(p, isNotNull);
      expect(p!.payeeAddress, 'starbucks@okhdfcbank');
      expect(p.payeeName, 'Starbucks Coffee');
      expect(p.amount, 250.50);
      expect(p.amountPaise, 25050);
      expect(p.currency, 'INR');
      expect(p.note, 'Order 12');
      expect(p.hasFixedAmount, isTrue);
    });

    test('open-amount QR leaves the amount for the payer', () {
      final p = UpiPayment.tryParse('upi://pay?pa=shop@ybl&pn=Corner%20Shop');
      expect(p, isNotNull);
      expect(p!.hasFixedAmount, isFalse);
      expect(p.amount, isNull);
      expect(p.amountPaise, isNull);
    });

    test('falls back to the VPA handle when no payee name is given', () {
      final p = UpiPayment.tryParse('upi://pay?pa=jiyad@sbi');
      expect(p!.payeeName, 'jiyad');
    });

    test('accepts the https form some issuers emit', () {
      final p = UpiPayment.tryParse('https://pay.example.com/x?pa=merchant@icici&am=10');
      expect(p, isNotNull);
      expect(p!.payeeAddress, 'merchant@icici');
    });
  });

  group('UpiPayment.tryParse — must reject', () {
    test('rejects null, empty and non-URI text', () {
      expect(UpiPayment.tryParse(null), isNull);
      expect(UpiPayment.tryParse(''), isNull);
      expect(UpiPayment.tryParse('   '), isNull);
      expect(UpiPayment.tryParse('just some scanned text'), isNull);
    });

    test('rejects a non-UPI URL (e.g. a random website QR)', () {
      expect(UpiPayment.tryParse('https://example.com/promo'), isNull);
    });

    test('rejects a UPI link with no payee', () {
      expect(UpiPayment.tryParse('upi://pay?am=100'), isNull);
    });

    test('rejects a malformed VPA', () {
      expect(UpiPayment.tryParse('upi://pay?pa=notavpa'), isNull);
      expect(UpiPayment.tryParse('upi://pay?pa=@bank'), isNull);
      expect(UpiPayment.tryParse('upi://pay?pa=user@'), isNull);
    });
  });

  group('UpiPayment.tryParse — hostile amounts', () {
    test('ignores a negative or zero amount instead of trusting it', () {
      expect(UpiPayment.tryParse('upi://pay?pa=shop@ybl&am=-500')!.amount, isNull);
      expect(UpiPayment.tryParse('upi://pay?pa=shop@ybl&am=0')!.amount, isNull);
    });

    test('ignores an absurd amount', () {
      expect(UpiPayment.tryParse('upi://pay?pa=shop@ybl&am=99999999')!.amount, isNull);
    });

    test('ignores a non-numeric amount', () {
      expect(UpiPayment.tryParse('upi://pay?pa=shop@ybl&am=abc')!.amount, isNull);
    });

    test('rounds paise correctly (no floating point drift)', () {
      expect(UpiPayment.tryParse('upi://pay?pa=shop@ybl&am=0.07')!.amountPaise, 7);
      expect(UpiPayment.tryParse('upi://pay?pa=shop@ybl&am=1234.56')!.amountPaise, 123456);
    });
  });
}
