import 'package:flutter/material.dart';
// Make sure these imports match your actual file locations
import './home_screen.dart';
import './stats_screen.dart';
import './accounts_screen.dart';
import './settings_screen.dart';
import './new_expense_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  int _previousIndex = 0;

  // List of pages to navigate between
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

  // Create a route for the add transaction screen with container transform
  Route _createAddTransactionRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const NewExpenseScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const beginOffset = Offset(0.0, 1.0);
        const endOffset = Offset.zero;
        const curve = Curves.easeInOut;

        var offsetAnimation = Tween(begin: beginOffset, end: endOffset)
            .chain(CurveTween(curve: curve))
            .animate(animation);

        // Also add a fade effect
        var fadeAnimation = Tween(begin: 0.0, end: 1.0)
            .animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
        ));

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use AnimatedSwitcher with custom transition
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          // Determine slide direction based on index change
          bool slideFromRight = _selectedIndex > _previousIndex;

          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(slideFromRight ? 1.0 : -1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          // Use await to properly handle the return value
          final result = await Navigator.of(context).push(_createAddTransactionRoute());
          // Check if we need to refresh
          if (result == true) {
            setState(() {
              // Refresh if needed
            });
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}