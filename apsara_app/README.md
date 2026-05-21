# Apsara Flutter App

Apsara is an Android-first Flutter app for discovering, sharing, saving, and buying authentic Khmer crafts and artworks.

## Stack

- Flutter
- Firebase Authentication
- Cloud Firestore
- Cloudinary image uploads

## Core Features

- Email sign up, login, verification, and password reset
- Pinterest-style home feed with categories and search
- Create posts with Cloudinary-hosted images
- Persistent saves, likes, comments, and share tracking
- Saved posts, chat, and profile screens

## Run

```powershell
flutter pub get
flutter run -d <device-id> --dart-define-from-file=.env
```
