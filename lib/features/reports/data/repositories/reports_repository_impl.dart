import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_local_datasource.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsLocalDatasource _datasource;
  ReportsRepositoryImpl(this._datasource);

  @override
  Future<FinancialReportEntity> getFinancialReport({DateTime? fromDate, DateTime? toDate}) =>
      _datasource.getFinancialReport(fromDate: fromDate, toDate: toDate);

  @override
  Future<List<TopSellingProductEntity>> getTopSellingProducts({DateTime? fromDate, DateTime? toDate, int limit = 10}) =>
      _datasource.getTopSellingProducts(fromDate: fromDate, toDate: toDate, limit: limit);
}
