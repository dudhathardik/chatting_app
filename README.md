
# Flutter Chatting Application

This is a real-time chatting application built with Flutter and Firebase. It includes features like user authentication, real-time messaging, and push notifications.

## Features

- User authentication (Sign up, Login, Logout)
- Real-time messaging
- Push notifications
- User profile images
- Background message handling

## Technologies Used

- Flutter
- Firebase (Authentication, Firestore, Cloud Messaging, Storage)
- SharedPreferences for local storage
- flutter_local_notifications for handling local notifications

## Project Structure

- `main.dart`: The entry point of the application. It initializes Firebase and sets up the app theme.
- `auth_screen.dart`: Handles user authentication (sign up and login).
- `chat_screen.dart`: The main chat screen where users can send and receive messages.
- `local_notification_service.dart`: A service for handling local notifications.

## Setup

1. Clone the repository:
   ```
   git clone https://github.com/dudhathardik/chatting_app.git
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Set up Firebase:
   - Create a new Firebase project
   - Add your Android and iOS apps to the Firebase project
   - Download and add the `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) to the respective folders in your Flutter project
   - Enable Authentication, Firestore, and Cloud Messaging in your Firebase project

4. Run the app:
   ```
   flutter run
   ```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the [MIT License](LICENSE).

## Contact

For any queries, please open an issue on GitHub or contact the repository owner.
