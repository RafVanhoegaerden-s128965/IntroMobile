import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:parq_app/constants/routes.dart';
import 'package:parq_app/models/user_model.dart';
import 'package:parq_app/views/cars_view.dart';
import 'package:parq_app/views/change_password_view.dart';
import 'package:parq_app/views/edit_profile_view.dart';

class SettingsPage extends StatefulWidget {
  final String? userId;
  const SettingsPage({super.key, this.userId});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  Future<void> _getUser() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isEqualTo: widget.userId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final userDoc = snapshot.docs.first;
        final userData = userDoc.data();
        final user = User.fromMap(userData);
        setState(() {
          _user = user;
        });
      }
    } catch (error) {
      // Handel eventuele fouten af
      log('Fout bij het ophalen van de gebruikersnaam: $error');
    }
  }

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
              child: Icon(
                Icons.person,
                size: 50,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _user?.username ?? "",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigeer naar een andere pagina
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordView(),
                  ),
                );
              },
              child: const Text("Change password"),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: () {
                // Navigeer naar een andere pagina
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const EditProfileView(),
                  ),
                );
              },
              child: const Text("Edit profile"),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: () {
                // Navigeer naar een andere pagina
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CarPage(
                      userId: _user!.id.toString(),
                    ),
                  ),
                );
              },
              child: const Text("Manage cars"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigeer naar de inlogpagina en verwijder alle eerdere routes uit de stapel.
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(loginRoute, (route) => false);
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
