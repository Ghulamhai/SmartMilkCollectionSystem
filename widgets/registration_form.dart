// //Added this registration form on the 19 apritl

// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import '../screens/home_screen_farmer.dart';
// import '../screens/home_screen_distributor.dart';
// import '../services/auth_service.dart';
// import '../models/user_model.dart';

// class RegistrationForm extends StatefulWidget {
//   const RegistrationForm({Key? key}) : super(key: key);

//   @override
//   State<RegistrationForm> createState() => _RegistrationFormState();
// }

// class _RegistrationFormState extends State<RegistrationForm> {
//   final _formKey = GlobalKey<FormState>();
//   bool _isPasswordVisible = false;
//   bool _isGettingLocation = false;

//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _locationController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();

//   String _userType = 'Farmer';
//   double? _latitude;
//   double? _longitude;

//   final AuthService _authService = AuthService();

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _locationController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }

//   void _navigateToHomeScreen(BuildContext context) {
//     final target =
//         _userType == 'Farmer'
//             ? const HomeScreenFarmer()
//             : const HomeScreenDistributor();

//     Navigator.of(context).pushAndRemoveUntil(
//       MaterialPageRoute(builder: (context) => target),
//       (route) => false,
//     );
//   }

//   Future<void> _getLocation() async {
//     // setState(() => _isGettingLocation = true);

//     // bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     // if (!serviceEnabled) {
//     //   ScaffoldMessenger.of(context).showSnackBar(
//     //     const SnackBar(content: Text('Location services are disabled.')),
//     //   );
//     //   setState(() => _isGettingLocation = false);
//     //   return;
//     // }

//     // LocationPermission permission = await Geolocator.checkPermission();
//     // if (permission == LocationPermission.denied) {
//     //   permission = await Geolocator.requestPermission();
//     //   if (permission == LocationPermission.denied) {
//     //     ScaffoldMessenger.of(context).showSnackBar(
//     //       const SnackBar(content: Text('Location permission denied.')),
//     //     );
//     //     setState(() => _isGettingLocation = false);
//     //     return;
//     //   }
//     // }

//     // if (permission == LocationPermission.deniedForever) {
//     //   ScaffoldMessenger.of(context).showSnackBar(
//     //     const SnackBar(
//     //       content: Text('Location permission permanently denied.'),
//     //     ),
//     //   );
//     //   setState(() => _isGettingLocation = false);
//     //   return;
//     // }

//     setState(() => _isGettingLocation = true);

//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Location services are disabled.')),
//       );
//       setState(() => _isGettingLocation = false);
//       return;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Location permission denied.')),
//         );
//         setState(() => _isGettingLocation = false);
//         return;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Location permission permanently denied.'),
//         ),
//       );
//       setState(() => _isGettingLocation = false);
//       return;
//     }

//     try {
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );

//       _latitude = position.latitude;
//       _longitude = position.longitude;

//       // Reverse geocoding to get human-readable address
//       List<Placemark> placemarks = await placemarkFromCoordinates(_latitude!, _longitude!);

//       if (placemarks.isNotEmpty) {
//         Placemark place = placemarks[0];
//         // String fullAddress =
//         //     "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";

//         String fullAddress = [
//           place.name,
//           place.street,
//           place.subLocality,
//           place.locality,
//           place.subAdministrativeArea,
//           place.administrativeArea,
//           place.postalCode,
//           place.country,
//         ].where((element) => element != null && element.isNotEmpty).join(', ');

//         _locationController.text = fullAddress; // Show address in text field
//       } else {
//         _locationController.text = "${_latitude}, ${_longitude}"; // Fallback to lat/lon
//       }
//     } catch (e) {
//       print("⚠️ Error fetching location or address: $e");
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
//     } finally {
//       setState(() => _isGettingLocation = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       constraints: const BoxConstraints(maxWidth: 400),
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Form(
//         key: _formKey,
//         child: Column(
//           children: [
//             const Text(
//               'Create Your Account',
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),

//             _buildUserTypeSelector(),
//             const SizedBox(height: 16),

