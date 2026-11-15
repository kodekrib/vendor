import 'package:flutter_test/flutter_test.dart';
import 'package:vendor/widgets/common.dart';
void main(){
 test('Fractional commissions remain visible',(){
  expect(formatPrice(0.25),endsWith('0.25'));
  expect(formatPrice(1200.75),endsWith('1,200.75'));
 });
}
