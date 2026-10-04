import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final int id;
  final String name;
  final String? barcode;
  final int? categoryId;
  final String? categoryName;
  final int? productTypeId;
  final String? productTypeName;
  final String? description;
  final String unit;
  final double currentQuantity;
  final double minQuantity;
  final double costPrice;
  final double sellPrice;
  final double groupPrice;
  final double groupQuantity;
  final double weightedAvgCost;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductEntity({
    required this.id,
    required this.name,
    this.barcode,
    this.categoryId,
    this.categoryName,
    this.productTypeId,
    this.productTypeName,
    this.description,
    required this.unit,
    required this.currentQuantity,
    required this.minQuantity,
    required this.costPrice,
    required this.sellPrice,
    required this.groupPrice,
    required this.groupQuantity,
    required this.weightedAvgCost,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'active';
  bool get isLowStock =>
      currentQuantity <= minQuantity && minQuantity > 0;
  bool get isOutOfStock => currentQuantity <= 0;

  double get profitPerUnit => sellPrice - weightedAvgCost;
  double get profitPerGroup =>
      groupPrice - (weightedAvgCost * groupQuantity);
  double get profitMargin =>
      sellPrice > 0 ? (profitPerUnit / sellPrice) * 100 : 0;
  double get inventoryValue => currentQuantity * weightedAvgCost;

  @override
  List<Object?> get props => [
        id,
        name,
        barcode,
        categoryId,
        productTypeId,
        unit,
        currentQuantity,
        costPrice,
        sellPrice,
        status,
      ];

  ProductEntity copyWith({
    int? id,
    String? name,
    String? barcode,
    int? categoryId,
    String? categoryName,
    int? productTypeId,
    String? productTypeName,
    String? description,
    String? unit,
    double? currentQuantity,
    double? minQuantity,
    double? costPrice,
    double? sellPrice,
    double? groupPrice,
    double? groupQuantity,
    double? weightedAvgCost,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      productTypeId: productTypeId ?? this.productTypeId,
      productTypeName: productTypeName ?? this.productTypeName,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      minQuantity: minQuantity ?? this.minQuantity,
      costPrice: costPrice ?? this.costPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      groupPrice: groupPrice ?? this.groupPrice,
      groupQuantity: groupQuantity ?? this.groupQuantity,
      weightedAvgCost: weightedAvgCost ?? this.weightedAvgCost,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
