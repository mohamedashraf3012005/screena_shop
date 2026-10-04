import 'package:equatable/equatable.dart';

class PurchaseEntity extends Equatable {
  final int id;
  final String invoiceNumber;
  final int? supplierId;
  final String? supplierName;
  final double subtotal;
  final double discountAmount;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String paymentType; // cash, credit
  final String status; // completed, cancelled
  final String? notes;
  final String? cancelReason;
  final int? userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PurchaseItemEntity> items;

  const PurchaseEntity({
    required this.id,
    required this.invoiceNumber,
    this.supplierId,
    this.supplierName,
    required this.subtotal,
    required this.discountAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentType,
    required this.status,
    this.notes,
    this.cancelReason,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  bool get isPaidInFull => remainingAmount <= 0;
  bool get isCancelled => status == 'cancelled';

  @override
  List<Object?> get props => [id, invoiceNumber, totalAmount, status, createdAt];
}

class PurchaseItemEntity extends Equatable {
  final int id;
  final int purchaseId;
  final int productId;
  final String productName;
  final double quantity;
  final double unitCost;
  final double totalCost;

  const PurchaseItemEntity({
    required this.id,
    required this.purchaseId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
  });

  @override
  List<Object?> get props => [id, purchaseId, productId, quantity, totalCost];
}
