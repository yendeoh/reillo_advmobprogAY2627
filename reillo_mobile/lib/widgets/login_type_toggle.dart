import 'package:flutter/material.dart';
import '../models/user.dart';

// LAB ACT 5: Lets the sign-in and sign-up screens switch between the
// DummyJSON API and Firebase Auth.
class LoginTypeToggle extends StatelessWidget {
  const LoginTypeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final LoginType value;
  final ValueChanged<LoginType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<LoginType>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: const Color(0xFF202B62),
        selectedForegroundColor: Colors.white,
        foregroundColor: const Color(0xFF202B62),
      ),
      segments: const [
        ButtonSegment(
          value: LoginType.firebase,
          icon: Icon(Icons.local_fire_department_outlined),
          label: Text('Firebase'),
        ),
        ButtonSegment(
          value: LoginType.dummyJson,
          icon: Icon(Icons.cloud_outlined),
          label: Text('DummyJSON'),
        ),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
