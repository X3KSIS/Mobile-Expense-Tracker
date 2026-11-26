import 'package:flutter_expensetracker/domain/models/money_message.dart';
import 'package:flutter_expensetracker/domain/models/wallet.dart';
import 'package:flutter_expensetracker/utils/money_message_parser.dart';
import 'package:flutter_test/flutter_test.dart';

// The sample messages follow the shape of real confirmations but are made
// up; check them against messages from your own phone.
void main() {
  MoneyMessage parse(String text) {
    final result = MoneyMessageParser.parse(text);
    expect(result, isNotNull, reason: text);
    return result!;
  }

  test('MTN MoMo money received', () {
    final m = parse(
      'You have received ZMW 250.00 from JOHN BANDA 0961234567 on '
      '26/11/2026 14:32. Your new balance is ZMW 1,070.00. '
      'Transaction ID: 1234567890.',
    );
    expect(m.kind, MoneyMessageKind.received);
    expect(m.amount, 250);
    expect(m.counterparty, 'John Banda');
    expect(m.balance, 1070);
    expect(m.reference, '1234567890');
    expect(m.date, DateTime(2026, 11, 26, 14, 32));
    expect(m.provider, isNull);
    expect(m.categoryHint, 'Other income');
  });

  test('MTN MoMo payment to a shop, with a zero fee', () {
    final m = parse(
      'MoMo: You have paid ZMW 150.00 to SHOPRITE MANDA HILL on '
      '26/11/2026 10:15. Fee ZMW 0.00. New balance ZMW 920.00. '
      'Txn ID: 987654.',
    );
    expect(m.kind, MoneyMessageKind.spent);
    expect(m.amount, 150);
    expect(m.counterparty, 'Shoprite Manda Hill');
    expect(m.fee, isNull);
    expect(m.balance, 920);
    expect(m.provider, 'MTN MoMo');
    expect(m.providerKind, WalletKind.mobileMoney);
    expect(m.categoryHint, 'Groceries');
  });

  test('Airtel Money received, with the number before the name', () {
    final m = parse(
      'Airtel Money: Money received. Amt: K500.00 From: 0971234567 '
      'MARY PHIRI. Bal: K1,250.00. TID: MP261126.1432.A12345.',
    );
    expect(m.kind, MoneyMessageKind.received);
    expect(m.amount, 500);
    expect(m.counterparty, 'Mary Phiri');
    expect(m.balance, 1250);
    expect(m.provider, 'Airtel Money');
    expect(m.reference, 'MP261126.1432.A12345');
  });

  test('sending money with a charge', () {
    final m = parse(
      'You have sent ZMW 100.00 to PETER MWALE 0977654321. '
      'Fee: ZMW 2.50. Balance: ZMW 817.50. Ref: ABC123XY',
    );
    expect(m.kind, MoneyMessageKind.spent);
    expect(m.amount, 100);
    expect(m.fee, 2.5);
    expect(m.counterparty, 'Peter Mwale');
  });

  test('agent cash out is a withdrawal', () {
    final m = parse(
      'Airtel: Cash out of K300.00 at agent KABWE STORES successful. '
      'Charge K8.50. Bal K950.00.',
    );
    expect(m.kind, MoneyMessageKind.withdrawal);
    expect(m.amount, 300);
    expect(m.fee, 8.5);
  });

  test('buying ZESCO units is Utilities', () {
    final m = parse(
      'Zamtel Kwacha: You have bought ZESCO units worth K200.00. '
      'Token 1234-5678-9012. Bal K40.00',
    );
    expect(m.kind, MoneyMessageKind.spent);
    expect(m.amount, 200);
    expect(m.provider, 'Zamtel Kwacha');
    expect(m.categoryHint, 'Utilities');
  });

  test('bank debit alert', () {
    final m = parse(
      'Zanaco: Your account ****1234 has been debited with ZMW 640.00 at '
      'PICK N PAY on 26-11-2026. Avail Bal: ZMW 5,210.00',
    );
    expect(m.kind, MoneyMessageKind.spent);
    expect(m.amount, 640);
    expect(m.provider, 'Zanaco');
    expect(m.providerKind, WalletKind.bank);
    expect(m.balance, 5210);
    expect(m.counterparty, 'Pick N Pay');
    expect(m.categoryHint, 'Groceries');
    expect(m.date, DateTime(2026, 11, 26, 12));
  });

  test('salary credit', () {
    final m = parse(
      'FNB: ZMW 12,500.00 credited to acc ...1234. Ref SALARY NOV.',
    );
    expect(m.kind, MoneyMessageKind.received);
    expect(m.amount, 12500);
    expect(m.provider, 'FNB');
    expect(m.categoryHint, 'Salary');
  });

  test('recognises providers run together in the sender name', () {
    expect(
      parse('AirtelMoney. Money received. Amt: K50.00').provider,
      'Airtel Money',
    );
    expect(parse('MoMoPay: You have paid ZMW 20.00 to X').provider, 'MTN MoMo');
  });

  test('ignores text that is not a money message', () {
    expect(MoneyMessageParser.parse(''), isNull);
    expect(MoneyMessageParser.parse('See you at 5, bring K'), isNull);
    expect(
      MoneyMessageParser.parse('You have received a new voicemail'),
      isNull,
    );
    expect(MoneyMessageParser.parse('Your OTP is 123456'), isNull);
  });
}
