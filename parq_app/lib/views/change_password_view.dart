import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';

class ChangePasswordView extends StatefulWidget {
  final String userId;

  const ChangePasswordView({Key? key, required this.userId}) : super(key: key);

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  User? _user;

  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

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
        _passwordController.text = '';
        _confirmPasswordController.text = '';
      }
    } catch (error) {
      log('Failed to fetch password: $error');
    }
  }

  Future<void> _editUser(User user) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isEqualTo: widget.userId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final docId = snapshot.docs.first.id;

        // Encrypt the new password with SHA256
        final hashedPassword =
            sha256.convert(utf8.encode(user.password)).toString();

        await FirebaseFirestore.instance.collection('users').doc(docId).update({
          'password': hashedPassword,
        });

        setState(() {
          _getUser();
          _isEditing = !_isEditing;
        });
      } else {
        log('User not found in the database.');
      }
    } catch (e) {
      log('Failed to update user: $e');
    }
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Password',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isEditing,
            textAlign: TextAlign.center,
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter a password.';
              }
              if (value != _confirmPasswordController.text) {
                return 'Passwords do not match.';
              }
              return null;
            },
          ),
          const Text(
            'Confirm password',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isEditing,
            textAlign: TextAlign.center,
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter a password.';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match.';
              }
              return null;
            },
          ),
          SizedBox(
            width: 400,
            child: Column(
              children: [
                SizedBox(
                  width: 400,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        String newPassword = _passwordController.text.trim();

                        if (newPassword.isNotEmpty) {
                          User user = User(
                            id: widget.userId,
                            email: _user!.email,
                            username: _user!.username,
                            avgRating: _user!.avgRating,
                            numRatings: _user!.numRatings,
                            totalRating: _user!.totalRating,
                            password: newPassword,
                          );
                          _editUser(user);
                        } else {
                          log('Please enter a value.');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save Change'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 400,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = !_isEditing;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Show password'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change password'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SizedBox(
        height: 300,
        width: 500,
        child: _buildForm(),
      ),
    );
  }
}
