import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_firebase/models/user.dart';
import 'package:test_firebase/riverpod/index.dart';
import 'package:test_firebase/screens/home4.dart';
import 'package:test_firebase/screens/profile.dart';
import 'package:test_firebase/screens/search.dart';
import 'package:test_firebase/screens/search2.dart';

class BottomScreen extends ConsumerWidget {
  const BottomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    return auth.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('User not logged in'));
        }
        return BottomTabs(user: user);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Error: $error')),
    );
  }
}

class BottomTabs extends StatefulWidget {
  final AppUser user;
  // 3. Properly require the user in the constructor
  const BottomTabs({super.key, required this.user});

  @override
  State<BottomTabs> createState() => _BottomTabsState();
}

class _BottomTabsState extends State<BottomTabs> {
  int currentPageIndex = 0;
  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen4(user: widget.user), // Accessing user from the widget above
      // PhoneSearchBottomSheet(),
      GlobalSearchScreen(),
      ProfileScreen(user: widget.user),
    ];

    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentPageIndex,
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        // indicatorColor: const Color.fromARGB(255, 98, 241, 103),
        indicatorColor: Color.fromARGB(255, 255, 255, 255),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        shadowColor: Theme.of(context).colorScheme.onPrimary,

        // labelTextStyle: WidgetStateProperty.all<TextStyle?>(
        //   const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
        // ),
        destinations: <Widget>[
          NavigationDestination(
            selectedIcon: Icon(
              Icons.chat_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            icon: Icon(Icons.chat_rounded),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.search_sharp,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: 'Search',
          ),
          NavigationDestination(
            selectedIcon: Icon(
              Icons.school,
              color: Theme.of(context).colorScheme.primary,
            ),
            icon: Icon(Icons.school_outlined),
            label: 'Profile',
          ),
        ],
      ),
      body: pages[currentPageIndex],
    );
  }
}
