# Phase 07 - Quality, Testing, and Observability

## Goal
Increase confidence that the app keeps working as features are added. Add practical tests and lightweight observability without slowing down development.

## Current Baseline
- Flutter widget test exists.
- Manual Android testing is the primary verification method.
- Firebase Auth and Firestore are live.
- Cloudinary is used for media.
- No dedicated crash reporting is required yet unless approved.

## Scope
Improve:
- Automated checks.
- Unit tests for service logic where possible.
- Widget tests for stable screens.
- Manual QA checklist.
- Release verification.
- Lightweight logs for critical actions.

## Non-Goals
- Do not add heavy analytics tracking without approval.
- Do not add paid monitoring tools unless approved.
- Do not write brittle screenshot tests for frequently changing UI.

## Files To Inspect
- `test/`
- `analysis_options.yaml`
- `pubspec.yaml`
- `lib/services/*`
- `lib/screens/*`
- `firestore.rules`
- `README.md`

## Required Automated Checks
Run these locally before handing off changes:

```powershell
dart format lib test
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=.env
```

If Firestore rules changed:

```powershell
firebase deploy --only firestore:rules
```

## Test Coverage Targets
1. Unit-level tests where logic is pure.
   - `ArtPost` computed fields.
   - Search filtering helpers if extracted.
   - Like state helpers if extracted.
   - Room ID generation if exposed in a testable way.

2. Widget tests for stable UI.
   - Login screen renders.
   - Saved empty state renders count and empty message.
   - Basic post detail action row renders with liked/saved states.
   - Chat empty state renders.

3. Service tests.
   - Prefer emulator-backed tests only if Firebase emulator setup is documented.
   - Do not mock Firestore with fragile fake maps unless the test adds clear value.

## Observability Requirements
Add lightweight logs only for failures and critical funnel actions:
- Firebase initialization failure.
- Auth failure.
- Cloudinary config missing.
- Cloudinary upload failure.
- Post create/update/delete failure.
- Like/save transaction failure.
- Chat send failure.

Use a small logging wrapper if needed. Do not scatter unstructured `print` calls everywhere.

## Release Checklist
Before sharing an APK:
- Confirm `.env` exists locally and is not committed.
- Run `flutter pub get`.
- Run `flutter analyze`.
- Run `flutter test`.
- Run `flutter build apk --debug --dart-define-from-file=.env`.
- Run on Android physical device.
- Test auth, feed, post detail, create post, edit profile, saved, chat, and logout.

## Acceptance Criteria
- Core checks pass reliably.
- New tests cover important logic without being brittle.
- Manual QA checklist is documented and current.
- Failure logs are useful but do not expose secrets.
- No real API secrets are committed.

## Manual Android QA Checklist
- Fresh launch signed out.
- Login.
- Email verification path if applicable.
- Home feed loads.
- Search posts and users.
- Category empty state.
- Create post with image.
- Edit post.
- Like/unlike repeatedly.
- Save/unsave.
- Comment and open commenter profile.
- Public profile to chat.
- Chat text and image send.
- Self-chat.
- Android back behavior in chat.
- Logout.

## Handoff Format For Future Codex Runs
When assigning work to an AI coding model, include:
- The phase spec path.
- The exact bug or feature request.
- Current device ID if Android testing is required.
- Whether Firestore rules may be deployed.
- Required verification commands.
- Any user-facing copy constraints.