//             _buildTextField(
//               controller: _nameController,
//               label: 'Full Name',
//               icon: Icons.person_outline,
//               validator:
//                   (v) => v == null || v.isEmpty ? 'Enter your name' : null,
//             ),
//             const SizedBox(height: 16),
//             _buildTextField(
//               controller: _emailController,
//               label: 'Email',
//               icon: Icons.email_outlined,
//               keyboard: TextInputType.emailAddress,
//               validator: (value) {
//                 if (value == null || value.isEmpty) return 'Enter your email';
//                 final emailValid = RegExp(
//                   r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9]+\.[a-zA-Z]+$",
//                 ).hasMatch(value);
//                 return emailValid ? null : 'Enter a valid email';
//               },
//             ),
//             const SizedBox(height: 16),
//             _buildTextField(
//               controller: _phoneController,
//               label: 'Phone Number',
//               icon: Icons.phone,
//               keyboard: TextInputType.phone,
//               validator:
//                   (v) =>
//                       v == null || v.length < 10
//                           ? 'Enter valid phone number'
//                           : null,
//             ),

//             if (_userType == 'Farmer' || _userType == 'Distributor') ...[
//               const SizedBox(height: 16),
//               _buildTextField(
//                 controller: _locationController,
//                 label: 'Location',
//                 icon: Icons.location_on,
//                 validator:
//                     (v) =>
//                         v == null || v.isEmpty ? 'Enter your location' : null,
//                 suffix:
//                     _isGettingLocation
//                         ? const Padding(
//                           padding: EdgeInsets.all(10),
//                           child: SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(strokeWidth: 2),
//                           ),
//                         )
//                         : IconButton(
//                           icon: const Icon(Icons.my_location),
//                           onPressed: _getLocation,
//                         ),
//               ),
//             ],

//             const SizedBox(height: 16),
//             _buildTextField(
//               controller: _passwordController,
//               label: 'Password',
//               icon: Icons.lock_outline,
//               isPassword: true,
//               validator:
//                   (v) =>
//                       v == null || v.length < 6
//                           ? 'Password must be at least 6 characters'
//                           : null,
//             ),
//             const SizedBox(height: 16),
//             _buildTextField(
//               controller: _confirmPasswordController,
//               label: 'Confirm Password',
//               icon: Icons.lock_outline,
//               isPassword: true,
//               validator:
//                   (v) =>
//                       v != _passwordController.text
//                           ? 'Passwords do not match'
//                           : null,
//             ),

