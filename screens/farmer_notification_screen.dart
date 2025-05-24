import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  final List<String> notifications = [
    'Milk collection will start at 7 AM tomorrow.',
    'Payment for March has been credited.',
    'Bonus payment for festival will be included in April.',
    'Milk quality improved, fat increased to 4.5%.',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        return Card(
          color: Colors.orange.shade50,
          child: ListTile(
            leading: const Icon(
              Icons.notification_important,
              color: Colors.orange,
            ),
            title: Text(notifications[index]),
          ),
        );
      },
    );
  }
}