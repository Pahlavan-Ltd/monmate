import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mongo_mate/screens/intro.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mongo_mate/helpers/toast.dart';
import 'package:mongo_mate/screens/home.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mongo_mate/utilities/AdRepository.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: ToastHelper.scaffoldMessengerKey,
      home: const InitialScreen(),
      theme: ThemeData(
          brightness: Brightness.light,
          colorScheme: const ColorScheme.light(
              primary: Colors.deepOrange,
              secondary: Colors.deepOrangeAccent,
              onInverseSurface: Color.fromARGB(255, 242, 242, 242))),
      darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
              primary: Colors.orange,
              secondary: Colors.orangeAccent,
              onInverseSurface: Color.fromARGB(255, 27, 27, 27))),
      themeMode: ThemeMode.system,
    );
  }
}

class InitialScreen extends StatefulWidget {
  const InitialScreen({Key? key}) : super(key: key);

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  bool _isLoading = true;
  bool _isIntroSeen = false;

  @override
  void initState() {
    super.initState();
    _checkIntroStatus();
  }

  Future<void> _checkIntroStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool seen = prefs.getBool('intro_seen') ?? false;

    setState(() {
      _isIntroSeen = seen;
      _isLoading = false; // Loading complete
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading screen while checking the intro status
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Navigate to the appropriate page based on the intro status
    return _isIntroSeen ? const HomePage() : const IntroPage();
  }
}
