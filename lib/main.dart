import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const HikesafeApp());
}

class HikesafeApp extends StatelessWidget {
  const HikesafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClimbLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
