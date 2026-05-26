# Phase 02 - Storage and Media Strategy

## Goal
Keep media storage simple, free-tier friendly, and consistent across the app. The chosen provider is Cloudinary using unsigned upload presets. Firebase Storage should not be used unless the project explicitly upgrades and this decision is revisited.

## Current Decision
- Use Cloudinary for all user-uploaded media.
- Use Firestore only for metadata and URLs.
- Do not store Cloudinary API secrets in Flutter code, `.env`, `.yaml`, or `pubspec.yaml`.
- Use unsigned upload preset values that are safe to compile into the client.

## Current Cloudinary Inputs
Expected build-time values:

```text
CLOUDINARY_CLOUD_NAME=<cloud name>
CLOUDINARY_UPLOAD_PRESET=<unsigned preset>
CLOUDINARY_UPLOAD_FOLDER=<folder configured in preset or accepted by unsigned upload>
```

These values are read through `String.fromEnvironment` in `CloudinaryMediaService` and passed with:

```powershell
flutter run -d "<android-device-id>" --dart-define-from-file=.env
```

## Files To Inspect
- `lib/services/cloudinary_media_service.dart`
- `lib/screens/create_post_screen.dart`
- `lib/screens/edit_post_screen.dart`
- `lib/screens/edit_profile_screen.dart`
- `lib/widgets/message_input.dart`
- `lib/services/chat_service.dart`
- `.env.example`
- `.gitignore`
- `pubspec.yaml`

## Scope
Media features that must use the same storage strategy:
- Post image upload.
- Edit post image replacement.
- Profile picture upload.
- Chat image upload.
- Save image to local gallery from post detail.

## Non-Goals
- Do not add Firebase Storage.
- Do not add a custom backend just for signed uploads in this phase.
- Do not commit real Cloudinary API secrets.
- Do not create separate Cloudinary folders unless the unsigned preset supports it reliably.

## Tasks
1. Audit media upload call sites.
   - Find every use of `CloudinaryMediaService`.
   - Confirm no `firebase_storage` dependency remains.
   - Confirm no screen directly constructs Cloudinary upload requests.

2. Harden `CloudinaryMediaService`.
   - Validate required build-time config before upload.
   - Return clear typed exceptions for config failure, network failure, non-2xx response, and missing URL.
   - Keep upload methods specific and readable:
     - `uploadPostImage`
     - `uploadProfileImage`
     - `uploadChatImage`
   - If they currently share one folder because unsigned upload folder overrides do not work, document that limitation instead of adding broken folder parameters.

3. Improve upload UX.
   - Create/edit/profile/chat uploads must show a loading state.
   - Failed upload must stop loading and show a short error message.
   - Users must be able to retry without leaving the screen.
   - Chat image upload should show local pending state and then resolved sent/failed state.

4. Clean configuration.
   - `.env.example` should contain placeholder values, not real keys or secrets.
   - `.gitignore` must ignore `.env`.
   - Do not expose `API secret` anywhere in the Flutter app.

5. Document operational setup.
   - Add or update README instructions for Cloudinary unsigned preset setup.
   - Include restrictions to reduce abuse:
     - image-only uploads
     - max file size
     - allowed formats
     - folder configured in preset when possible

## Acceptance Criteria
- All image upload paths use `CloudinaryMediaService`.
- App builds without `firebase_storage`.
- Upload failures do not crash and do not leave indefinite spinners.
- `.env.example` has no real secret values.
- `flutter analyze` and `flutter test` pass.

## Security Requirements
- Never place Cloudinary API secret in client code.
- Never place Cloudinary API secret in `.env` for Flutter builds.
- Treat Cloudinary cloud name and unsigned preset as public identifiers.
- Restrict unsigned preset in Cloudinary Console because the preset name is visible in client builds.

## Verification Commands
```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=.env
```

## Manual Android QA Checklist
- Create post with image.
- Edit post and replace image.
- Edit profile and replace avatar.
- Send chat image.
- Turn off network during upload and confirm graceful failure.
- Restore network and retry.
