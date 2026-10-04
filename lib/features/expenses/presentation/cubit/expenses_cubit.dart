import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/expenses_repository.dart';

abstract class ExpensesState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ExpensesInitial extends ExpensesState {}

class ExpensesLoading extends ExpensesState {}

class ExpensesLoaded extends ExpensesState {
  final List<ExpenseEntity> expenses;
  final Map<String, double> categoryTotals;
  final double totalAmount;

  ExpensesLoaded({
    required this.expenses,
    required this.categoryTotals,
    required this.totalAmount,
  });

  @override
  List<Object?> get props => [expenses, categoryTotals, totalAmount];
}

class ExpensesError extends ExpensesState {
  final String message;
  ExpensesError(this.message);
  @override
  List<Object?> get props => [message];
}

class ExpensesCubit extends Cubit<ExpensesState> {
  final ExpensesRepository _repository;
  ExpensesCubit(this._repository) : super(ExpensesInitial());

  Future<void> loadExpenses({String? category, DateTime? fromDate, DateTime? toDate}) async {
    emit(ExpensesLoading());
    try {
      final expenses = await _repository.getAllExpenses(
        category: category,
        fromDate: fromDate,
        toDate: toDate,
      );
      final totals = await _repository.getExpensesByCategory(
        fromDate: fromDate,
        toDate: toDate,
      );
      final sum = expenses.fold(0.0, (acc, e) => acc + e.amount);
      emit(ExpensesLoaded(
        expenses: expenses,
        categoryTotals: totals,
        totalAmount: sum,
      ));
    } catch (e) {
      emit(ExpensesError('حدث خطأ أثناء تحميل المصروفات'));
    }
  }

  Future<bool> createExpense(ExpenseEntity expense) async {
    try {
      await _repository.createExpense(expense);
      await loadExpenses();
      return true;
    } catch (e) {
      emit(ExpensesError('حدث خطأ أثناء تسجيل المصروف'));
      return false;
    }
  }

  Future<bool> deleteExpense(int id) async {
    try {
      await _repository.deleteExpense(id);
      await loadExpenses();
      return true;
    } catch (e) {
      emit(ExpensesError('حدث خطأ أثناء حذف المصروف'));
      return false;
    }
  }
}
