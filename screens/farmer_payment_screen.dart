import 'package:flutter/material.dart';

class PaymentsPage extends StatelessWidget {
  final List<Map<String, String>> payments = [
    {'month': 'April 2025', 'amount': '₹1200', 'status': 'Paid'},
    {'month': 'March 2025', 'amount': '₹1150', 'status': 'Paid'},
    {'month': 'February 2025', 'amount': '₹950', 'status': 'Pending'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children:
          payments.map((payment) {
            return Card(
              child: ListTile(
                leading: Icon(
                  Icons.currency_rupee,
                  color:
                      payment['status'] == 'Paid' ? Colors.green : Colors.red,
                ),
                title: Text(payment['month'] ?? ''),
                subtitle: Text('Amount: ${payment['amount']}'),
                trailing: Text(
                  payment['status'] ?? '',
                  style: TextStyle(
                    color:
                        payment['status'] == 'Paid' ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
