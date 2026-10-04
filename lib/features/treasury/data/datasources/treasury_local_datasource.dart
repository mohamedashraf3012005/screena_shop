import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/treasury_entity.dart';

class TreasuryLocalDatasource {
  final AppDatabase _db;
  TreasuryLocalDatasource(this._db);

  Future<double> getCurrentBalance() => _db.getCurrentCashBalance();

  Future<List<CashTransactionEntity>> getTransactions({
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
    int page = 1,
    int pageSize = 50,
  }) async {
    final query = _db.select(_db.cashTransactions);

    if (fromDate != null) {
      query.where((t) => t.createdAt.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where((t) => t.createdAt.isSmallerOrEqualValue(toDate));
    }
    if (type != null && type.isNotEmpty) {
      query.where((t) => t.transactionType.equals(type));
    }

    query.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    query.limit(pageSize, offset: (page - 1) * pageSize);

    final rows = await query.get();

    return rows
        .map((r) => CashTransactionEntity(
              id: r.id,
              transactionType: r.transactionType,
              amount: r.amount,
              balanceBefore: r.balanceBefore,
              balanceAfter: r.balanceAfter,
              description: r.description,
              referenceId: r.referenceId,
              referenceType: r.referenceType,
              notes: r.notes,
              sessionId: r.sessionId,
              createdAt: r.createdAt,
            ))
        .toList();
  }

  Future<void> addCashMovement({
    required double amount,
    required String type,
    required String description,
    String? notes,
    int? userId,
  }) async {
    await _db.transaction(() async {
      final cashBefore = await _db.getCurrentCashBalance();
      final cashAfter = cashBefore + amount;

      await _db.into(_db.cashTransactions).insert(
            CashTransactionsCompanion.insert(
              transactionType: type,
              amount: amount,
              balanceBefore: Value(cashBefore),
              balanceAfter: Value(cashAfter),
              description: description,
              notes: Value(notes),
              userId: Value(userId),
            ),
          );
    });
  }

  Future<CashSessionEntity?> getActiveSession() async {
    final s = await (_db.select(_db.cashSessions)
          ..where((tbl) => tbl.status.equals('open'))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.openedAt)]))
        .getSingleOrNull();

    if (s == null) return null;

    final currentBal = await _db.getCurrentCashBalance();

    return CashSessionEntity(
      id: s.id,
      openedAt: s.openedAt,
      closedAt: s.closedAt,
      openingBalance: s.openingBalance,
      expectedBalance: currentBal,
      actualBalance: s.actualBalance,
      difference: s.difference,
      status: s.status,
      notes: s.notes,
    );
  }

  Future<int> openSession({required double openingBalance, int? userId}) async {
    return await _db.into(_db.cashSessions).insert(
          CashSessionsCompanion.insert(
            openingBalance: Value(openingBalance),
            expectedBalance: Value(openingBalance),
            status: const Value('open'),
            userId: Value(userId),
          ),
        );
  }

  Future<bool> closeSession({
    required int sessionId,
    required double actualBalance,
    String? notes,
  }) async {
    return await _db.transaction(() async {
      final expected = await _db.getCurrentCashBalance();
      final difference = actualBalance - expected;

      final count = await (_db.update(_db.cashSessions)..where((s) => s.id.equals(sessionId))).write(
        CashSessionsCompanion(
          closedAt: Value(DateTime.now()),
          actualBalance: Value(actualBalance),
          expectedBalance: Value(expected),
          difference: Value(difference),
          status: const Value('closed'),
          notes: Value(notes),
        ),
      );

      return count > 0;
    });
  }
}
