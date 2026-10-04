import 'package:equatable/equatable.dart';

class FinancialReportEntity extends Equatable {
  final double totalSales;
  final double totalSalesCost;
  final double grossProfit;
  final double totalExpenses;
  final double netProfit;
  final double totalPurchases;
  final double totalDamagesCost;
  final int totalInvoicesCount;
  final double currentCashBalance;
  final double totalCustomersDebt;
  final double totalSuppliersDebt;
  final double totalInventoryValuation;

  const FinancialReportEntity({
    required this.totalSales,
    required this.totalSalesCost,
    required this.grossProfit,
    required this.totalExpenses,
    required this.netProfit,
    required this.totalPurchases,
    required this.totalDamagesCost,
    required this.totalInvoicesCount,
    required this.currentCashBalance,
    required this.totalCustomersDebt,
    required this.totalSuppliersDebt,
    required this.totalInventoryValuation,
  });

  @override
  List<Object?> get props => [
        totalSales,
        grossProfit,
        totalExpenses,
        netProfit,
        currentCashBalance,
      ];
}

class TopSellingProductEntity extends Equatable {
  final int productId;
  final String productName;
  final double quantitySold;
  final double totalRevenue;
  final double totalProfit;

  const TopSellingProductEntity({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.totalRevenue,
    required this.totalProfit,
  });

  @override
  List<Object?> get props => [productId, quantitySold, totalRevenue];
}
