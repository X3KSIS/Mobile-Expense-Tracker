import '../../../domain/models/bill.dart';
import '../../../utils/result.dart';
import 'bill_repository.dart';

/// In-memory [BillRepository] for tests and previews, seeded with [bills].
class BillRepositoryLocalFake extends BillRepository {
  BillRepositoryLocalFake({List<Bill> bills = const []}) : _bills = [...bills];

  final List<Bill> _bills;
  int _nextId = 1;

  @override
  Future<Result<List<Bill>>> getBills() async =>
      Result.ok([..._bills]..sort((a, b) => a.nextDue.compareTo(b.nextDue)));

  @override
  Future<Result<Bill>> saveBill(Bill bill) async {
    final saved = bill.id.isEmpty
        ? bill.copyWith(id: 'bill-${_nextId++}')
        : bill;
    final index = _bills.indexWhere((b) => b.id == saved.id);
    if (index == -1) {
      _bills.add(saved);
    } else {
      _bills[index] = saved;
    }
    notifyListeners();
    return Result.ok(saved);
  }

  @override
  Future<Result<void>> deleteBill(String id) async {
    _bills.removeWhere((b) => b.id == id);
    notifyListeners();
    return const Result.ok(null);
  }
}
