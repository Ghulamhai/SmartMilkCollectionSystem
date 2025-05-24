// import 'package:flutter/material.dart';
// import '../widgets/login_form.dart';

// class SignInPage extends StatelessWidget {
//   const SignInPage({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final isSmallScreen = MediaQuery.of(context).size.width < 600;

//     return Scaffold(
//       backgroundColor: const Color(0xFFF3F5F7),
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const _Logo(),
//               const SizedBox(height: 16),
//               Container(
//                 constraints: const BoxConstraints(maxWidth: 380),
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: const [
//                     BoxShadow(
//                       color: Colors.black12,
//                       blurRadius: 10,
//                       offset: Offset(0, 4),
//                     )
//                   ],
//                 ),
//                 child: const LoginForm(),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _Logo extends StatelessWidget {
//   const _Logo({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Image.asset(
//       'assets/app_icon.png',
//        width: 80,
//        height: 80,
//       ),
//         SizedBox(height: 12),
//         Text(
//           'Welcome Back 👋',
//           style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//         ),
//         Text(
//           'Login to begin your day',
//           style: TextStyle(color: Colors.grey),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../widgets/login_form.dart';
import 'dart:ui';

class SignInPage extends StatelessWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green.shade50, Colors.green.shade100],
              ),
            ),
          ),

          // Decorative circles
          Positioned(
            top: -size.height * 0.1,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.6,
              height: size.width * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.05,
            left: -size.width * 0.1,
            child: Container(
              width: size.width * 0.4,
              height: size.width * 0.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.1),
              ),
            ),
          ),

          // Main content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo and welcome text
                  const _EnhancedLogo(),
                  const SizedBox(height: 32),

                  // Login form card
                  Container(
                    constraints: const BoxConstraints(maxWidth: 380),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please enter your credentials to continue',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const LoginForm(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Footer
                  const SizedBox(height: 24),
                  Text(
                    '© ${DateTime.now().year} Milk Distribution App',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnhancedLogo extends StatelessWidget {
  const _EnhancedLogo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo with glowing effect
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Image.asset('assets/app_icon.png', width: 80, height: 80),
        ),
        const SizedBox(height: 24),
        // Welcome text with emoji
        const Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 8),
        // Subtitle with slightly larger text
        Text(
          'Login to begin your day',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
