import 'package:flutter/material.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Successfully Paired and Navigated!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
