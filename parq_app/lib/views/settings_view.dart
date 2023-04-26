import 'package:flutter/material.dart';
import 'package:parq_app/constants/routes.dart';

class SettingsPage extends StatelessWidget {
  final String? userId;
  const SettingsPage({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
        ),
      ),
      body: Center(
        child: Column(
          children: [
            // Toon de userId die werd doorgegeven vanuit HomePage
            Text(userId.toString()),
            // Uitlogknop
            TextButton(
              onPressed: () {
                // Navigate to the register page.
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(loginRoute, (route) => false);
              },
              child: const Text('Uitloggen'),
            ),
          ],
        ),
      ),
    );
  }
}
