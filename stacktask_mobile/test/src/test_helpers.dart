import 'package:stacktask_mobile/src/core/result/result_barrel.dart';

extension ResultWhen<S, E> on Result<S, E> {
  T when<T>({
    required T Function(S value) success,
    required T Function(E error) failure,
  }) {
    return switch (this) {
      Success(:final value) => success(value),
      Failure(:final error) => failure(error),
    };
  }
}
