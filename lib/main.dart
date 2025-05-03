import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Providers/location_provider.dart';
import 'Providers/post_provider.dart';
import 'Screens/home_screen.dart';
import 'Screens/daily_screen.dart';
import 'Screens/community_screen.dart';
import 'Screens/radar_screen.dart';
import 'Widgets/navbar_widget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:weather_app/firebase_options.dart';

// Main entry point - initializes Firebase and state providers
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// Root widget that configures the MaterialApp
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

// Main scaffold with bottom navigation
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// Manages screen navigation state
class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const DailyScreen(),
    const CommunityScreen(),
    const RadarScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}