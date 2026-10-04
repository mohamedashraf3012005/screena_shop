import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';

abstract class SettingsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final ShopSettingsEntity settings;
  SettingsLoaded(this.settings);
  @override
  List<Object?> get props => [settings];
}

class SettingsError extends SettingsState {
  final String message;
  SettingsError(this.message);
  @override
  List<Object?> get props => [message];
}

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repository;
  SettingsCubit(this._repository) : super(SettingsInitial());

  Future<void> loadSettings() async {
    emit(SettingsLoading());
    try {
      final s = await _repository.getSettings();
      emit(SettingsLoaded(s));
    } catch (e) {
      emit(SettingsError('حدث خطأ أثناء تحميل الإعدادات'));
    }
  }

  Future<bool> updateSettings(ShopSettingsEntity settings) async {
    try {
      final success = await _repository.updateSettings(settings);
      if (success) emit(SettingsLoaded(settings));
      return success;
    } catch (e) {
      emit(SettingsError('حدث خطأ أثناء حفظ الإعدادات'));
      return false;
    }
  }

  Future<String?> backupDatabase(String destinationDir) async {
    try {
      return await _repository.backupDatabase(destinationDir);
    } catch (_) {
      return null;
    }
  }

  Future<bool> restoreDatabase(String sourceFilePath) async {
    try {
      return await _repository.restoreDatabase(sourceFilePath);
    } catch (_) {
      return false;
    }
  }
}
