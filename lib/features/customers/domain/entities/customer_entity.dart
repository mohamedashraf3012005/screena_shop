import 'package:equatable/equatable.dart';

class CustomerEntity extends Equatable {
  final int id;
  final String name;
  final String? phone;
  final String? whatsapp;
  final String? address;
  final String? notes;
  final double totalBalance; // مديونية العميل
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastTransactionAt;

  const CustomerEntity({
    required this.id,
    required this.name,
    this.phone,
    this.whatsapp,
    this.address,
    this.notes,
    required this.totalBalance,
    required this.isActive,
    required this.createdAt,
    this.lastTransactionAt,
  });

  bool get hasBalance => totalBalance > 0;

  @override
  List<Object?> get props => [id, name, totalBalance];
}

class CustomerTransactionEntity extends Equatable {
  final int id;
  final int customerId;
  final String transactionType;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final int? referenceId;
  final String? referenceType;
  final String? notes;
  final DateTime createdAt;

  const CustomerTransactionEntity({
    required this.id,
    required this.customerId,
    required this.transactionType,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.referenceId,
    this.referenceType,
    this.notes,
    required this.createdAt,
  });

  String get typeLabel {
    switch (transactionType) {
      case 'sale': return 'مبيعات';
      case 'payment': return 'تحصيل';
      case 'return': return 'مرتجع';
      default: return 'تعديل';
    }
  }

  @override
  List<Object?> get props => [id, transactionType, amount, createdAt];
}
