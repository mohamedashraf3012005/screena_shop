import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final int productCount;
  final DateTime createdAt;

  const CategoryEntity({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    required this.productCount,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, isActive];
}

class ProductTypeEntity extends Equatable {
  final int id;
  final int categoryId;
  final String categoryName;
  final String name;
  final String? description;
  final bool isActive;
  final int productCount;
  final DateTime createdAt;

  const ProductTypeEntity({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    this.description,
    required this.isActive,
    required this.productCount,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, categoryId, name];
}
