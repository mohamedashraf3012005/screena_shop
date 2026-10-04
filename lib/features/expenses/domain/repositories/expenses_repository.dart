import '../entities/expense_entity.dart';

abstract class ExpensesRepository {
  Future<List<ExpenseEntity>> getAllExpenses({
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int pageSize = 50,
  });
  Future<int> createExpense(ExpenseEntity expense);
  Future<bool> deleteExpense(int id);
  Future<Map<String, double>> getExpensesByCategory({DateTime? fromDate, DateTime? toDate});
}
