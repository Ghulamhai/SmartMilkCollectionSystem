Dairy Connect - Smart Milk Collection System
Overview
Dairy Connect is an Android app developed to streamline rural milk logistics in India. Built with Flutter and Firebase, it connects dairy farmers and distributors, optimizing collection routes, enabling real-time price comparisons, and supporting offline functionality for rural users. The app addresses inefficiencies in milk collection, enhances market access for farmers, and promotes digital inclusion.
Features

Account Management: Register and log in as a farmer or distributor.
Price Comparison: Farmers compare distributor prices to schedule pickups.
Route Optimization: Distributors get optimized routes for milk collection.
Transaction Tracking: Monitor milk quantities, earnings, and statistics.
Offline Support: Works in low-connectivity rural areas.

Tech Stack

Frontend: Flutter (Dart)
Backend: Firebase (Firestore, Authentication, Cloud Functions)
Route Optimization: Likely Google OR-Tools (assumed for route planning)
Location Services: Android Location API


Set Up Firebase:
Create a Firebase project at Firebase Console.
Add an Android app and download google-services.json.
Place google-services.json in android/app/.
Enable Firestore, Authentication (Email, Google), and Cloud Functions.


Run the App:flutter run



Usage

Farmers: Sign up, compare distributor prices, schedule pickups, and track transactions via the dashboard.
Distributors: Log in, manage pickup requests, optimize routes, update prices, and view statistics.
Screenshots: Key screens include signup, login, farmer dashboard, price comparison, route navigation, and transaction stats.

Project Structure

lib/: Flutter source code
screens/: UI screens (e.g., login, dashboard)
services/: Firebase and API integrations
models/: Data models(e.g. user, pickup)


android/: Android-specific configurations
assets/: Images and other static resources

Contributing

Fork the repository.
Create a feature branch (git checkout -b feature/your-feature).
Commit changes (git commit -m "Add your feature").
Push to the branch (git push origin feature/your-feature).
Open a pull request.

Future Enhancements
Integrate machine learning for milk quantity and price predictions.
Add real-time alerts for weather or urgent requests.

Team
MD Rizwan Ahmad (2024AIM1005)
Ghulam Haider (2024CSM1008)
Yash Narnaware (2024AIM100)
Mudasir Nazir Khan (2024CSM1006)

License
This project is licensed under the MIT License - see the LICENSE file for details.
