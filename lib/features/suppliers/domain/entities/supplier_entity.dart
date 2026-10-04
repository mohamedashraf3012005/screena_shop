import 'package:equatable/equatable.dart';

class SupplierEntity extends Equatable {
  final int id;
  final String name;
  final String? company;
  final String? phone;
  final String? whatsapp;
  final String? address;
  final String? notes;
  final double totalBalance; // مستحقات المورد (موجب = له علينا)
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastTransactionAt;

  const SupplierEntity({
    required this.id,
    required this.name,
    this.company,
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

class SupplierTransactionEntity extends Equatable {
  final int id;
  final int supplierId;
  final String transactionType; // purchase, payment, return, adjustment
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final int? referenceId;
  final String? referenceType;
  final String? notes;
  final DateTime createdAt;

  const SupplierTransactionEntity({
    required this.id,
    required this.supplierId,
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
      case 'purchase': return 'فاتورة مشتريات';
      case 'payment': return 'سداد للمورد';
      case 'return': return 'مرتجع مشتريات';
      default: return 'تسوية / تعديل';
    }
  }

  @override
  List<Object?> get props => [id, transactionType, amount, createdAt];
}
