import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:mongo_mate/utilities/AdRepository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mongo_mate/screens/home.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({Key? key}) : super(key: key);

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _currentPage = 0;
  // bool _isNameValid = false;
  // bool _nameSubmitted = false;
  bool _continued = false;
  bool _showPrivacyPage = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // void _submitName() {
  //   if (_nameController.text.trim().length >= 2) {
  //     setState(() {
  //       _nameSubmitted = true;
  //     });
  //     Future.delayed(const Duration(seconds: 2), () {
  //       setState(() {
  //         _showPrivacyPage = true;
  //       });
  //     });
  //   } else {
  //     setState(() {
  //       _isNameValid = false;
  //     });
  //   }
  // }

  void _continue() {
    setState(() {
      _continued = true;
    });
    setState(() {
      _showPrivacyPage = true;
    });
  }

  void _completeIntro() async {
    AdRepository.showConsentUMP();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_seen', true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  void _requestATT() async {
    if (await AppTrackingTransparency.trackingAuthorizationStatus ==
        TrackingStatus.notDetermined) {
      await Future.delayed(const Duration(milliseconds: 200));
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
    _completeIntro();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _showPrivacyPage
          ? SafeArea(child: _buildPrivacyPage())
          : _continued
              ? SafeArea(child: _buildWelcomeAnimation())
              : SafeArea(child: _buildOnboarding()),
    );
  }

  Widget _buildOnboarding() {
    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              _buildPage(
                image: Icons.storage_rounded,
                title: "Welcome to MonMate",
                description: "Manage MongoDB with MonMate!",
              ),
              _buildPage(
                image: Icons.cable_rounded,
                title: "Database Management",
                description:
                    "Create, edit, and delete connections, collections, and documents. Enjoy built-in editor, sorting, and filtering.",
              ),
              _buildPage(
                image: Icons.search_rounded,
                title: "Query Sorting and Filtering",
                description:
                    "Run your queries with precision. Sort and filter your data to quickly find exactly what you're looking for. MonMate's powerful querying capabilities make data retrieval efficient and effective.",
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.all(4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color:
                    _currentPage == index ? Colors.orangeAccent : Colors.grey,
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // TextField(
              //   controller: _nameController,
              //   onChanged: (value) {
              //     setState(() {
              //       _isNameValid = value.trim().length >= 2;
              //     });
              //   },
              //   decoration: InputDecoration(
              //     labelText: "Enter your name",
              //     border: OutlineInputBorder(),
              //   ),
              // ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _continue,
                child: const Text("Continue"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPage({
    required IconData image,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(image, size: 100, color: Colors.orangeAccent),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeAnimation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 100, color: Colors.green),
          const SizedBox(height: 24),
          Text(
            "Welcome, ${_nameController.text.trim()}!",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text("Let’s set up your privacy preferences."),
        ],
      ),
    );
  }

  Widget _buildPrivacyPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.privacy_tip,
                size: 100, color: Colors.orangeAccent),
            const SizedBox(height: 24),
            const Text(
              "Privacy Settings",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              "To keep this app free, we'd like your permission to track your activity for personalized ads.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _requestATT,
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}
