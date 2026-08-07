import 'package:flutter_test/flutter_test.dart';

import 'package:finix_dashboard/services/sms_service.dart';

void main() {
  group('OTP messages are never scanned', () {
    test('recognises the common OTP formats Indian banks send', () {
      const otps = [
        '482910 is your OTP for txn of INR 10,000.00. Do not share.',
        'Your one-time password is 3948. Valid for 10 minutes.',
        'Use verification code 928374 to log in.',
        'OTP: 5591 for your UPI registration. Never share this.',
        'Your security code is 220496 - HDFC Bank',
        'One time passcode 8842 for your card ending 1234',
      ];
      for (final body in otps) {
        expect(FinixSms.isOtpMessage(body), isTrue, reason: body);
      }
    });

    test('leaves ordinary and phishing messages alone', () {
      const keep = [
        // The whole point of the scanner.
        'URGENT: Your account is blocked. Verify KYC at sbi-kyc-check.com',
        'Rs 5,000 debited from A/c XX4521 on 03-Aug. Bal Rs 1,15,239.',
        'Your order has been delivered! Enjoy your meal.',
        // Mentions an OTP but is not an OTP delivery — this is exactly the
        // social-engineering text the scanner must still see.
        'Share your OTP with our agent to reverse the failed transaction.',
      ];
      for (final body in keep) {
        expect(FinixSms.isOtpMessage(body), isFalse, reason: body);
      }
    });

    test('a code alone is not enough without OTP wording', () {
      // Amounts and reference numbers must not be mistaken for OTPs.
      expect(FinixSms.isOtpMessage('Ref 4829102 credited to your account'),
          isFalse);
      expect(FinixSms.isOtpMessage('Your EMI of 24650 is due on 05 Aug'),
          isFalse);
    });
  });
}
