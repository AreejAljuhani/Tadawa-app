import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:tadawa_app/widgets/profile_image.dart';
import 'package:firebase_storage/firebase_storage.dart';

final _firebase = FirebaseAuth.instance;
final _firestore = FirebaseFirestore.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();

  var _isLogin = true;
  var _enteredUsername = '';
  var _enteredFirstName = '';
  var _enteredLastName = '';
  var _enteredPhone = '';
  var _enteredEmail = '';
  var _enteredPassword = '';
  var _enteredConfirmPassword = '';
  File? _selectedImage;
  var _isAuthenticating = false;

  void _submit() async {
    final isValid = _form.currentState!.validate();

    if (!isValid) {
      return;
    }

    _form.currentState!.save();

    try {
      setState(() {
        _isAuthenticating = true;
      });
      if (_isLogin) {
        await _firebase.signInWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );
      } else {
        final userCredential = await _firebase.createUserWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );

        // Upload image and store user data
        if (_selectedImage != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('user_images')
              .child('${userCredential.user!.uid}.jpg');
          await storageRef.putFile(_selectedImage!);
          var imageUrl = await storageRef.getDownloadURL();

          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'username': _enteredUsername,
            'firstName': _enteredFirstName,
            'lastName': _enteredLastName,
            'phone': _enteredPhone,
            'email': _enteredEmail,
            'image_url': imageUrl,
          });
        }
      }
    } on FirebaseAuthException catch (error) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Authentication failed.'),
        ),
      );
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(255, 254, 247, 255),
        title: Text(_isLogin ? 'Login' : 'Register'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_isLogin)
              Center(
                child: Image.asset(
                  'assets/logos/logo1.PNG',
                  height: 150,
                  width: 150,
                ),
              ),
            const SizedBox(height: 20),
            Form(
              key: _form,
              child: Column(
                children: [
                  if (!_isLogin)
                    ProfileImage(
                      onPickImage: (pickedImage) {
                        _selectedImage = pickedImage;
                      },
                    ),
                  if (!_isLogin)
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _enteredUsername = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your username.';
                        }
                        return null;
                      },
                    ),
                  if (!_isLogin)
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _enteredFirstName = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your first name.';
                        }
                        return null;
                      },
                    ),
                  if (!_isLogin)
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _enteredLastName = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your last name.';
                        }
                        return null;
                      },
                    ),
                  if (!_isLogin)
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (value) {
                        _enteredPhone = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number.';
                        }
                        return null;
                      },
                    ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      _enteredEmail = value;
                    },
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          !value.contains('@')) {
                        return 'Please enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    onChanged: (value) {
                      _enteredPassword = value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length < 6) {
                        return 'Password must be at least 6 characters long.';
                      }
                      return null;
                    },
                  ),
                  if (!_isLogin)
                    TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                          border: OutlineInputBorder()),
                      obscureText: true,
                      onChanged: (value) {
                        _enteredConfirmPassword = value;
                      },
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            value != _enteredPassword) {
                          return 'Passwords do not match.';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      minimumSize:
                          const Size(double.infinity, 50), // Full width
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: const Color.fromARGB(
                          255, 46, 161, 132), // Background color
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: Text(
                      _isLogin ? 'Login' : 'Register',
                      style: const TextStyle(color: Colors.white), // Text color
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                      });
                    },
                    child: Text(
                      _isLogin
                          ? 'Create new account'
                          : 'I already have an account',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
