import '../errors/app_failure.dart';

enum SyncStatus {
  initial,
  loading,
  success,
  failure,
  refreshing,
  submitting,
  stale;
}

class AsyncState<T> {
  const AsyncState({
    required this.status,
    this.data,
    this.error,
  });

  const AsyncState.initial() : this(status: SyncStatus.initial);
  const AsyncState.loading({T? data})
    : this(status: SyncStatus.loading, data: data);
  const AsyncState.refreshing({T? data})
    : this(status: SyncStatus.refreshing, data: data);
  const AsyncState.submitting({T? data})
    : this(status: SyncStatus.submitting, data: data);
  const AsyncState.success(T data)
    : this(status: SyncStatus.success, data: data);
  const AsyncState.failure(AppFailure error, {T? data})
    : this(status: SyncStatus.failure, data: data, error: error);
  const AsyncState.stale(T data, {AppFailure? error})
    : this(status: SyncStatus.stale, data: data, error: error);

  final SyncStatus status;
  final T? data;
  final AppFailure? error;
}
