import 'package:flutter/material.dart';

void main() {
  runApp(const ChartFinderApp());
}

class ChartFinderApp extends StatelessWidget {
  const ChartFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chart Finder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const PlaceholderScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Chart Finder Flutter',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text(
              'Skeleton app ready for navigation/features.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
