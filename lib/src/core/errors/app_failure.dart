sealed class AppFailure {
  const AppFailure(this.message);

  final String message;
}

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([super.message = 'Please sign in to continue.']);
}

final class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure([super.message = 'You do not have permission for that action.']);
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'The requested item could not be found.']);
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'Network unavailable. Please try again.']);
}

final class ServerFailure extends AppFailure {
  const ServerFailure([super.message = 'Something went wrong on the server.']);
}

final class ConflictFailure extends AppFailure {
  const ConflictFailure(super.message);
}
