import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final int id;
  final String username;
  final String fullName;
  final String role;
  final bool isActive;

  const UserEntity({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.isActive,
  });

  bool get isAdmin => role == 'admin';
  bool get isFinance => role == 'finance' || role == 'admin';
  bool get isCashier => role == 'cashier' || role == 'admin';

  bool get canDeleteInvoices => role == 'admin';
  bool get canEditStockManually => role == 'admin' || role == 'finance';
  bool get canEditPurchaseCost => role == 'admin' || role == 'finance';
  bool get canDeleteFinancialTrans => role == 'admin';
  bool get canViewReports => role == 'admin' || role == 'finance';
  bool get canViewTreasury => role == 'admin' || role == 'finance';
  bool get canManageUsers => role == 'admin';

  @override
  List<Object?> get props => [id, username, fullName, role, isActive];
}
