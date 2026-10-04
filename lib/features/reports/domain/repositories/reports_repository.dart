import '../entities/report_entity.dart';

abstract class ReportsRepository {
  Future<FinancialReportEntity> getFinancialReport({DateTime? fromDate, DateTime? toDate});
  Future<List<TopSellingProductEntity>> getTopSellingProducts({DateTime? fromDate, DateTime? toDate, int limit = 10});
}
