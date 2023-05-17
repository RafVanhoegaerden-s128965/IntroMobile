import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class EditProfileView extends StatefulWidget {
  final String userId;
  const EditProfileView({super.key, required this.userId});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  Future<void> _getUser() async {
    log(widget.userId.toString());
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SizedBox(
        height: 150,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text('Username: ${_user?.username}'),
                      const SizedBox(
                        width: 16,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text('Email: ${_user?.email}'),
                      const SizedBox(
                        width: 16,
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: implement logic
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue, // Text color
                    ),
                    child: const Text('Change'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
