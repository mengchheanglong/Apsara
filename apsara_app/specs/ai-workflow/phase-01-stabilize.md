# Phase 01 - Stabilize Core Android Flows

## Goal
Make the current Android app reliable before adding larger features. Focus on fixing crashes, broken state sync, confusing loading/error states, and regressions in the core marketplace flows.

## Project Context
- App: Apsara, an Android-first Flutter marketplace for Khmer crafts.
- Frontend: Flutter Material 3.
- Backend: Firebase Auth and Cloud Firestore.
- Media: Cloudinary unsigned uploads through `CloudinaryMediaService`. Do not introduce Firebase Storage.
- Important entry points:
  - `lib/app.dart`
  - `lib/app_shell.dart`
  - `lib/screens/auth_screens.dart`
  - `lib/screens/home_screen.dart`
  - `lib/screens/post_detail_screen.dart`
  - `lib/screens/create_post_screen.dart`
  - `lib/screens/chat_screen.dart`
  - `lib/services/*`
  - `firestore.rules`

## Scope
Stabilize these flows:
- App startup and Firebase initialization.
- Login, register, forgot password, email verification, logout.
- Home feed loading and category filtering.
- Post detail open/close, like/unlike, save/unsave, comment, share.
- Create post and edit post with Cloudinary image upload.
- Chat list, chat room, self-chat, message send, image send, Android back behavior.
- Public profile and profile-to-chat navigation.

## Non-Goals
- Do not redesign the whole app.
- Do not migrate storage provider.
- Do not add a new state management framework unless a specific bug cannot be solved locally.
- Do not change Firestore document shapes unless the spec explicitly requires it and rules are updated.

## Tasks
1. Reproduce current failures.
   - Run `flutter analyze`.
   - Run `flutter test`.
   - Run the app on Android with `--dart-define-from-file=.env`.
   - Exercise the flows listed in Scope and record any crashes or obvious broken states.

2. Audit startup and auth.
   - Confirm `Firebase.initializeApp` failure path shows a useful screen.
   - Confirm verified users reach `ApsaraShell`.
   - Confirm unverified password users reach `VerifyEmailScreen`.
   - Confirm forgot password does not call UI updates after dispose.

3. Audit feed and post detail state.
   - Confirm `PostService.watchPosts()` updates the feed without blank flicker.
   - Confirm `PostDetailSheet` local state stays synchronized for save and like actions while the sheet remains open.
   - Confirm like state persists across app restart and does not require reopening the post to toggle again.
   - Confirm location does not default to `Cambodia`; blank location displays as `No location`.

4. Audit media upload error handling.
   - Confirm missing Cloudinary env values show clear user-facing errors.
   - Confirm failed create/edit/profile/chat image uploads do not leave spinners stuck.
   - Confirm retrying after an upload failure is possible without restarting the app.

5. Audit chat stability.
   - Confirm chat list does not flash messages and then disappear.
   - Confirm chat search filters by user name.
   - Confirm self-chat can be opened and messages persist.
   - Confirm Android back from inside a chat room returns to the chat list, not the app launcher.
   - Confirm profile-to-chat opens with a `Scaffold` or other valid `Material` ancestor.

6. Add defensive UI states where missing.
   - Add empty, loading, and error states that match `AppColors`.
   - Prefer inline retry buttons for recoverable failures.
   - Keep copy short and user-facing.

## Implementation Notes
- Prefer small fixes in the owning screen/service.
- Keep service methods deterministic. For example, use `setLiked(post, liked)` instead of inferring intent from a stale widget state.
- When changing Firestore paths or rules, update both app code and `firestore.rules`.
- Avoid broad refactors in this phase.

## Acceptance Criteria
- No red-screen Flutter exceptions in the listed flows.
- Like/unlike works repeatedly inside the same open post sheet.
- Saved and liked state persists after app restart.
- Chat list and chat room navigation work from bottom tab and public profile.
- Cloudinary failures show actionable messages and do not freeze the UI.
- `flutter analyze` passes.
- `flutter test` passes.

## Verification Commands
Run from `C:\Users\User\Internship\Apsara\apsara_app`:

```powershell
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=.env
flutter run -d "<android-device-id>" --dart-define-from-file=.env
```

If Firestore rules changed:

```powershell
firebase deploy --only firestore:rules
```

## Manual Android QA Checklist
- Launch app while signed out.
- Register or log in.
- Open a post, like/unlike several times without closing it.
- Close app fully, reopen, confirm liked heart still shows.
- Save/unsave a post and check Saved tab count.
- Create a post with and without location.
- Edit a post and clear location.
- Open public profile, tap chat icon, send text.
- Search chat by another user name and own name.
- Press Android back inside chat room.
