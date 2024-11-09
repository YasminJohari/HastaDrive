//booking_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'agreement_confirmation_page.dart';

class BookingPage extends StatefulWidget {
  final String carName;
  final String carType;
  final String gearType;
  final String seats;
  final double pricePerDay;
  final Map<String, double> pricePerHour;
  final String imageUrl;

  const BookingPage({
    super.key,
    required this.carName,
    required this.carType,
    required this.gearType,
    required this.seats,
    required this.pricePerDay,
    required this.pricePerHour,
    required this.imageUrl,
  });

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _pickupLocationController = TextEditingController();
  final _returnLocationController = TextEditingController();
  DateTime? _pickupDate;
  DateTime? _returnDate;
  String? customerName;
  String? customerEmail;
  String? customerPhone;
  double totalPrice = 0.0;
  double officehour = 0.0;
  String? _pickupLocation;
  String? _returnLocation;
  String? _customPickupLocation;
  String? _customReturnLocation;
  double customLocation = 0.0;

  List<Map<String, dynamic>> priceBreakdown = [];
  List<DateTime> bookedDates = []; // Store all booked dates for this car

  @override
  void initState() {
    super.initState();
    _fetchCustomerDetails();
    _fetchBookedDates(); // Fetch booked dates when the page initializes
  }

