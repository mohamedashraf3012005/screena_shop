import 'package:equatable/equatable.dart';

class CashTransactionEntity extends Equatable {
  final int id;
  final String transactionType; // sale_income, purchase_payment, expense, customer_payment, supplier_payment, cash_in, cash_out
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String description;
  final int? referenceId;
  final String? referenceType;
  final String? notes;
  final int? sessionId;
  final DateTime createdAt;

  const CashTransactionEntity({
    required this.id,
    required this.transactionType,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.description,
    this.referenceId,
    this.referenceType,
    this.notes,
    this.sessionId,
    required this.createdAt,
  });

  bool get isIncome => amount > 0;

  String get typeLabel {
    switch (transactionType) {
      case 'sale_income': return 'إيراد مبيعات';
      case 'customer_payment': return 'تحصيل عميل';
      case 'purchase_payment': return 'سداد مشتريات';
      case 'supplier_payment': return 'سداد مورد';
      case 'expense': return 'مصروفات تشغيلية';
      case 'cash_in': return 'إيداع نقدي';
      case 'cash_out': return 'سحب نقدي';
      default: return 'حركة خزينة';
    }
  }

  @override
  List<Object?> get props => [id, transactionType, amount, balanceAfter, createdAt];
}

class CashSessionEntity extends Equatable {
  final int id;
  final DateTime openedAt;
  final DateTime? closedAt;
  final double openingBalance;
  final double expectedBalance;
  final double? actualBalance;
  final double? difference;
  final String status; // open, closed
  final String? notes;

  const CashSessionEntity({
    required this.id,
    required this.openedAt,
    this.closedAt,
    required this.openingBalance,
    required this.expectedBalance,
    this.actualBalance,
    this.difference,
    required this.status,
    this.notes,
  });

  bool get isOpen => status == 'open';

  @override
  List<Object?> get props => [id, status, openedAt, closedAt];
}
