import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/report_entity.dart';

class ReportsLocalDatasource {
  final AppDatabase _db;
  ReportsLocalDatasource(this._db);

  Future<FinancialReportEntity> getFinancialReport({DateTime? fromDate, DateTime? toDate}) async {
    // 1. Sales
    final salesQuery = _db.select(_db.sales)..where((s) => s.status.equals('completed'));
    if (fromDate != null) salesQuery.where((s) => s.createdAt.isBiggerOrEqualValue(fromDate));
    if (toDate != null) salesQuery.where((s) => s.createdAt.isSmallerOrEqualValue(toDate));
    final salesRows = await salesQuery.get();

    final totalSales = salesRows.fold(0.0, (sum, s) => sum + s.totalAmount);
    final totalSalesCost = salesRows.fold(0.0, (sum, s) => sum + s.costAmount);
    final grossProfit = salesRows.fold(0.0, (sum, s) => sum + s.profitAmount);
    final invoicesCount = salesRows.length;

    // 2. Expenses
    final expQuery = _db.select(_db.expenses);
    if (fromDate != null) expQuery.where((e) => e.expenseDate.isBiggerOrEqualValue(fromDate));
    if (toDate != null) expQuery.where((e) => e.expenseDate.isSmallerOrEqualValue(toDate));
    final expRows = await expQuery.get();
    final totalExpenses = expRows.fold(0.0, (sum, e) => sum + e.amount);

    // 3. Purchases
    final purQuery = _db.select(_db.purchases)..where((p) => p.status.equals('completed'));
    if (fromDate != null) purQuery.where((p) => p.createdAt.isBiggerOrEqualValue(fromDate));
    if (toDate != null) purQuery.where((p) => p.createdAt.isSmallerOrEqualValue(toDate));
    final purRows = await purQuery.get();
    final totalPurchases = purRows.fold(0.0, (sum, p) => sum + p.totalAmount);

    // 4. Damages
    final damQuery = _db.select(_db.stockDamages);
    if (fromDate != null) damQuery.where((d) => d.createdAt.isBiggerOrEqualValue(fromDate));
    if (toDate != null) damQuery.where((d) => d.createdAt.isSmallerOrEqualValue(toDate));
    final damRows = await damQuery.get();
    final totalDamages = damRows.fold(0.0, (sum, d) => sum + d.totalCost);

    // 5. Net Profit
    final netProfit = grossProfit - totalExpenses - totalDamages;

    // 6. Assets & Debts
    final cashBalance = await _db.getCurrentCashBalance();
    final custDebt = await _db.getTotalCustomersBalance();
    final supDebt = await _db.getTotalSuppliersBalance();
    final invValuation = await _db.getTotalInventoryValue();

    return FinancialReportEntity(
      totalSales: totalSales,
      totalSalesCost: totalSalesCost,
      grossProfit: grossProfit,
      totalExpenses: totalExpenses,
      netProfit: netProfit,
      totalPurchases: totalPurchases,
      totalDamagesCost: totalDamages,
      totalInvoicesCount: invoicesCount,
      currentCashBalance: cashBalance,
      totalCustomersDebt: custDebt,
      totalSuppliersDebt: supDebt,
      totalInventoryValuation: invValuation,
    );
  }

  Future<List<TopSellingProductEntity>> getTopSellingProducts({
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 10,
  }) async {
    // Group sale_items by product_id
    final query = '''
      SELECT 
        si.product_id, 
        si.product_name, 
        SUM(si.quantity) as total_qty, 
        SUM(si.total_price) as total_rev, 
        SUM(si.profit_amount) as total_profit
      FROM sale_items si
      INNER JOIN sales s ON s.id = si.sale_id
      WHERE s.status = 'completed'
      ${fromDate != null ? "AND s.created_at >= '${fromDate.toIso8601String()}'" : ""}
      ${toDate != null ? "AND s.created_at <= '${toDate.toIso8601String()}'" : ""}
      GROUP BY si.product_id, si.product_name
      ORDER BY total_qty DESC
      LIMIT $limit
    ''';

    final result = await _db.customSelect(query, readsFrom: {_db.saleItems, _db.sales}).get();

    return result.map((row) {
      return TopSellingProductEntity(
        productId: row.read<int>('product_id'),
        productName: row.read<String>('product_name'),
        quantitySold: (row.read<num>('total_qty')).toDouble(),
        totalRevenue: (row.read<num>('total_rev')).toDouble(),
        totalProfit: (row.read<num>('total_profit')).toDouble(),
      );
    }).toList();
  }
}
