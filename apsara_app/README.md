# Apsara Flutter App

Apsara is an Android-first Flutter app for discovering, sharing, saving, and buying authentic Khmer crafts and artworks.

## Stack

- Flutter
- Firebase Authentication
- Cloud Firestore
- Cloudinary image uploads

## Storage decision

- All user-uploaded media goes through Cloudinary.
- Firestore stores metadata and media URLs.
- Firebase Storage is not used in this app.
- Cloudinary API secrets must not be placed in Flutter build inputs.

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

## Cloudinary setup

1. Create an unsigned upload preset in Cloudinary.
   - Restrict to image-only uploads.
   - Set a max file size.
   - Limit allowed formats such as `jpg`, `png`, and `webp`.
   - Configure a default folder if needed.
2. Copy `.env.example` to `.env` and set:
   - `CLOUDINARY_CLOUD_NAME`
   - `CLOUDINARY_UPLOAD_PRESET`
   - `CLOUDINARY_UPLOAD_FOLDER`
3. Keep API secrets out of `.env` because Flutter build values are public.
4. If the unsigned preset does not reliably support per-feature folders, keep one app-level folder and separate media logically in Firestore instead of forcing broken folder overrides.

## Verification

```powershell
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=.env
```
