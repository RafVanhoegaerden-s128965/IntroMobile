import 'package:flutter/material.dart';
import 'package:parq_app/constants/routes.dart';

class SettingsPage extends StatelessWidget {
  final String? userId;
  const SettingsPage({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    // return Scaffold(
    //   appBar: AppBar(
    //     title: const Text(
    //       'Settings',
    //     ),
    //   ),
    //   body: Center(
    //     child: Column(
    //       children: [
    //         // Toon de userId die werd doorgegeven vanuit HomePage
    //         Text(userId.toString()),
    //         // Uitlogknop
    //         TextButton(
    //           onPressed: () {
    //             // Navigate to the register page.
    //             Navigator.of(context)
    //                 .pushNamedAndRemoveUntil(loginRoute, (route) => false);
    //           },
    //           child: const Text('Uitloggen'),
    //         ),
    //       ],
    //     ),
    //   ),
    // );
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person),
            ),
            const SizedBox(height: 20),
            // TODO: verander naar user.name.toString()
            const Text(
              'Naam user',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigeer naar een andere pagina
                //Navigator.of(context).pushNamed();
              },
              child: const Text("Pagina 1"),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: () {
                // Navigeer naar een andere pagina
                //Navigator.of(context).pushNamed(routeTwo);
              },
              child: const Text("Pagina 2"),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: () {
                // Navigeer naar een andere pagina
                //Navigator.of(context).pushNamed(routeThree);
              },
              child: const Text("Pagina 3"),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // Navigeer naar de inlogpagina en verwijder alle eerdere routes uit de stapel.
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
