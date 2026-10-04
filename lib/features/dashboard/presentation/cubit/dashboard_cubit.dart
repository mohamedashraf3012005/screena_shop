import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/database/app_database.dart';

abstract class DashboardState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final Map<String, double> todayStats;
  final List<Product> lowStockProducts;
  final double totalInventoryValuation;
  final double totalCustomerDebt;
  final double totalSupplierDebt;

  DashboardLoaded({
    required this.todayStats,
    required this.lowStockProducts,
    required this.totalInventoryValuation,
    required this.totalCustomerDebt,
    required this.totalSupplierDebt,
  });

  @override
  List<Object?> get props => [
        todayStats,
        lowStockProducts,
        totalInventoryValuation,
        totalCustomerDebt,
        totalSupplierDebt,
      ];
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}

class DashboardCubit extends Cubit<DashboardState> {
  final AppDatabase _db;
  DashboardCubit(this._db) : super(DashboardInitial());

  Future<void> loadDashboard() async {
    emit(DashboardLoading());
    try {
      final todayStats = await _db.getTodayStats();
      final lowStock = await _db.getLowStockProducts();
      final invVal = await _db.getTotalInventoryValue();
      final custDebt = await _db.getTotalCustomersBalance();
      final supDebt = await _db.getTotalSuppliersBalance();

      emit(DashboardLoaded(
        todayStats: todayStats,
        lowStockProducts: lowStock,
        totalInventoryValuation: invVal,
        totalCustomerDebt: custDebt,
        totalSupplierDebt: supDebt,
      ));
    } catch (e) {
      emit(DashboardError('حدث خطأ أثناء تحميل لوحة التحكم'));
    }
  }
}
