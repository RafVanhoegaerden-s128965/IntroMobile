import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:parq_app/functions/delete_functions.dart';
import 'package:parq_app/functions/get_functions.dart';
import '../models/car_model.dart';
import '../models/ticket_model.dart';

class TicketPage extends StatefulWidget {
  final String? userId;
  const TicketPage({super.key, this.userId});

  @override
  State<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> {
  List<Ticket> _tickets = [];
  List<Ticket> _activeTickets = [];

  bool active = true;

  void _getValues() async {
    List<Ticket> activeTickets =
        await getAllActiveTicketsOfUser(widget.userId.toString());
    List<Ticket> allTickets =
        await getAllTicketsOfUser(widget.userId.toString());
    List<Ticket> notActiveTickets = [];

    for (var t in allTickets) {
      if (t.active == 'false') {
        notActiveTickets.add(t);
      }
    }

    setState(() {
      _activeTickets = activeTickets;
      _tickets = notActiveTickets;
      log("Tickets on ticket page: ${active ? _activeTickets.length : _tickets.length}");
    });
  }

  void updateState() {
    setState(() {
      _getValues();
    });
  }

  //Delete ticket
  void _deleteTicket(Ticket ticket) async {
    deleteTicket(ticket, updateState);
  }

  Future<Widget> buildTicketInfoWidget(Ticket ticket) async {
    Car car = await getCarWithId(ticket.carId);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(ticket.time.toDate().toString()),
        Text(ticket.street),
        Text('${car.brand} ${car.type}'),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _getValues();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tickets',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        active = true;
                        _getValues();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: active ? Colors.blue : Colors.grey,
                    ),
                    child: const Text('Active Tickets'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        active = false;
                        _getValues();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: active ? Colors.grey : Colors.blue,
                    ),
                    child: const Text('History'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount:
                    active == false ? _tickets.length : _activeTickets.length,
                itemBuilder: (BuildContext context, int index) {
                  List<Ticket> tickets = active ? _activeTickets : _tickets;
                  final ticket = tickets[index];
                  return Column(
                    children: [
                      Card(
                        child: SizedBox(
                          height: 150,
                          width: 400,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              FutureBuilder<Widget>(
                                future: buildTicketInfoWidget(ticket),
                                builder: (BuildContext context,
                                    AsyncSnapshot<Widget> snapshot) {
                                  if (snapshot.hasData) {
                                    return snapshot.data!;
                                  } else {
                                    return const CircularProgressIndicator();
                                  }
                                },
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      _deleteTicket(ticket);
                                    },
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                      if (index < _tickets.length - 1)
                        const Divider(thickness: 2)
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          //;
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
