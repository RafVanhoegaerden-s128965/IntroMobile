import 'package:flutter/material.dart';

class TicketPage extends StatefulWidget {
  final String? userId;
  const TicketPage({super.key, this.userId});

  @override
  State<TicketPage> createState() => _TicketPageState();
}

//TODO: user kan active tickets bekijken en erop klikken om die vrij te geven, List met active tickets is al aangemaakt
//TODO: user kan zijn geschiedenis bekijken door te controleren bij de field "active" == "false"
class _TicketPageState extends State<TicketPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tickets',
        ),
      ),
      body: const Text("Tickets"),
    );
  }
}
