import 'package:equatable/equatable.dart';

class SaleEntity extends Equatable {
  final int id;
  final String invoiceNumber;
  final int? customerId;
  final String? customerName;
  final double subtotal;
  final double discountAmount;
  final double discountPercent;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final double costAmount;
  final double profitAmount;
  final String paymentType; // cash, credit
  final String status; // completed, cancelled, voided
  final String? notes;
  final String? cancelReason;
  final int? userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SaleItemEntity> items;

  const SaleEntity({
    required this.id,
    required this.invoiceNumber,
    this.customerId,
    this.customerName,
    required this.subtotal,
    required this.discountAmount,
    required this.discountPercent,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.costAmount,
    required this.profitAmount,
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

class SaleItemEntity extends Equatable {
  final int id;
  final int saleId;
  final int productId;
  final String productName;
  final String? productBarcode;
  final double quantity;
  final double unitPrice;
  final double costPrice;
  final double discountAmount;
  final double totalPrice;
  final double totalCost;
  final double profitAmount;
  final String priceType; // unit, group

  const SaleItemEntity({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    this.productBarcode,
    required this.quantity,
    required this.unitPrice,
    required this.costPrice,
    required this.discountAmount,
    required this.totalPrice,
    required this.totalCost,
    required this.profitAmount,
    required this.priceType,
  });

  @override
  List<Object?> get props => [id, saleId, productId, quantity, totalPrice];
}
