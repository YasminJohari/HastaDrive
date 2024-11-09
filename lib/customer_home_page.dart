//customer_home_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_page.dart';
import 'order_history_page.dart';
import 'profile_page.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  _CustomerHomePageState createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  // Variables for dropdowns
  String carType = 'Select';
  String gearType = 'Select';
  String numberOfSeats = 'Select';

  // Current index for bottom navigation bar
  int _currentIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Handle navigation based on the selected index
    switch (index) {
      case 0:
        // Stay on the current page (Customer Home Page)
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OrderHistoryPage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("CAR TYPE"),
                    DropdownButton<String>(
                      value: carType,
                      items: <String>[
                        'Select',
                        'Subcompact',
                        'Sedan',
                        'Minivan'
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          carType = newValue!;
                        });
                      },
                    ),
                    const Text("GEAR TYPE"),
                    DropdownButton<String>(
                      value: gearType,
                      items: <String>['Select', 'Automatic', 'Manual']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          gearType = newValue!;
                        });
                      },
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("NUMBER OF SEATS"),
                    DropdownButton<String>(
                      value: numberOfSeats,
                      items: <String>['Select', '5', '7'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          numberOfSeats = newValue!;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Fetch and display car data from Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('cars').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var filteredCars = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (carType == 'Select' || data['type'] == carType) &&
                      (gearType == 'Select' || data['gear'] == gearType) &&
                      (numberOfSeats == 'Select' ||
                          data['seats'].toString() == numberOfSeats);
                }).toList();

                return ListView.builder(
                  itemCount: filteredCars.length,
                  itemBuilder: (context, index) {
                    final carData =
                        filteredCars[index].data() as Map<String, dynamic>;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      child: Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 140, 20, 20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            // Car image with fallback/default image
                            Container(
                              width: 120,
                              height: 120,
                              margin: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: carData['imageUrl'] != null &&
                                          carData['imageUrl'].isNotEmpty
                                      ? NetworkImage(carData['imageUrl'])
                                      : const AssetImage(
                                              'assets/images/default_car.jpg')
                                          as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            // Car details and Book button
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 18),
                                  Text(
                                    carData['name'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'RM${carData['pricePerDay']} per day',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  // Displaying only the 1-hour rate from the pricePerHour map as double
                                  Text(
                                    'RM${carData['pricePerHour']['1']} per hour (1 hour rate)',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BookingPage(
                                            carName: carData['name'],
                                            carType: carData['type'],
                                            gearType: carData['gear'],
                                            seats: carData['seats'].toString(),
                                            pricePerDay: carData['pricePerDay'],
                                            pricePerHour:
                                                Map<String, double>.from(
                                                    carData['pricePerHour']),
                                            imageUrl: carData['imageUrl'],
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Book'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Image.network(
              'https://cdn3.iconfinder.com/data/icons/feather-5/24/home-256.png',
              width: 24,
              height: 24,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Image.network(
              'https://cdn3.iconfinder.com/data/icons/feather-5/24/clock-256.png',
              width: 24,
              height: 24,
            ),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Image.network(
              'https://cdn3.iconfinder.com/data/icons/feather-5/24/user-256.png',
              width: 24,
              height: 24,
            ),
            label: 'Profile',
          ),
        ],
        currentIndex: _currentIndex,
        selectedItemColor: Colors.red,
        onTap: _onItemTapped,
      ),
    );
  }
}
