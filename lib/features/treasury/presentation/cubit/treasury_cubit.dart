import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/treasury_entity.dart';
import '../../domain/repositories/treasury_repository.dart';

abstract class TreasuryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TreasuryInitial extends TreasuryState {}

class TreasuryLoading extends TreasuryState {}

class TreasuryLoaded extends TreasuryState {
  final double currentBalance;
  final List<CashTransactionEntity> transactions;
  final CashSessionEntity? activeSession;

  TreasuryLoaded({
    required this.currentBalance,
    required this.transactions,
    this.activeSession,
  });

  @override
  List<Object?> get props => [currentBalance, transactions, activeSession];
}

class TreasuryError extends TreasuryState {
  final String message;
  TreasuryError(this.message);
  @override
  List<Object?> get props => [message];
}

class TreasuryCubit extends Cubit<TreasuryState> {
  final TreasuryRepository _repository;
  TreasuryCubit(this._repository) : super(TreasuryInitial());

  Future<void> loadTreasury({DateTime? fromDate, DateTime? toDate, String? type}) async {
    emit(TreasuryLoading());
    try {
      final balance = await _repository.getCurrentBalance();
      final txs = await _repository.getTransactions(fromDate: fromDate, toDate: toDate, type: type);
      final session = await _repository.getActiveSession();
      emit(TreasuryLoaded(
        currentBalance: balance,
        transactions: txs,
        activeSession: session,
      ));
    } catch (e) {
      emit(TreasuryError('حدث خطأ أثناء تحميل بيانات الخزينة'));
    }
  }

  Future<bool> addCashMovement({
    required double amount,
    required String type,
    required String description,
    String? notes,
    int? userId,
  }) async {
    try {
      await _repository.addCashMovement(
        amount: amount,
        type: type,
        description: description,
        notes: notes,
        userId: userId,
      );
      await loadTreasury();
      return true;
    } catch (e) {
      emit(TreasuryError('حدث خطأ أثناء تسجيل حركة الخزينة'));
      return false;
    }
  }

  Future<bool> openSession(double openingBalance, {int? userId}) async {
    try {
      await _repository.openSession(openingBalance: openingBalance, userId: userId);
      await loadTreasury();
      return true;
    } catch (e) {
      emit(TreasuryError('حدث خطأ أثناء فتح الجلسة اليومية'));
      return false;
    }
  }

  Future<bool> closeSession(int sessionId, double actualBalance, {String? notes}) async {
    try {
      final success = await _repository.closeSession(
        sessionId: sessionId,
        actualBalance: actualBalance,
        notes: notes,
      );
      await loadTreasury();
      return success;
    } catch (e) {
      emit(TreasuryError('حدث خطأ أثناء إغلاق الجلسة اليومية'));
      return false;
    }
  }
}
