import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/expense_entity.dart';

class ExpensesLocalDatasource {
  final AppDatabase _db;
  ExpensesLocalDatasource(this._db);

  Future<List<ExpenseEntity>> getAllExpenses({
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int pageSize = 50,
  }) async {
    final query = _db.select(_db.expenses);

    if (category != null && category.isNotEmpty) {
      query.where((e) => e.category.equals(category));
    }
    if (fromDate != null) {
      query.where((e) => e.expenseDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where((e) => e.expenseDate.isSmallerOrEqualValue(toDate));
    }

    query.orderBy([(e) => OrderingTerm.desc(e.expenseDate)]);
    query.limit(pageSize, offset: (page - 1) * pageSize);

    final rows = await query.get();

    return rows
        .map((r) => ExpenseEntity(
              id: r.id,
              category: r.category,
              description: r.description,
              amount: r.amount,
              paymentMethod: r.paymentMethod,
              notes: r.notes,
              userId: r.userId,
              expenseDate: r.expenseDate,
              createdAt: r.createdAt,
            ))
        .toList();
  }

  Future<int> createExpense(ExpenseEntity e) async {
    return await _db.transaction(() async {
      final expenseId = await _db.into(_db.expenses).insert(
            ExpensesCompanion.insert(
              category: e.category,
              description: e.description,
              amount: e.amount,
              paymentMethod: Value(e.paymentMethod),
              notes: Value(e.notes),
              userId: Value(e.userId),
              expenseDate: Value(e.expenseDate),
            ),
          );

      // Record in Cash Transactions
      final cashBefore = await _db.getCurrentCashBalance();
      await _db.into(_db.cashTransactions).insert(
            CashTransactionsCompanion.insert(
              transactionType: 'expense',
              amount: -e.amount,
              balanceBefore: Value(cashBefore),
              balanceAfter: Value(cashBefore - e.amount),
              description: 'مصروفات [${e.category}]: ${e.description}',
              referenceId: Value(expenseId),
              referenceType: const Value('expense'),
              notes: Value(e.notes),
              userId: Value(e.userId),
            ),
          );

      return expenseId;
    });
  }

  Future<bool> deleteExpense(int id) async {
    return await _db.transaction(() async {
      final expense = await (_db.select(_db.expenses)..where((e) => e.id.equals(id))).getSingleOrNull();
      if (expense == null) return false;

      // Refund cash
      final cashBefore = await _db.getCurrentCashBalance();
      await _db.into(_db.cashTransactions).insert(
            CashTransactionsCompanion.insert(
              transactionType: 'cash_in',
              amount: expense.amount,
              balanceBefore: Value(cashBefore),
              balanceAfter: Value(cashBefore + expense.amount),
              description: 'إلغاء مصروف [${expense.category}]: ${expense.description}',
              referenceId: Value(id),
              referenceType: const Value('expense_cancel'),
            ),
          );

      final count = await (_db.delete(_db.expenses)..where((e) => e.id.equals(id))).go();
      return count > 0;
    });
  }

  Future<Map<String, double>> getExpensesByCategory({DateTime? fromDate, DateTime? toDate}) async {
    final query = _db.select(_db.expenses);
    if (fromDate != null) query.where((e) => e.expenseDate.isBiggerOrEqualValue(fromDate));
    if (toDate != null) query.where((e) => e.expenseDate.isSmallerOrEqualValue(toDate));

    final rows = await query.get();
    final Map<String, double> map = {};

    for (final r in rows) {
      map[r.category] = (map[r.category] ?? 0.0) + r.amount;
    }
    return map;
  }
}
