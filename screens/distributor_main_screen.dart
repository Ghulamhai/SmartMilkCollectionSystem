import 'package:flutter/material.dart';
import './home_screen_distributor.dart';
import './distributor_route_screen.dart';
import './distributor_collections_screen.dart';


class DistributorMainScreen extends StatefulWidget {
  const DistributorMainScreen({Key? key}) : super(key: key);

  @override
  State<DistributorMainScreen> createState() => _DistributorMainScreenState();
}

class _DistributorMainScreenState extends State<DistributorMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreenDistributor(),
    // const DistributorMainScreen(),
    RouteScreen(),
    // const PlaceholderScreen(title: 'Route Overview Coming Soon'),
    const CollectionsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route),
            label: 'Route',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in),
            label: 'Collections',
          ),
        ],
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(title),
      ),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
