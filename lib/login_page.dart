//login_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_home_page.dart';
import 'hasta_home_page.dart';
import 'sign_up_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SingleChildScrollView(
        // Added to allow scrolling
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add the image at the top
            Image.asset(
              'assets/HASTA_LOGO.png', // Replace with your image asset path
              height: 100, // Adjust the height as needed
              fit: BoxFit.cover, // Adjust fit if necessary
            ),
            const SizedBox(height: 16), // Space below the image
            const Text(
              'Welcome Back!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                try {
                  final username = usernameController.text.trim();
                  final password = passwordController.text.trim();

                  // Step 1: Retrieve email based on username
                  final userQuery = await FirebaseFirestore.instance
                      .collection('users')
                      .where('username', isEqualTo: username)
                      .get();

                  if (userQuery.docs.isNotEmpty) {
                    final userData = userQuery.docs.first;
                    final email = userData['email'];

                    // Step 2: Sign in with the retrieved email
                    UserCredential userCredential =
                        await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: email,
                      password: password,
                    );

                    User user = userCredential.user!;

                    // Step 3: Check if the email is verified
                    if (user.emailVerified) {
                      // Update Firestore 'verified' field
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .update({'verified': true});

                      // Redirect based on user type
                      String userType = userData.data().containsKey('userType')
                          ? userData['userType']
                          : 'unknown';

                      if (userType == 'customer') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CustomerHomePage()),
                        );
                      } else if (userType == 'hasta') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HastaHomePage()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Unknown user type')),
                        );
                      }
                    } else {
                      // If email is not verified, prompt the user
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Please verify your email to proceed.')),
                      );
                      // Optionally resend verification email
                      await user.sendEmailVerification();
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid username')),
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.message ?? 'Unknown error')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('An error occurred: $e')),
                  );
                }
              },
              child: const Text('Login'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                // Implement forgot password feature
                final username = usernameController.text.trim();

                if (username.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your username')),
                  );
                  return;
                }

                try {
                  // Retrieve email based on username
                  final userQuery = await FirebaseFirestore.instance
                      .collection('users')
                      .where('username', isEqualTo: username)
                      .get();

                  if (userQuery.docs.isNotEmpty) {
                    final email = userQuery.docs.first['email'];

                    // Send password reset email
                    await FirebaseAuth.instance
                        .sendPasswordResetEmail(email: email);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Password reset email sent to $email')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Username not found')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Forgot Password?'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const SignUpPage()), // Navigate to sign-up page
                );
              },
              child: const Text('Don\'t have an account? Sign up here'),
            ),
          ],
        ),
      ),
    );
  }
}
