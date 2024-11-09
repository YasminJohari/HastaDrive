//agreement_confirmation_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AgreementConfirmationPage extends StatelessWidget {
  final String carName;
  final String carType;
  final String gearType;
  final String seats;
  final DateTime pickupDate;
  final DateTime returnDate;
  final String pickupLocation;
  final String returnLocation;
  final double totalPrice;
  final List<Map<String, dynamic>> priceBreakdown; // Add price breakdown
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String? customPickupLocation;
  final String? customReturnLocation;

  const AgreementConfirmationPage({
    super.key,
    required this.carName,
    required this.carType,
    required this.gearType,
    required this.seats,
    required this.pickupDate,
    required this.returnDate,
    required this.pickupLocation,
    required this.returnLocation,
    required this.totalPrice,
    required this.priceBreakdown,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    this.customPickupLocation,
    this.customReturnLocation,
  });

  void _confirmBooking(BuildContext context) async {
    try {
      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;

      // Add booking details to Firestore if the car is available
      final bookingRef =
          FirebaseFirestore.instance.collection('bookings').doc();
      await bookingRef.set({
        'carName': carName,
        'carType': carType,
        'gearType': gearType,
        'seats': seats,
        'pickupDate': pickupDate,
        'returnDate': returnDate,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'totalPrice': totalPrice,
        'pickupLocation': pickupLocation == 'Others'
            ? customPickupLocation ?? ''
            : pickupLocation,
        'returnLocation': returnLocation == 'Others'
            ? customReturnLocation ?? ''
            : returnLocation,
        'priceBreakdown': priceBreakdown,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking Successful!')),
      );

      Future.delayed(const Duration(seconds: 3), () {
        Navigator.popUntil(context, (route) => route.isFirst);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Agreement')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Car Details',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Car Name: $carName'),
            Text('Car Type: $carType'),
            Text('Gear Type: $gearType'),
            Text('Seats: $seats'),
            const SizedBox(height: 20),
            const Text(
              'Booking Details',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Pickup Location: $pickupLocation'),
            Text('Pickup Date & Time: ${pickupDate.toLocal()}'),
            Text('Return Location: $returnLocation'),
            Text('Return Date & Time: ${returnDate.toLocal()}'),
            const SizedBox(height: 20),
            const Text(
              'Price Breakdown',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...priceBreakdown.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['description'],
                        style: const TextStyle(fontSize: 11),
                      ),
                      Text(
                        'RM${item['amount'].toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                )),
            const Divider(thickness: 1.5),
            Text(
              'Total Price: RM${totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Note: If there is any damage to the car, you are responsible for paying for the service charge.',
              style: TextStyle(color: Colors.red),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _confirmBooking(context),
              child: const Text('I Agree to the Terms and Conditions'),
            ),
          ],
        ),
      ),
    );
  }
}
