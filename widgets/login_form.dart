import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/home_screen_farmer.dart';
// import 'package:flutter_project/screens/home_screen_farmer.dart';
import '../screens/home_screen_distributor.dart';
import '../screens/registration_screen.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField(
            controller: emailController,
            label: 'Email',
            hint: 'Enter your email',
            icon: Icons.email_outlined,
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Please enter your email';
              final emailValid = RegExp(
                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
              ).hasMatch(value);
              return emailValid ? null : 'Please enter a valid email';
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: passwordController,
            label: 'Password',
            hint: 'Enter your password',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Please enter your password';
              return value.length < 6
                  ? 'Password must be at least 6 characters'
                  : null;
            },
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _rememberMe,
            onChanged: (value) => setState(() => _rememberMe = value ?? false),
            title: const Text('Remember me'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _handleLogin,
              child: const Text(
                'Login',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {}, // Add Google auth later if needed
              icon: const Icon(Icons.g_mobiledata),
              label: const Text(
                'Continue with Google',
                style: TextStyle(fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegistrationScreen(),
                  ),
                );
              },
              child: const Text(
                'New here? Create an account',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: isPassword && !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        prefixIcon: Icon(icon),
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed:
                      () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                )
                : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final email = emailController.text;
        final password = passwordController.text;

        print('Attempting to log in user: $email');

        // Sign in with Firebase
        UserCredential userCredential = await _authService
            .signInWithEmailAndPassword(email, password);
        User? user = userCredential.user;

        if (user != null) {
          print('Login successful! UID: ${user.uid}');

          // Fetch user data from Firestore
          UserModel? userData = await _authService.getUserData(user.uid);

          if (userData != null) {
            print('User data fetched from Firestore: ${userData.toJson()}');

            // Navigate based on userType
            final target =
                userData.userType == 'Farmer'
                    ? const HomeScreenFarmer()
                    : const HomeScreenDistributor();

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => target),
            );
          } else {
            print('User data is null!');
            _showSnackBar('No user data found in Firestore.');
          }
        } else {
          print('User object is null after login!');
          _showSnackBar('Login failed. Please try again.');
        }
      } catch (e) {
        print('login coming from login_form.dart');
        print('Login error: $e');
        _showSnackBar(e.toString());
      }
    }
  }

  // void _handleLogin() async {
  //   if (_formKey.currentState?.validate() ?? false) {
  //     try {
  //       final email = emailController.text;
  //       final password = passwordController.text;
  //
  //       print("Attempting to log in user: $email");
  //
  //       // Sign in with Firebase
  //       UserCredential userCredential = await _authService.signInWithEmailAndPassword(email, password);
  //       User? user = userCredential.user;
  //
  //       if (user != null) {
  //         print("Login successfully UID: ${user.uid}");
  //         // Fetch user data from Firestore
  //         UserModel? userData = await _authService.getUserData(user.uid);
  //
  //
  //         if(userData != null) {
  //           print("User data fetched from firestore: ${userData.toJson()}");
  //
  //           // Navigate based on userType
  //           final target = userData!.userType == 'Farmer'
  //             ? const HomeScreenFarmer()
  //             : const HomeScreenDistributor(); // Using DistributorMainScreen if needed
  //
  //           Navigator.pushReplacement(
  //             context,
  //             MaterialPageRoute(builder: (context) => target),
  //           );
  //         } else {
  //           print('User data is null');
  //           _showSnackBar('No user data found in firestore');
  //         }
  //       } else {
  //         print('User object is null after login !');
  //         _showSnackBar('Login failed. Please Try again');
  //
  //       } catch (e) {
  //         print('Login error: $e');
  //       _showSnackBar(e.toString());
  //     }
  //   }
  // }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
