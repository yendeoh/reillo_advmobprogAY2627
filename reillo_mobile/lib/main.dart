// packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

// screens
import 'screens/home_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/settings_screen.dart';

// providers
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((
    _,
  ) async {
    await dotenv.load(fileName: 'assets/.env');
    runApp(const ReilloAdvMobProg());
  });
}

class ReilloAdvMobProg extends StatelessWidget {
  const ReilloAdvMobProg({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: ScreenUtilInit(
        designSize: const Size(412, 715),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (build, child) {
          final themeModel = build.watch<ThemeProvider>();
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeModel.lightTheme,
            darkTheme: themeModel.darkTheme,
            themeMode: themeModel.isDark ? ThemeMode.dark : ThemeMode.light,
            title: 'E-Commerce App',
            home: const MainShell(),
            routes: {
              '/home': (context) => const HomeScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CartScreen(userId: 1),
    SettingsScreen(),
  ];

  static const int _cartIndex = 1;

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final bool onCartScreen = _currentIndex == _cartIndex;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: onCartScreen
          ? null
          : FloatingActionButton(
              onPressed: () {
                final next = (_currentIndex + 1) % _screens.length;
                _onNavTap(next);
              },
              child: const Icon(Icons.chat),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                Icons.storefront,
                color: _currentIndex == 0 ? Colors.indigo : Colors.grey,
              ),
              onPressed: () => _onNavTap(0),
            ),
            IconButton(
              icon: Icon(
                Icons.shopping_cart,
                color: onCartScreen ? Colors.indigo : Colors.grey,
              ),
              onPressed: () => _onNavTap(_cartIndex),
            ),
            IconButton(
              icon: Icon(
                Icons.person,
                color: _currentIndex == 2 ? Colors.indigo : Colors.grey,
              ),
              onPressed: () => _onNavTap(2),
            ),
          ],
        ),
      ),
    );
  }
}
