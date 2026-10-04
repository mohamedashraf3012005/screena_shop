import '../entities/treasury_entity.dart';

abstract class TreasuryRepository {
  Future<double> getCurrentBalance();
  Future<List<CashTransactionEntity>> getTransactions({
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
    int page = 1,
    int pageSize = 50,
  });
  Future<void> addCashMovement({
    required double amount, // positive for cash_in, negative for cash_out
    required String type, // cash_in, cash_out
    required String description,
    String? notes,
    int? userId,
  });
  Future<CashSessionEntity?> getActiveSession();
  Future<int> openSession({required double openingBalance, int? userId});
  Future<bool> closeSession({
    required int sessionId,
    required double actualBalance,
    String? notes,
  });
}
