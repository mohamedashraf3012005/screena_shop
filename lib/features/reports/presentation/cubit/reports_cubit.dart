import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/reports_repository.dart';

abstract class ReportsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

class ReportsLoaded extends ReportsState {
  final FinancialReportEntity financial;
  final List<TopSellingProductEntity> topProducts;
  final DateTime? fromDate;
  final DateTime? toDate;

  ReportsLoaded({
    required this.financial,
    required this.topProducts,
    this.fromDate,
    this.toDate,
  });

  @override
  List<Object?> get props => [financial, topProducts, fromDate, toDate];
}

class ReportsError extends ReportsState {
  final String message;
  ReportsError(this.message);
  @override
  List<Object?> get props => [message];
}

class ReportsCubit extends Cubit<ReportsState> {
  final ReportsRepository _repository;
  ReportsCubit(this._repository) : super(ReportsInitial());

  Future<void> loadReport({DateTime? fromDate, DateTime? toDate}) async {
    emit(ReportsLoading());
    try {
      final financial = await _repository.getFinancialReport(fromDate: fromDate, toDate: toDate);
      final topProducts = await _repository.getTopSellingProducts(fromDate: fromDate, toDate: toDate);
      emit(ReportsLoaded(
        financial: financial,
        topProducts: topProducts,
        fromDate: fromDate,
        toDate: toDate,
      ));
    } catch (e) {
      emit(ReportsError('حدث خطأ أثناء إعداد التقرير المالي'));
    }
  }
}
