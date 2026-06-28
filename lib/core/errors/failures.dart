abstract class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class AIFailure extends Failure {
  const AIFailure(super.message);
}
