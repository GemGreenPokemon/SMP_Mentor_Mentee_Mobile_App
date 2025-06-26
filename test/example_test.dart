import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Example Tests', () {
    test('Simple arithmetic test', () {
      expect(2 + 2, equals(4));
    });

    test('String concatenation test', () {
      final result = 'Hello' + ' ' + 'World';
      expect(result, equals('Hello World'));
    });

    test('List operations test', () {
      final list = [1, 2, 3];
      list.add(4);
      expect(list.length, equals(4));
      expect(list.last, equals(4));
    });
  });
}