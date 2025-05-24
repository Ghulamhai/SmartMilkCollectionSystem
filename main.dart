import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import './screens/home_screen_farmer.dart';
import './screens/login_screen.dart';
import './screens/home_screen_distributor.dart';
import './screens/distributor_main_screen.dart';
// import './screens/distributor_route_screen.dart';
import './services/auth_service.dart';
import 'firebase_options.dart';
import './models/user_model.dart';
import 'helpers/distributor_route_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Login Demo',
      theme: ThemeData(primarySwatch: Colors.green),
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: AuthWrapper(),
      //home: const RouteScreen(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;
          if (user == null) {
            return SignInPage(); // Show login if not authenticated
          }
          return FutureBuilder<UserModel?>(
            future: AuthService().getUserData(user.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.done) {
                if (userSnapshot.hasData && userSnapshot.data != null) {
                  final userData = userSnapshot.data!;
                  final target =
                      userData.userType == 'Farmer'
                          ? HomeScreenFarmer()
                          : HomeScreenDistributor(); // Or DistributorMainScreen

                  return target;
                } else {
                  print("User data not found or incomplete");
                  return Center(child: Text("Error loading user data"));
                }
              }
              return Center(
                child: CircularProgressIndicator(),
              ); // Loading state
            },
          );
        }
        return Center(child: CircularProgressIndicator()); // Loading state
      },
    );
  }
}
