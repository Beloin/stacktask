import 'package:stacktask_mobile/src/core/result/error_code.dart';

sealed class Result<S, E> {
  const Result();
}

typedef AsyncResult<S, E> = Future<Result<S, E>>;

final class Success<S, E> extends Result<S, E> {
  const Success(this.value);

  final S value;

  @override
  String toString() => 'Success: $value';
}

final class Failure<S, E> extends Result<S, E> {
  const Failure(this.error);

  final E error;

  static Failure<S, ErrorCode> withError<S>({
    String? message,
    Map<String, dynamic>? extraData,
  }) {
    return Failure(ErrorCode.fromString(
      message: message,
      extraData: extraData,
    ));
  }

  @override
  String toString() => 'Failure: $error';
}