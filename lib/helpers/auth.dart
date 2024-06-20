// import 'package:local_auth/local_auth.dart';
// import 'package:flutter/services.dart';

// class AuthService {
//   final LocalAuthentication _localAuthentication = LocalAuthentication();

//   Future<bool> authenticate() async {
//     bool isAuthenticated = false;
//     try {
//       isAuthenticated = await _localAuthentication.authenticate(
//         localizedReason: 'Please authenticate to access',
//       );
//     } on PlatformException catch (e) {
//       print(e);
//     }
//     return isAuthenticated;
//   }
// }
