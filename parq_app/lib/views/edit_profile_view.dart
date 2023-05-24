import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class EditProfileView extends StatefulWidget {
  final String userId;
  const EditProfileView({Key? key, required this.userId}) : super(key: key);

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  User? _user;

  final _formKey = GlobalKey<FormState>();

  // Input fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Sets if editting active
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  // Get user
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
        _usernameController.text = user.username;
        _emailController.text = user.email;
      }
    } catch (error) {
      log('Failed to fetch username: $error');
    }
  }

  // Edit user
  Future<void> _editUser(User user) async {
    try {
      final usernameSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: user.username)
          .get();
      final emailSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .get();

      if (usernameSnapshot.docs.isNotEmpty &&
          user.username != _user?.username) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A user with this username already exists'),
          ),
        );
        return;
      }

      if (emailSnapshot.docs.isNotEmpty && user.email != _user?.email) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A user with this email already exists'),
          ),
        );
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isEqualTo: widget.userId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final docId = snapshot.docs.first.id;
        await FirebaseFirestore.instance.collection('users').doc(docId).update({
          'username': user.username,
          'email': user.email,
        });
        setState(() {
          _getUser();
          _isEditing = false;
        });
      } else {
        log('User not found in the database.');
      }
    } catch (e) {
      log('Failed to update user: $e');
    }
  }

  Widget _buildUserInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Text(
              'Username',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('${_user?.username}'),
            const Text(
              'Email',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('${_user?.email}'),
            const SizedBox(height: 20),
            SizedBox(
              width: 390,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                ),
                child: const Text('Edit Profile'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Username',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextFormField(
            controller: _usernameController,
            textAlign: TextAlign.center,
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter a username.';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Email',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textAlign: TextAlign.center,
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter an email address.';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Please enter a valid email address.';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 390,
            child: Column(
              children: [
                SizedBox(
                  width: 400,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        String newUsername = _usernameController.text.trim();
                        String newEmail = _emailController.text.trim();
                        if (newUsername.isNotEmpty && newEmail.isNotEmpty) {
                          User user = User(
                            id: widget.userId,
                            email: newEmail,
                            username: newUsername,
                            avgRating: _user!.avgRating,
                            numRatings: _user!.numRatings,
                            totalRating: _user!.totalRating,
                            password: _user!.password,
                          );
                          _editUser(user);
                        } else {
                          log('Please enter values for all fields.');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save Changes'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 400,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cancel'),
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
        title: const Text('Edit profile'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SizedBox(
        height: 300,
        width: 550,
        child: _isEditing ? _buildForm() : _buildUserInfo(),
      ),
    );
  }
}
