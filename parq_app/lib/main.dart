import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:parq_app/views/login_view.dart';
import 'package:parq_app/views/map_view.dart';
import 'package:parq_app/views/register_view.dart';
import 'package:parq_app/views/settings_view.dart';
import 'package:parq_app/views/ticket_view.dart';
import 'constants/routes.dart';
import 'constants/icons.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginView(),
      routes: {
        loginRoute: (context) => const LoginView(),
        registerRoute: (context) => const RegisterView(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  final String userId;
  const HomePage({required Key key, required this.userId}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //BottomNavBar Routing list + Index
  int _currentIndex = 1;
  List<Widget> _routingOptions = [];

  @override
  void initState() {
    super.initState();

    //BottomNavBar set routing list
    _routingOptions = [
      TicketPage(
        userId: widget.userId,
        alreadyRated: false,
      ),
      MapPage(userId: widget.userId),
      SettingsPage(userId: widget.userId),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _routingOptions.elementAt(_currentIndex),
      //Navigation Bar at the bottom
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.white,
        items: [
          //Icon ticket
          BottomNavigationBarItem(
            icon: ticketIcon,
            label: 'Ticket',
          ),
          //Icon map
          BottomNavigationBarItem(
            icon: mapIcon,
            label: 'Map',
          ),
          //Icon settings
          BottomNavigationBarItem(
            icon: settingsIcon,
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
