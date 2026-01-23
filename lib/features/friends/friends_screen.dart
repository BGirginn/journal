import 'package:flutter/material.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text('Arkadaşlar', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Arkadaş ekleme ve listeleme paneli'),
        ],
      ),
    );
  }
}
