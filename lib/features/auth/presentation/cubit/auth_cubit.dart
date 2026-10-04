import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';

// ─── States ───
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Cubit ───
class AuthCubit extends Cubit<AuthState> {
  final LoginUsecase _loginUsecase;
  UserEntity? _currentUser;

  AuthCubit(this._loginUsecase) : super(AuthInitial());

  UserEntity? get currentUser => _currentUser;

  Future<void> login(String username, String password) async {
    emit(AuthLoading());
    try {
      final user = await _loginUsecase(username, password);
      if (user != null) {
        _currentUser = user;
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthError('اسم المستخدم أو كلمة المرور غير صحيحة'));
      }
    } catch (e) {
      emit(AuthError('حدث خطأ أثناء تسجيل الدخول. يرجى المحاولة مرة أخرى'));
    }
  }

  void logout() {
    _currentUser = null;
    emit(AuthUnauthenticated());
  }
}
