import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/expenses_repository.dart';
import '../datasources/expenses_local_datasource.dart';

class ExpensesRepositoryImpl implements ExpensesRepository {
  final ExpensesLocalDatasource _datasource;
  ExpensesRepositoryImpl(this._datasource);

  @override
  Future<List<ExpenseEntity>> getAllExpenses({
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int pageSize = 50,
  }) =>
      _datasource.getAllExpenses(
        category: category,
        fromDate: fromDate,
        toDate: toDate,
        page: page,
        pageSize: pageSize,
      );

  @override
  Future<int> createExpense(ExpenseEntity expense) => _datasource.createExpense(expense);

  @override
  Future<bool> deleteExpense(int id) => _datasource.deleteExpense(id);

  @override
  Future<Map<String, double>> getExpensesByCategory({DateTime? fromDate, DateTime? toDate}) =>
      _datasource.getExpensesByCategory(fromDate: fromDate, toDate: toDate);
}
