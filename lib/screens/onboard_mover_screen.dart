import 'package:flutter/material.dart';
import '../widgets/onboard_driver_form.dart';

class OnboardMoverScreen extends StatelessWidget {
  const OnboardMoverScreen({super.key});
  @override
  Widget build(BuildContext context) => const OnboardDriverForm(mover: true);
}
