abstract class AppException implements Exception {
  final String message;
  final String? userMessage;
  final dynamic cause;

  const AppException(this.message, {this.userMessage, this.cause});

  @override
  String toString() => message;
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.userMessage, super.cause});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.userMessage, super.cause});
}

class InsufficientStockException extends AppException {
  final String productName;
  final double available;
  final double requested;

  const InsufficientStockException({
    required this.productName,
    required this.available,
    required this.requested,
  }) : super(
          'مخزون غير كافٍ للمنتج: $productName',
          userMessage:
              'الكمية المتاحة من "$productName" هي $available فقط',
        );
}

class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.userMessage});
}

class PermissionException extends AppException {
  const PermissionException(super.message, {super.userMessage});
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.userMessage});
}

// نتيجة العملية (Either pattern)
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final AppException exception;
  const Failure(this.exception);
}

extension ResultExtension<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T get dataOrThrow {
    if (this is Success<T>) return (this as Success<T>).data;
    throw (this as Failure<T>).exception;
  }

  AppException? get error {
    if (this is Failure<T>) return (this as Failure<T>).exception;
    return null;
  }

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(AppException error) onFailure,
  }) {
    return switch (this) {
      Success<T> s => onSuccess(s.data),
      Failure<T> f => onFailure(f.exception),
    };
  }
}
