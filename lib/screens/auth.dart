// import 'package:flutter/material.dart';
// import 'package:mongo_mate/helpers/auth.dart';
// import 'package:mongo_mate/screens/home.dart';

// class AuthScreen extends StatelessWidget {
//   final AuthService _authService = AuthService();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('MonMate'),
//       ),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () async {
//             bool isAuthenticated = await _authService.authenticate();
//             if (isAuthenticated) {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (context) => const HomePage()),
//               );
//             } else {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text('Failed to authenticate!')),
//               );
//             }
//           },
//           child: Text('Authenticate with Face ID'),
//         ),
//       ),
//     );
//   }
// }
