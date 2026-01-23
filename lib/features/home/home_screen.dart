import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text('Anasayfa', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Hoş geldiniz!'),
        ],
      ),
    );
  }
}
