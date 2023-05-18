import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:parq_app/functions/delete_functions.dart';
import 'package:parq_app/functions/get_functions.dart';
import '../models/car_model.dart';
import '../models/parking_model.dart';
import '../models/ticket_model.dart';
import '../models/user_model.dart';

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
    DateTime timeData = ticket.time.toDate();
    String ticketTime =
        "${timeData.hour}:${timeData.minute.toString().padLeft(2, '0')} ${timeData.day}/${timeData.month}";
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(ticketTime),
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

  Future<void> rateUser(String userId, int rating) async {
    User user = await getUserWithId(userId);

    final numRatings = user.numRatings;
    final totalRating = user.totalRating;
    final newNumRatings = numRatings + 1;
    final newTotalRating = totalRating + rating;
    final newAvgRating = newTotalRating / newNumRatings;
    // TODO: Implement rating logic, e.g. save rating to database
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isEqualTo: userId)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final docId = snapshot.docs.first.id;

        await FirebaseFirestore.instance.collection('users').doc(docId).update({
          'numRatings': newNumRatings,
          'totalRating': newTotalRating,
          'avgRating': newAvgRating
        });
        setState(() {
          _getValues();
          log('numRatings: ${user.numRatings}');
          log('avgRating: ${user.avgRating}');
          log('totalRating: ${user.totalRating}');
        });
      } else {
        log('User not found in database.');
      }
    } catch (e) {
      log('Failed to update rating: $e');
    }
  }

  //Rate-Popup
  Future<void> showRatePopup(BuildContext context, Ticket ticket) async {
    final ratingController = TextEditingController();

    User user = await getUserWithId(ticket.previousUserIs);

    // Use a new context from the parent widget
    BuildContext dialogContext;
    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      builder: (BuildContext context) {
        dialogContext = context;
        return AlertDialog(
          title: const Text('Rate'),
          content: SizedBox(
            height: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Parked user: ${user.username}'),
                const Text('Rate this user on a scale of 1/5:'),
                TextFormField(
                  controller: ratingController,
                  decoration: const InputDecoration(labelText: 'Rating'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter a rating.';
                    }
                    if (value != '1' &&
                        value != '2' &&
                        value != '3' &&
                        value != '4' &&
                        value != '5') {
                      return 'Please enter a valid rating';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Rate'),
              onPressed: () async {
                String ratingStr = ratingController.text;
                int rating = int.parse(ratingStr);
                log(user.id);
                await rateUser(user.id, rating);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Card(
                        child: SizedBox(
                          height: 150,
                          width: 400,
                          child: Row(
                            children: [
                              Expanded(
                                child: FutureBuilder<Widget>(
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
                                  ),
                                  if (ticket.previousUserIs != widget.userId)
                                    SizedBox(
                                      width: 100,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          await showRatePopup(context, ticket);
                                        },
                                        child: const Text(
                                          'Rate user',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(
                                width: 60,
                              )
                            ],
                          ),
                        ),
                      ),
                      if (index < tickets.length - 1)
                        const Divider(thickness: 2)
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
