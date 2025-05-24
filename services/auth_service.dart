import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to listen to authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
   
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print(email);
      print(password);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Register with email and password, and store additional user data in Firestore
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String userType,
    String? location,
  }) async {
    try {
      // Create user with Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Store additional user data in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'userType': userType,
        'location': location, // Can be null for Distributors
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      print("Document exists: ${doc.exists}");

      if (doc.exists) {
        print("Document data: ${doc.data()}");
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching user data: $e');
    }
  }

  // Get current Firebase user
  User? get currentUser => _auth.currentUser;
}


// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/user_model.dart';

// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // Stream to listen to authentication state changes
//   Stream<User?> get authStateChanges => _auth.authStateChanges();

//   // Sign in with email and password
//   Future<UserCredential> signInWithEmailAndPassword(
//     String email,
//     String password,
//   ) async {
//     try {
//       return await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//     } on FirebaseAuthException catch (e) {
//       throw Exception(e.message);
//     }
//   }

//   // Register with email and password, and store additional user data in Firestore
//   Future<UserCredential> registerWithEmailAndPassword({
//     required String email,
//     required String password,
//     required String name,
//     required String phone,
//     required String userType,
//     Map<String, double>? location, // <-- Updated to Map
//   }) async {
//     try {
//       UserCredential userCredential = await _auth
//           .createUserWithEmailAndPassword(email: email, password: password);

//       await _firestore.collection('users').doc(userCredential.user!.uid).set({
//         'name': name,
//         'email': email,
//         'phone': phone,
//         'userType': userType,
//         'location': location != null
//             ? {
//                 'latitude': location['latitude'],
//                 'longitude': location['longitude'],
//               }
//             : null,
//         'createdAt': FieldValue.serverTimestamp(),
//       });

//       return userCredential;
//     } on FirebaseAuthException catch (e) {
//       throw Exception(e.message);
//     }
//   }

//   // Sign out
//   Future<void> signOut() async {
//     await _auth.signOut();
//   }

//   // Get current user data from Firestore
//   Future<UserModel?> getUserData(String uid) async {
//     try {
//       DocumentSnapshot doc =
//           await _firestore.collection('users').doc(uid).get();

//       if (doc.exists) {
//         return UserModel.fromFirestore(doc);
//       }
//       return null;
//     } catch (e) {
//       throw Exception('Error fetching user data: $e');
//     }
//   }

//   // Get current Firebase user
//   User? get currentUser => _auth.currentUser;
// }
