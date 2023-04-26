import 'package:flutter/material.dart';

class TicketPage extends StatelessWidget {
  final String? userId;
  const TicketPage({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tickets',
        ),
      ),
    );
  }
}
