import 'package:equatable/equatable.dart';

class ExpenseEntity extends Equatable {
  final int id;
  final String category; // كهرباء، إيجار، مياه، مرتبات، بوفيه ونظافة، أخرى
  final String description;
  final double amount;
  final String paymentMethod;
  final String? notes;
  final int? userId;
  final DateTime expenseDate;
  final DateTime createdAt;

  const ExpenseEntity({
    required this.id,
    required this.category,
    required this.description,
    required this.amount,
    required this.paymentMethod,
    this.notes,
    this.userId,
    required this.expenseDate,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, category, description, amount, expenseDate];
}
