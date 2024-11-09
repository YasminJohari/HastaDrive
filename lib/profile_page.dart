import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Details',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const ProfileDetail(label: 'Name', value: 'John Doe'),
            const SizedBox(height: 8),
            const ProfileDetail(label: 'Email', value: 'john.doe@example.com'),
            const SizedBox(height: 8),
            const ProfileDetail(label: 'Phone Number', value: '+60123456789'),
            const SizedBox(height: 8),
            const ProfileDetail(label: 'Gender', value: 'Male'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Handle edit profile logic
              },
              child: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileDetail extends StatelessWidget {
  final String label;
  final String value;

  const ProfileDetail({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 18)),
        Text(value, style: const TextStyle(fontSize: 18)),
      ],
    );
  }
}