  Future<void> _fetchCustomerDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        customerName = userDoc.get('name');
        customerEmail = userDoc.get('email');
        customerPhone = userDoc.get('phone');
      });
    }
  }

  Future<void> _fetchBookedDates() async {
    // Fetch bookings for this car and calculate booked date ranges
    final bookingQuery = await FirebaseFirestore.instance
        .collection('bookings')
        .where('carName', isEqualTo: widget.carName)
        .get();

    List<DateTime> dates = [];
    for (var doc in bookingQuery.docs) {
      DateTime startDate = (doc['pickupDate'] as Timestamp).toDate();
      DateTime endDate = (doc['returnDate'] as Timestamp).toDate();

      // Include each day in the range from startDate to endDate
      for (DateTime date = startDate;
          date.isBefore(endDate.add(const Duration(days: 1)));
          date = date.add(const Duration(days: 1))) {
        dates.add(date);
      }
    }

    setState(() {
      bookedDates = dates;
      print(bookedDates);
    });
  }

  bool _isDateBooked(DateTime date) {
    // Checks if a date is in the bookedDates list by comparing only the date part
    return bookedDates.any((bookedDate) =>
        bookedDate.year == date.year &&
        bookedDate.month == date.month &&
        bookedDate.day == date.day);
  }

  Future<void> _selectPickupDate() async {
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Pickup Date and Time',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),
                SizedBox(
                  height: 330,
                  width: 300,
                  child: SingleChildScrollView(
                    // Added scroll view
                    child: TableCalendar(
                      firstDay: DateTime.now(),
                      lastDay: DateTime(2100),
                      focusedDay: _pickupDate ?? DateTime.now(),
                      selectedDayPredicate: (day) =>
                          _pickupDate?.day == day.day,
                      onDaySelected: (selectedDay, focusedDay) async {
                        if (!_isDateBooked(selectedDay)) {
                          final now = DateTime.now();
                          TimeOfDay initialTime;

                          // Set initial time to now if selected day is today, else default to 8:00 AM
                          if (selectedDay.year == now.year &&
                              selectedDay.month == now.month &&
                              selectedDay.day == now.day) {
                            initialTime = TimeOfDay(
                                hour: now.hour,
                                minute: (now.minute / 30).ceil() * 30);
                          } else {
                            initialTime = const TimeOfDay(hour: 8, minute: 0);
                          }

                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: initialTime,
                            builder: (context, child) {
                              return MediaQuery(
                                data: MediaQuery.of(context)
                                    .copyWith(alwaysUse24HourFormat: true),
                                child: child!,
                              );
                            },
                          );

                          if (pickedTime != null) {
                            // Prevent selecting a time before current time on the same day
                            if (selectedDay.year == now.year &&
                                selectedDay.month == now.month &&
                                selectedDay.day == now.day &&
                                (pickedTime.hour < now.hour ||
                                    (pickedTime.hour == now.hour &&
                                        pickedTime.minute < now.minute))) {
                              // Show an alert to inform the user
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Invalid Time'),
                                  content: const Text(
                                      'You cannot select a time in the past.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

                            setState(() {
                              _pickupDate = DateTime(
                                selectedDay.year,
                                selectedDay.month,
                                selectedDay.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                              _calculateTotalPrice();
                            });
                            Navigator.pop(context);
                          }
                        }
                      },
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleTextStyle: TextStyle(
                          fontSize: 16.0,
                        ),
                        titleCentered: true,
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          if (_isDateBooked(day)) {
                            return Container(
                              margin: const EdgeInsets.all(4.0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectReturnDate() async {
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Return Date and Time',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),
                SizedBox(
                  height: 330,
                  width: 300,
                  child: SingleChildScrollView(
                    // Added scroll view
                    child: TableCalendar(
                      firstDay: _pickupDate ?? DateTime.now(),
                      lastDay: DateTime(2100),
                      focusedDay:
                          _returnDate ?? (_pickupDate ?? DateTime.now()),
                      selectedDayPredicate: (day) =>
                          _returnDate?.day == day.day,
                      onDaySelected: (selectedDay, focusedDay) async {
                        if (!_isDateBooked(selectedDay)) {
                          final now = DateTime.now();
                          TimeOfDay initialTime;

                          // Set initial time to now if selected day is today, else default to 8:00 AM
                          if (selectedDay.year == now.year &&
                              selectedDay.month == now.month &&
                              selectedDay.day == now.day) {
                            initialTime = TimeOfDay(
                                hour: now.hour,
                                minute: (now.minute / 30).ceil() * 30);
                          } else {
                            initialTime = const TimeOfDay(hour: 8, minute: 0);
                          }

                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: initialTime,
                            builder: (context, child) {
                              return MediaQuery(
                                data: MediaQuery.of(context)
                                    .copyWith(alwaysUse24HourFormat: true),
                                child: child!,
                              );
                            },
                          );

                          if (pickedTime != null) {
                            // Prevent selecting a time before current time on the same day
                            if (selectedDay.year == now.year &&
                                selectedDay.month == now.month &&
                                selectedDay.day == now.day &&
                                (pickedTime.hour < now.hour ||
                                    (pickedTime.hour == now.hour &&
                                        pickedTime.minute < now.minute))) {
                              // Show an alert to inform the user
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Invalid Time'),
                                  content: const Text(
                                      'You cannot select a time in the past.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

                            setState(() {
                              _returnDate = DateTime(
                                selectedDay.year,
                                selectedDay.month,
                                selectedDay.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                              _calculateTotalPrice();
                            });
                            Navigator.pop(context);
                          }
                        }
                      },
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleTextStyle: TextStyle(
                          fontSize: 16.0,
                        ),
                        titleCentered: true,
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          if (_isDateBooked(day)) {
                            return Container(
                              margin: const EdgeInsets.all(4.0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _calculateTotalPrice() {
    priceBreakdown.clear();
    if (_pickupDate != null && _returnDate != null) {
      final duration = _returnDate!.difference(_pickupDate!);
      final totalHours = duration.inHours;
      final totalDays = duration.inDays;
      double total = 0.0;

      if (totalDays > 0) {
        total += widget.pricePerDay * totalDays;
        priceBreakdown.add({
          'description':
              '$totalDays Day(s) at RM${widget.pricePerDay.toStringAsFixed(2)} each',
          'amount': widget.pricePerDay * totalDays,
        });
      }

      final remainingHours = totalHours % 24;

      if (remainingHours > 0) {
        if (remainingHours <= 1) {
          total += widget.pricePerHour['1']!;
          priceBreakdown.add({
            'description': '1 Hour',
            'amount': widget.pricePerHour['1'],
          });
        } else if (remainingHours <= 3) {
          total += widget.pricePerHour['3']!;
          priceBreakdown.add({
            'description': 'Up to 3 Hours',
            'amount': widget.pricePerHour['3'],
          });
        } else if (remainingHours <= 5) {
          total += widget.pricePerHour['5']!;
          priceBreakdown.add({
            'description': 'Up to 5 Hours',
            'amount': widget.pricePerHour['5'],
          });
        } else if (remainingHours <= 7) {
          total += widget.pricePerHour['7']!;
          priceBreakdown.add({
            'description': 'Up to 7 Hours',
            'amount': widget.pricePerHour['7'],
          });
        } else if (remainingHours <= 9) {
          total += widget.pricePerHour['9']!;
          priceBreakdown.add({
            'description': 'Up to 9 Hours',
            'amount': widget.pricePerHour['9'],
          });
        } else if (remainingHours <= 12) {
          total += widget.pricePerHour['12']!;
          priceBreakdown.add({
            'description': 'Up to 12 Hours',
            'amount': widget.pricePerHour['12'],
          });
        } else {
          total += widget.pricePerHour['24']!;
          priceBreakdown.add({
            'description': 'Up to 24 Hours',
            'amount': widget.pricePerHour['24'],
          });
        }
      }

      final pickupHour = _pickupDate!.hour;
      final returnHour = _returnDate!.hour;

      // Calculate outside office hours fee
      if ((pickupHour < 9 || pickupHour >= 17) &&
          (returnHour < 9 || returnHour >= 17)) {
        total += 20.0;
        officehour = 20.0;
        priceBreakdown.add({
          'description':
              'Outside Office Hours Fee (Both pickup and return time)',
          'amount': 20.0,
        });
      } else if ((pickupHour < 9 || pickupHour >= 17) ||
          (returnHour < 9 || returnHour >= 17)) {
        total += 10.0;
        officehour = 10.0;
        priceBreakdown.add({
          'description':
              'Outside Office Hours Fee (Either pickup and return time)',
          'amount': 10.0,
        });
      }

      // Custom location fee
      if ((_pickupLocation == 'Others' &&
              _pickupLocationController.text.isNotEmpty) &&
          (_returnLocation == 'Others' &&
              _returnLocationController.text.isNotEmpty)) {
        total += 10.0;
        customLocation = 10.0;
        priceBreakdown.add({
          'description':
              'Custom Location Fee (Both pickup and return location)',
          'amount': 10.0,
        });
      } else if ((_pickupLocation == 'Others' &&
              _pickupLocationController.text.isNotEmpty) ||
          (_returnLocation == 'Others' &&
              _returnLocationController.text.isNotEmpty)) {
        total += 5.0;
        customLocation = 5.0;
        priceBreakdown.add({
          'description':
              'Custom Location Fee (Either pickup or return location)',
          'amount': 5.0,
        });
      } else {
        customLocation = 0.0; // Reset if no custom location is selected
      }

      setState(() {
        totalPrice = total;
      });
    }
  }

  Future<void> _confirmBooking() async {
    if (_pickupDate == null || _returnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select both pickup and return dates.')),
      );
      return;
    }

    // Check if the selected dates overlap with any existing bookings
    bool isAvailable = await _checkDateAvailability(_pickupDate!, _returnDate!);
    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('This car is already booked for the selected dates.')),
      );
      return;
    }

    // Check if "Others" is selected for pickup and if the input is empty
    if (_pickupLocation == 'Others' && _pickupLocationController.text.isEmpty) {
      _showAlertDialog('Please fill in the custom pickup location.');
      return;
    }
    if (_returnLocation == 'Others' && _returnLocationController.text.isEmpty) {
      _showAlertDialog('Please fill in the custom return location.');
      return;
    }

    _calculateTotalPrice();

    _customPickupLocation = _pickupLocationController.text.trim();
    _customReturnLocation = _returnLocationController.text.trim();

    // Navigate to the Agreement & Confirmation Page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgreementConfirmationPage(
          carName: widget.carName, // Ensure all these values are non-null
          carType: widget.carType,
          gearType: widget.gearType,
          seats: widget.seats,
          pickupDate: _pickupDate!,
          returnDate: _returnDate!,
          customerName: customerName ?? '',
          customerEmail: customerEmail ?? '',
          customerPhone: customerPhone ?? '',
          pickupLocation: _pickupLocation == 'Others'
              ? _customPickupLocation ?? ''
              : _pickupLocation ?? '',
          returnLocation: _returnLocation == 'Others'
              ? _customReturnLocation ?? ''
              : _returnLocation ?? '',
          customPickupLocation: _customPickupLocation ?? '',
          customReturnLocation: _customReturnLocation ?? '',
          totalPrice: totalPrice,
          priceBreakdown: priceBreakdown,
        ),
      ),
    );
  }

  void _showAlertDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Input Required'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> _checkDateAvailability(
      DateTime pickupDate, DateTime returnDate) async {
    // Query Firestore for any existing bookings of this car that overlap with the selected dates
    final bookingQuery = await FirebaseFirestore.instance
        .collection('bookings')
        .where('carName', isEqualTo: widget.carName)
        .where('pickupDate', isLessThanOrEqualTo: returnDate)
        .where('returnDate', isGreaterThanOrEqualTo: pickupDate)
        .get();

    // If any bookings are found, there is an overlap
    return bookingQuery.docs.isEmpty;
  }

  Widget _buildHourlyPricingInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hourly Pricing:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (var entry
              in widget.pricePerHour.entries.toList()
                ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key))))
            Text(
              '<= ${entry.key} hour(s): RM${entry.value.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Display the car image
            Image.network(widget.imageUrl, height: 200, fit: BoxFit.cover),
            const SizedBox(height: 16),

            // Display car details
            Text('Car Name: ${widget.carName}',
                style: const TextStyle(fontSize: 24)),
            Text('Car Type: ${widget.carType}'),
            Text('Gear Type: ${widget.gearType}'),
            Text('Seats: ${widget.seats}'),
            //const SizedBox(height: 16),

            // Price details
            //Text('Price Per Day: RM${widget.pricePerDay.toStringAsFixed(2)}'),
            //const SizedBox(height: 20),
            _buildHourlyPricingInfo(), // Method to build hourly pricing info

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Pickup Location'),
              value: _pickupLocation,
              onChanged: (String? newValue) {
                setState(() {
                  _pickupLocation = newValue;
                  _pickupLocationController
                      .clear(); // Clear custom pickup location text if dropdown changes
                });
              },
              items: <String>['Student Mall', 'Others']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),

// If "Others" is selected for Pickup Location, show custom input field
            if (_pickupLocation == 'Others')
              TextField(
                controller: _pickupLocationController,
                decoration: const InputDecoration(
                    labelText: 'Enter Custom Pickup Location'),
                onChanged: (String value) {
                  setState(() {}); // Rebuild to capture changes
                },
              ),

// Similar setup for Return Location
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Return Location'),
              value: _returnLocation,
              onChanged: (String? newValue) {
                setState(() {
                  _returnLocation = newValue;
                  _returnLocationController
                      .clear(); // Clear custom return location text if dropdown changes
                });
              },
              items: <String>['Student Mall', 'Others']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),

// If "Others" is selected for Return Location, show custom input field
            if (_returnLocation == 'Others')
              TextField(
                controller: _returnLocationController,
                decoration: const InputDecoration(
                    labelText: 'Enter Custom Return Location'),
                onChanged: (String value) {
                  setState(() {}); // Rebuild to capture changes
                },
              ),
            const SizedBox(height: 16),

            // Button to select pickup date & time
            ElevatedButton(
              onPressed: _selectPickupDate,
              child: const Text('Select Pickup Date & Time'),
            ),
            const SizedBox(height: 16),
            if (_pickupDate != null)
              Text(
                  'Pickup Date & Time: ${DateFormat.yMMMd().add_jm().format(_pickupDate!)}'),
            const SizedBox(height: 16),

            // Button to select return date & time
            ElevatedButton(
              onPressed: _selectReturnDate,
              child: const Text('Select Return Date & Time'),
            ),
            const SizedBox(height: 16),
            if (_returnDate != null)
              Text(
                  'Return Date & Time: ${DateFormat.yMMMd().add_jm().format(_returnDate!)}'),
            const SizedBox(height: 20),

            // Calculate and display duration if both dates are selected
            if (_pickupDate != null && _returnDate != null)
              Text(
                'Duration: ${_returnDate!.difference(_pickupDate!).inHours} hour(s)',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 20),

            // Conditional pricing information
            if (totalPrice > 0) ...[
              if (officehour == 20)
                const Text(
                    'RM20 fee added for both pickup and return outside of office hours (9 a.m. - 5 p.m.).',
                    style: TextStyle(color: Colors.red))
              else if (officehour == 10)
                const Text(
                    'RM10 fee added either for pickup or return outside of office hours (9 a.m. - 5 p.m.).',
                    style: TextStyle(color: Colors.red)),
              if (customLocation == 5)
                const Text(
                    'RM5 fee added for either pickup or return location not in Student Mall.',
                    style: TextStyle(color: Colors.red))
              else if (customLocation == 10)
                const Text(
                    'RM10 fee added for both pickup and return location not in Student Mall.',
                    style: TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),

            // Display total price
            Text('Total Price: RM${totalPrice.toStringAsFixed(2)}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Button to confirm booking
            ElevatedButton(
              onPressed: _confirmBooking,
              child: const Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