//             const SizedBox(height: 24),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _handleRegister,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green.shade700,
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: const Text(
//                   'Register',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Text('Already have an account?'),
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text('Sign In'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildUserTypeSelector() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Register as:',
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 12),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             _buildRoleCard(
//               title: 'Farmer',
//               icon: Icons.agriculture,
//               selected: _userType == 'Farmer',
//               onTap: () => setState(() => _userType = 'Farmer'),
//             ),
//             _buildRoleCard(
//               title: 'Distributor',
//               icon: Icons.local_shipping,
//               selected: _userType == 'Distributor',
//               onTap: () => setState(() => _userType = 'Distributor'),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildRoleCard({
//     required String title,
//     required IconData icon,
//     required bool selected,
//     required VoidCallback onTap,
//   }) {
//     return Expanded(
//       child: GestureDetector(
//         onTap: onTap,
//         child: Container(
//           margin: const EdgeInsets.symmetric(horizontal: 6),
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           decoration: BoxDecoration(
//             color: selected ? Colors.green.shade100 : Colors.white,
//             border: Border.all(
//               color: selected ? Colors.green : Colors.grey.shade300,
//               width: 2,
//             ),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Column(
//             children: [
//               Icon(icon, color: selected ? Colors.green.shade800 : Colors.grey),
//               const SizedBox(height: 8),
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontWeight: FontWeight.w600,
//                   color: selected ? Colors.green.shade800 : Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     bool isPassword = false,
//     TextInputType keyboard = TextInputType.text,
//     String? Function(String?)? validator,
//     Widget? suffix,
//   }) {
//     return TextFormField(
//       controller: controller,
//       obscureText: isPassword && !_isPasswordVisible,
//       keyboardType: keyboard,
//       validator: validator,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon),
//         suffixIcon: suffix,
//         filled: true,
//         fillColor: Colors.grey.shade100,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//     );
//   }

//   Future<void> _handleRegister() async {
//     if (_formKey.currentState!.validate()) {
//       try {
//         final email = _emailController.text;
//         final password = _passwordController.text;
//         final name = _nameController.text;
//         final phone = _phoneController.text;
//         final userType = _userType;
//         // final location = _locationController.text;
//         //_userType == 'Farmer' ? _locationController.text : null;

//         await _authService.registerWithEmailAndPassword(
//           email: email,
//           password: password,
//           name: name,
//           phone: phone,
//           userType: userType,
// // Suggested code may be subject to a license. Learn more: ~LicenseLog:751025266.
//           latitude: _latitude,
//           longitude: _longitude,
//           // location: location,
//         );

//         _navigateToHomeScreen(context);
//       } catch (e) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text(e.toString())));
//       }
//     }
//   }
// }


import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../screens/home_screen_farmer.dart';
import '../screens/home_screen_distributor.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({Key? key}) : super(key: key);

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isGettingLocation = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _userType = 'Farmer';
  double? _latitude; // Store latitude
  double? _longitude; // Store longitude

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _navigateToHomeScreen(BuildContext context) {
    final target =
        _userType == 'Farmer'
            ? const HomeScreenFarmer()
            : const HomeScreenDistributor();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => target),
      (route) => false,
    );
  }

  Future<void> _getLocation() async {
    setState(() => _isGettingLocation = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      setState(() => _isGettingLocation = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        setState(() => _isGettingLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission permanently denied.'),
        ),
      );
      setState(() => _isGettingLocation = false);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitude = position.latitude; // Store latitude
      _longitude = position.longitude; // Store longitude

      // Reverse geocoding to get human-readable address
      List<Placemark> placemarks =
          await placemarkFromCoordinates(_latitude!, _longitude!);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String fullAddress = [
          place.name,
          place.street,
          place.subLocality,
          place.locality,
          place.subAdministrativeArea,
          place.administrativeArea,
          place.postalCode,
          place.country,
        ].where((element) => element != null && element.isNotEmpty).join(', ');

        _locationController.text = fullAddress; // Show address in text field
      } else {
        _locationController.text = "${_latitude}, ${_longitude}"; // Fallback
      }
    } catch (e) {
      print("⚠️ Error fetching location or address: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $e')),
      );
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text(
              'Create Your Account',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            _buildUserTypeSelector(),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline,
              validator:
                  (v) => v == null || v.isEmpty ? 'Enter your name' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboard: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter your email';
                final emailValid = RegExp(
                  r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9]+\.[a-zA-Z]+$",
                ).hasMatch(value);
                return emailValid ? null : 'Enter a valid email';
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
              keyboard: TextInputType.phone,
              validator:
                  (v) =>
                      v == null || v.length < 10
                          ? 'Enter valid phone number'
                          : null,
            ),

            if (_userType == 'Farmer' || _userType == 'Distributor') ...[
              const SizedBox(height: 16),
              _buildTextField(
                controller: _locationController,
                label: 'Location',
                icon: Icons.location_on,
                validator:
                    (v) =>
                        v == null || v.isEmpty ? 'Enter your location' : null,
                suffix:
                    _isGettingLocation
                        ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                        : IconButton(
                          icon: const Icon(Icons.my_location),
                          onPressed: _getLocation,
                        ),
              ),
            ],

            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline,
              isPassword: true,
              validator:
                  (v) =>
                      v == null || v.length < 6
                          ? 'Password must be at least 6 characters'
                          : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              icon: Icons.lock_outline,
              isPassword: true,
              validator:
                  (v) =>
                      v != _passwordController.text
                          ? 'Passwords do not match'
                          : null,
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Register',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account?'),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Sign In'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Register as:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildRoleCard(
              title: 'Farmer',
              icon: Icons.agriculture,
              selected: _userType == 'Farmer',
              onTap: () => setState(() => _userType = 'Farmer'),
            ),
            _buildRoleCard(
              title: 'Distributor',
              icon: Icons.local_shipping,
              selected: _userType == 'Distributor',
              onTap: () => setState(() => _userType = 'Distributor'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? Colors.green.shade100 : Colors.white,
            border: Border.all(
              color: selected ? Colors.green : Colors.grey.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? Colors.green.shade800 : Colors.grey),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.green.shade800 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: keyboard,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (_userType == 'Farmer' || _userType == 'Distributor') {
        if (_latitude == null || _longitude == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fetch your location.')),
          );
          return;
        }
      }
      try {
        final email = _emailController.text;
        final password = _passwordController.text;
        final name = _nameController.text;
        final phone = _phoneController.text;
        final userType = _userType;
        // Combine latitude and longitude into a string
        final location = _latitude != null && _longitude != null
            ? "${_latitude}, ${_longitude}"
            : null;

        await _authService.registerWithEmailAndPassword(
          email: email,
          password: password,
          name: name,
          phone: phone,
          userType: userType,
          location: location,
        );

        _navigateToHomeScreen(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
}