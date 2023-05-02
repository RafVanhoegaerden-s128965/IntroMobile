import 'package:flutter/material.dart';

class TicketPage extends StatefulWidget {
  final String? userId;
  const TicketPage({super.key, this.userId});

  @override
  State<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> {
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
