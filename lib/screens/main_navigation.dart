import 'package:animations/animations.dart'; // Add this import
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'stats_screen.dart';
import 'accounts_screen.dart';
import 'settings_screen.dart';
import 'new_expense_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  int _previousIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    StatsScreen(),
    AccountsScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
    });
  }

  // ✅ Keep this transition builder for page switching
  Widget _buildTransition(Widget child, Animation<double> animation) {
    bool slideFromRight = _selectedIndex > _previousIndex;

    const curve = Curves.easeInOut;
    final begin = slideFromRight ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
    final end = Offset.zero;

    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    final offsetAnimation = animation.drive(tween);

    return SlideTransition(position: offsetAnimation, child: child);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: _buildTransition,
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Accounts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      // Only show FAB when not on the Accounts screen
      floatingActionButton: _selectedIndex != 2 ? _buildFAB() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // New method to build the FAB with container transform
  Widget _buildFAB() {
    return OpenContainer(
      transitionType: ContainerTransitionType.fade, // Use fade type from the animations package
      transitionDuration: const Duration(milliseconds: 500),
      closedElevation: 6.0,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(28.0)),
      ),
      closedColor: Colors.deepPurple,
      closedBuilder: (context, openContainer) {
        return SizedBox(
          height: 56.0,
          width: 56.0,
          child: Center(
            child: Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
        );
      },
      openBuilder: (context, _) {
        return const NewExpenseScreen();
      },
      onClosed: (value) {
        if (value == true) {
          setState(() {
            // Optionally refresh here if needed
          });
        }
      },
    );
  }
}