import 'package:flutter_test/flutter_test.dart';
import 'package:stacktask_mobile/src/core/result/result_barrel.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('holds value', () {
        const result = Success<int, ErrorCode>(42);
        expect(result.value, 42);
      });

      test('toString contains value', () {
        const result = Success<String, ErrorCode>('hello');
        expect(result.toString(), contains('hello'));
      });

      test('is a Result subtype', () {
        Result<int, ErrorCode> result = const Success(10);
        expect(result, isA<Success<int, ErrorCode>>());
      });
    });

    group('Failure', () {
      test('holds error', () {
        final result = Failure<int, ErrorCode>(
          ErrorCode.fromString(message: 'something went wrong'),
        );
        expect(result.error.message, 'something went wrong');
      });

      test('withError factory creates Failure with ErrorCode', () {
        final result = Failure.withError<List<int>>(
          message: 'not found',
          extraData: {'key': 'value'},
        );
        expect(result.error.message, 'not found');
        expect(result.error.extraData?['key'], 'value');
      });

      test('withError factory works without extraData', () {
        final result = Failure.withError<int>(
          message: 'simple error',
        );
        expect(result.error.message, 'simple error');
        expect(result.error.extraData, isNull);
      });

      test('toString contains error', () {
        final result = Failure<int, ErrorCode>(
          ErrorCode.fromString(message: 'fail'),
        );
        expect(result.toString(), contains('fail'));
      });
    });

    group('Pattern matching', () {
      test('can pattern match on Success', () {
        const Result<int, String> result = Success<int, String>(5);
        switch (result) {
          case Success(:final value):
            expect(value, 5);
          case Failure():
            fail('Expected Success');
        }
      });

      test('can pattern match on Failure', () {
        const Result<int, String> result = Failure<int, String>('error msg');
        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error):
            expect(error, 'error msg');
        }
      });
    });
  });

  group('ErrorCode', () {
    test('fromString with message', () {
      final code = ErrorCode.fromString(message: 'database error');
      expect(code.toString(), 'database error');
      expect(code.toLocalString(), 'database error');
    });

    test('fromString without message returns unknown', () {
      final code = ErrorCode.fromString();
      expect(code.toString(), 'Unknown error');
      expect(code.toLocalString(), 'Unknown error');
    });

    test('fromString with extraData', () {
      final code = ErrorCode.fromString(
        message: 'validation failed',
        extraData: {'field': 'title'},
      );
      expect(code.message, 'validation failed');
      expect(code.extraData?['field'], 'title');
    });
  });
}