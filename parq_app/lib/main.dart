import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:parq_app/views/login_view.dart';
import 'package:parq_app/views/map_view.dart';
import 'package:parq_app/views/register_view.dart';
import 'package:parq_app/views/settings_view.dart';
import 'package:parq_app/views/ticket_view.dart';

import 'constants/routes.dart';

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
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //Routing list + Index
  int _currentIndex = 1;
  static const List<Widget> _routingOptions = [
    TicketPage(),
    MapPage(), //HomePage
    SettingsPage()
  ];
  //Icons
  final _ticketIcon = Image.asset(
    'assets/images/Ticket.png',
    width: 45,
    height: 45,
  );
  final _mapIcon = Image.asset(
    'assets/images/Map.png',
    width: 45,
    height: 45,
  );
  final _settingsIcon = Image.asset(
    'assets/images/Settings.png',
    width: 45,
    height: 45,
  );

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
            icon: _ticketIcon,
            label: 'Ticket',
          ),
          //Icon map
          BottomNavigationBarItem(
            icon: _mapIcon,
            label: 'Map',
          ),
          //Icon settings
          BottomNavigationBarItem(
            icon: _settingsIcon,
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
