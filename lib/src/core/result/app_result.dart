import '../errors/app_failure.dart';

sealed class AppResult<T> {
  const AppResult();

  bool get isSuccess => this is AppSuccess<T>;
  bool get isFailure => this is AppFailureResult<T>;

  R when<R>({
    required R Function(T value) success,
    required R Function(AppFailure failure) failure,
  }) {
    final current = this;
    if (current is AppSuccess<T>) {
      return success(current.value);
    }
    return failure((current as AppFailureResult<T>).error);
  }
}

final class AppSuccess<T> extends AppResult<T> {
  const AppSuccess(this.value);

  final T value;
}

final class AppFailureResult<T> extends AppResult<T> {
  const AppFailureResult(this.error);

  final AppFailure error;
}
