//main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await registerHasta(); // Register the hasta admin account only once

  // Add cars to Firestore initially (comment out after first run)
  await addCarsToFirestore();

  runApp(const MyApp());
}

// Function to register hasta admin user
Future<void> registerHasta() async {
  const String adminEmail = 'hastaad2425@gmail.com';
  const String adminPassword = 'Duck12345';
  const String adminUsername = 'hastaAdmin';

  try {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc('hasta').get();

    if (!userDoc.exists) {
      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': adminEmail,
          'username': adminUsername,
          'userType': 'hasta',
        });

        print(
            'Hasta admin account created successfully in Firebase Auth and Firestore.');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          print('Admin email already in use.');
        } else {
          print('Error creating admin in Firebase Auth: ${e.message}');
        }
      }
    } else {
      print('Hasta admin already exists in Firestore.');
    }
  } catch (e) {
    print('Error during hasta registration: $e');
  }
}

// Function to add car data to Firestore
Future<void> addCarsToFirestore() async {
  CollectionReference cars = FirebaseFirestore.instance.collection('cars');

  List<Map<String, dynamic>> carData = [
    {
      'name': 'Perodua Axia',
      'type': 'Subcompact',
      'gear': 'Automatic',
      'seats': 5,
      'pricePerDay': 110.0,
      'pricePerHour': {
        '1': 30.0,
        '3': 50.0,
        '5': 60.0,
        '7': 65.0,
        '9': 70.0,
        '12': 80.0,
        '24': 110.0,
      },
      'imageUrl': 'https://hastatravel.com/assets/img/kereta/axia.jpg'
    },
    {
      'name': 'Perodua Bezza',
      'type': 'Sedan',
      'gear': 'Automatic',
      'seats': 5,
      'pricePerDay': 120.0,
      'pricePerHour': {
        '1': 35.0,
        '3': 55.0,
        '5': 65.0,
        '7': 70.0,
        '9': 75.0,
        '12': 85.0,
        '24': 120.0,
      },
      'imageUrl': 'https://hastatravel.com/assets/img/kereta/bezza2016.jpg'
    },
    {
      'name': 'Perodua Myvi',
      'type': 'Subcompact',
      'gear': 'Automatic',
      'seats': 5,
      'pricePerDay': 120.0,
      'pricePerHour': {
        '1': 35.0,
        '3': 55.0,
        '5': 65.0,
        '7': 70.0,
        '9': 75.0,
        '12': 85.0,
        '24': 120.0,
      },
      'imageUrl': 'https://hastatravel.com/assets/img/kereta/myvi2012.jpg'
    },
    // Commenting out Toyota Alphard entry to skip adding it
    /*
    {
      'name': 'Toyota Alphard',
      'type': 'Minivan',
      'gear': 'Automatic',
      'seats': 7,
      'pricePerDay': 300.0,
      'pricePerHour': {'1': 45.0}, // Example flat rate, can adjust if needed
      'imageUrl':
          'https://hastatravel.com/assets/img/kereta/alphard/alphard.jpg'
    },
    */
    // Add more cars here as needed
  ];

  for (var car in carData) {
    // Check if the car already exists using the name as a document ID
    DocumentReference carDoc = cars.doc(car['name']);
    DocumentSnapshot existingCar = await carDoc.get();

    if (!existingCar.exists) {
      // If the car does not exist, add it
      await carDoc.set(car);
      print('Added car: ${car['name']} to Firestore.');
    } else {
      print('Car already exists: ${car['name']}. Skipping.');
    }
  }
  print('Car data processed for Firestore.');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hasta Rental',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
    );
  }
}
