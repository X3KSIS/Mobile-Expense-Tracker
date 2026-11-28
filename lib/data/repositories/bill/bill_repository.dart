import 'package:flutter/foundation.dart';

import '../../../domain/models/bill.dart';
import '../../../utils/result.dart';

/// Source of truth for the bills the user set up (rent, DStv, school
/// fees). Notifies after every change.
abstract class BillRepository extends ChangeNotifier {
  /// Every bill, soonest due first.
  Future<Result<List<Bill>>> getBills();

  /// Adds [bill] when its id is empty, otherwise replaces the bill with
  /// the same id.
  Future<Result<Bill>> saveBill(Bill bill);

  Future<Result<void>> deleteBill(String id);
}
