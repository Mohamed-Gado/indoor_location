import 'package:flutter/material.dart';
import 'View/nearby_screen.dart';
import 'View/opening_screen.dart';

import 'models/app_state_model.dart';

class UmbrellaMain extends StatelessWidget {
  const UmbrellaMain({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Umbrella',
      home: BottomNav(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class BottomNav extends StatefulWidget {
  const BottomNav({Key? key}) : super(key: key);

  @override
  BottomNavState createState() {
    return BottomNavState();
  }
}

class BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;
  static final List<Widget> _widgetOptions = <Widget>[
    const OpeningScreen(),
    const NearbyScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();

    AppStateModel appStateModel = AppStateModel.instance;

    appStateModel.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.record_voice_over),
            label: 'Anchor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_walk),
            label: 'Mobile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        onTap: _onItemTapped,
      ),
    );
  }
}
