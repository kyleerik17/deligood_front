import 'package:deligood/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MyApp can be constructed', () {
    expect(const MyApp(orderId: 0), isA<MyApp>());
  });
}
