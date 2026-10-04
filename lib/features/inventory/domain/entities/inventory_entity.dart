import 'package:equatable/equatable.dart';

class InventoryMovementEntity extends Equatable {
  final int id;
  final int productId;
  final String productName;
  final String movementType; // purchase, sale, customer_return, supplier_return, manual_add, manual_remove, damage, inventory_adj
  final double quantity;
  final double costPrice;
  final double quantityBefore;
  final double quantityAfter;
  final int? referenceId;
  final String? referenceType;
  final String? reason;
  final String? notes;
  final DateTime createdAt;

  const InventoryMovementEntity({
    required this.id,
    required this.productId,
    required this.productName,
    required this.movementType,
    required this.quantity,
    required this.costPrice,
    required this.quantityBefore,
    required this.quantityAfter,
    this.referenceId,
    this.referenceType,
    this.reason,
    this.notes,
    required this.createdAt,
  });

  String get typeLabel {
    switch (movementType) {
      case 'purchase': return 'شراء وارد';
      case 'sale': return 'بيع صادر';
      case 'customer_return': return 'مرتجع مبيعات';
      case 'supplier_return': return 'مرتجع مشتريات';
      case 'manual_add': return 'إضافة يدوية';
      case 'manual_remove': return 'خصم يدوي';
      case 'damage': return 'هالك / تالف';
      case 'inventory_adj': return 'تسوية جرد';
      default: return 'حركة مخزون';
    }
  }

  @override
  List<Object?> get props => [id, productId, movementType, quantity, createdAt];
}

class StockDamageEntity extends Equatable {
  final int id;
  final int productId;
  final String productName;
  final double quantity;
  final double costPrice;
  final double totalCost;
  final String reason;
  final String? notes;
  final DateTime createdAt;

  const StockDamageEntity({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.costPrice,
    required this.totalCost,
    required this.reason,
    this.notes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, productId, quantity, totalCost, createdAt];
}

class StockAdjustmentEntity extends Equatable {
  final int id;
  final String adjustmentNumber;
  final String status; // draft, approved
  final String? notes;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final List<StockAdjustmentItemEntity> items;

  const StockAdjustmentEntity({
    required this.id,
    required this.adjustmentNumber,
    required this.status,
    this.notes,
    required this.createdAt,
    this.approvedAt,
    this.items = const [],
  });

  @override
  List<Object?> get props => [id, adjustmentNumber, status, createdAt];
}

class StockAdjustmentItemEntity extends Equatable {
  final int id;
  final int adjustmentId;
  final int productId;
  final String productName;
  final double systemQuantity;
  final double actualQuantity;
  final double difference;

  const StockAdjustmentItemEntity({
    required this.id,
    required this.adjustmentId,
    required this.productId,
    required this.productName,
    required this.systemQuantity,
    required this.actualQuantity,
    required this.difference,
  });

  @override
  List<Object?> get props => [id, adjustmentId, productId, actualQuantity, difference];
}
