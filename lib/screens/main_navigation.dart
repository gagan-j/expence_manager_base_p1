import 'package:flutter/material.dart';
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

  // ✅ Fixed: this now matches AnimatedSwitcherTransitionBuilder type
  Widget _buildTransition(Widget child, Animation<double> animation) {
    bool slideFromRight = _selectedIndex > _previousIndex;

    const curve = Curves.easeInOut;
    final begin = slideFromRight ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
    final end = Offset.zero;

    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    final offsetAnimation = animation.drive(tween);

    return SlideTransition(position: offsetAnimation, child: child);
  }

  Route _createAddTransactionRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const NewExpenseScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const beginOffset = Offset(0.0, 1.0);
        const endOffset = Offset.zero;
        const curve = Curves.easeInOut;

        final offsetAnimation = Tween(begin: beginOffset, end: endOffset)
            .chain(CurveTween(curve: curve))
            .animate(animation);

        final fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
          ),
        );

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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.of(context).push(_createAddTransactionRoute()).then((value) {
            if (value == true) {
              setState(() {
                // Optionally refresh here
              });
            }
          });
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
