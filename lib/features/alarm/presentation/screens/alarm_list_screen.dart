import 'package:flutter/material.dart';
import 'home_screen.dart';

/// Legacy export and compatibility wrapper for [HomeScreen]
class AlarmListScreen extends StatelessWidget {
  const AlarmListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
