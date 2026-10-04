import '../../domain/entities/treasury_entity.dart';
import '../../domain/repositories/treasury_repository.dart';
import '../datasources/treasury_local_datasource.dart';

class TreasuryRepositoryImpl implements TreasuryRepository {
  final TreasuryLocalDatasource _datasource;
  TreasuryRepositoryImpl(this._datasource);

  @override
  Future<double> getCurrentBalance() => _datasource.getCurrentBalance();

  @override
  Future<List<CashTransactionEntity>> getTransactions({
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
    int page = 1,
    int pageSize = 50,
  }) =>
      _datasource.getTransactions(
        fromDate: fromDate,
        toDate: toDate,
        type: type,
        page: page,
        pageSize: pageSize,
      );

  @override
  Future<void> addCashMovement({
    required double amount,
    required String type,
    required String description,
    String? notes,
    int? userId,
  }) =>
      _datasource.addCashMovement(
        amount: amount,
        type: type,
        description: description,
        notes: notes,
        userId: userId,
      );

  @override
  Future<CashSessionEntity?> getActiveSession() => _datasource.getActiveSession();

  @override
  Future<int> openSession({required double openingBalance, int? userId}) =>
      _datasource.openSession(openingBalance: openingBalance, userId: userId);

  @override
  Future<bool> closeSession({
    required int sessionId,
    required double actualBalance,
    String? notes,
  }) =>
      _datasource.closeSession(
        sessionId: sessionId,
        actualBalance: actualBalance,
        notes: notes,
      );
}
