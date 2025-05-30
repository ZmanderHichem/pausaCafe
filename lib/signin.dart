import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_application_1/mainHome.dart';
import 'package:saadoun/auth.dart';
import 'package:saadoun/localStorage.dart';
import 'package:saadoun/mainHome.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();

  String? errorMessage = "";

  Future<void> addToLocalStorage(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
    print('Data added to local storage');
  }

  LStorage lStorage = LStorage();

  @override
  void initState() {
    super.initState();
    Auth().signOut();
  }

  Future<Map<String, dynamic>> getUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user is currently signed in');
        return {};
      }

      print('Fetching user data for UID: ${user.uid}');
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (snapshot.exists) {
        print('User data found: ${snapshot.data()}');
        return snapshot.data()!;
      } else {
        print('No user document found for UID: ${user.uid}');
        return {};
      }
    } catch (e) {
      print('Error fetching user data: $e');
      rethrow;
    }
  }

  Future<void> signInWithEmailAndPassword(BuildContext context) async {
    try {
      print('Attempting to sign in...');
      print('Email: ${_controllerEmail.text}');
      print('Password: ${_controllerPassword.text}');

      await Auth()
          .signInWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      )
          .then((value) async {
        print('Authentication successful');
        try {
          Map<String, dynamic> userData = await getUserData();
          print('User Data retrieved: $userData');
          String jsonMap = jsonEncode(userData);
          print('User Data encoded to JSON');
          await lStorage.addToLocalStorage('userData', jsonMap);
          print('User Data saved to local storage');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BottomNavigation()),
          );
        } catch (e) {
          print('Error in user data processing: $e');
          rethrow;
        }
      });
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      setState(() {
        errorMessage = e.code;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            backgroundColor: const Color.fromARGB(255, 207, 62, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        );
      });
    } catch (e) {
      print('Unexpected Error: $e');
      setState(() {
        errorMessage = 'An unexpected error occurred';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            backgroundColor: const Color.fromARGB(255, 207, 62, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Redirection directe vers l'écran principal
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const BottomNavigation()),
            );
          },
          child: const Text('Accéder à l\'application'),
        ),
      ),
    );
  }
}
