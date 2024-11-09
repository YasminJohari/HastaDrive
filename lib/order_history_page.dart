import 'package:flutter/material.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Text(
            'Your Orders',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          // Sample order item
          OrderItem(
            orderId: '001',
            carName: 'Perodua Axia',
            date: '2024-10-01',
            status: 'Completed',
          ),
          Divider(),
          OrderItem(
            orderId: '002',
            carName: 'Toyota Prius',
            date: '2024-09-15',
            status: 'Cancelled',
          ),
          Divider(),
          OrderItem(
            orderId: '003',
            carName: 'BMW X5',
            date: '2024-08-30',
            status: 'Completed',
          ),
        ],
      ),
    );
  }
}

class OrderItem extends StatelessWidget {
  final String orderId;
  final String carName;
  final String date;
  final String status;

  const OrderItem({
    super.key,
    required this.orderId,
    required this.carName,
    required this.date,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(carName),
      subtitle: Text('Order ID: $orderId\nDate: $date\nStatus: $status'),
      isThreeLine: true,
      trailing: const Icon(Icons.arrow_forward),
      onTap: () {
        // Handle tap to show order details if needed
      },
    );
  }
}
