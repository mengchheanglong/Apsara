# Phase 03 - Architecture and Maintainability

## Goal
Make the codebase easier to understand, change, and test without creating excessive folder nesting or a large risky rewrite.

## Current Architecture
The app already has these broad layers:

```text
lib/
  app.dart
  app_shell.dart
  models/
  screens/
  services/
  theme/
  utils/
  widgets/
```

Keep this structure as the baseline. Improve organization only where files are too large, responsibilities are mixed, or repeated logic is spreading.

## Principles
- Keep folder depth shallow.
- Keep each file focused on one main responsibility.
- Prefer existing patterns before introducing new frameworks.
- Services own Firestore/Auth/Cloudinary calls.
- Screens own layout and local UI state.
- Widgets own reusable UI pieces.
- Models own typed data shapes and parsing helpers.
- Avoid moving files unless it clearly improves maintainability.

## Files To Inspect First
- `lib/app.dart`
- `lib/app_shell.dart`
- `lib/models/*.dart`
- `lib/screens/*.dart`
- `lib/services/*.dart`
- `lib/widgets/*.dart`
- `lib/theme/app_theme.dart`
- `pubspec.yaml`

## Scope
Improve:
- Large screens with mixed responsibilities.
- Service files that combine unrelated domains.
- Repeated UI patterns that should be widgets.
- Navigation paths that are duplicated or fragile.
- State handoff between shell, post detail, chat, and public profile.

## Non-Goals
- Do not rewrite the app to Riverpod or Bloc unless explicitly approved.
- Do not introduce `go_router` unless route complexity justifies it.
- Do not rename public classes casually.
- Do not move files without updating every import and running verification.

## Recommended Target Structure
Use this only where it helps. Do not force every file into a feature folder immediately.

```text
lib/
  app.dart
  app_shell.dart
  data/
  models/
  screens/
    auth_screens.dart
    home_screen.dart
    post_detail_screen.dart
    chat_screen.dart
    profile_screen.dart
  services/
    auth_service.dart
    post_service.dart
    engagement_service.dart
    saved_post_service.dart
    chat_service.dart
    profile_service.dart
    cloudinary_media_service.dart
  widgets/
    chat_bubble.dart
    chat_list_item.dart
    empty_state.dart
    form_fields.dart
    message_input.dart
    post_grids.dart
  theme/
  utils/
```

## Tasks
1. Inventory responsibilities.
   - For each screen and service, write a short note about what it owns.
   - Identify files that mix two or more unrelated domains.

2. Split only obvious large files.
   - Candidate: if a screen contains a reusable component over roughly 100 lines, move it to `widgets/`.
   - Candidate: if a service has unrelated persistence domains, split by domain.
   - Keep private widgets in the same file if they are only used by that screen and not distracting.

3. Make state ownership explicit.
   - Shared app state should live in `ApsaraShell` or a service stream.
   - One-off input state should stay inside the screen.
   - Avoid duplicating persisted state in multiple places unless there is a clear sync path.

4. Clean navigation.
   - Keep bottom-tab content as tab content.
   - If a screen is pushed as a full route, ensure it has a `Scaffold` and `Material` ancestor.
   - Avoid pushing tab-only widgets directly as standalone pages.

5. Reduce coupling.
   - Screens should call service methods through injected callbacks when the parent owns the result.
   - Services should not import screens or widgets.
   - Models should not import services or widgets.

6. Update imports and remove dead code.
   - Run `rg` for old class names and stale imports.
   - Delete unused files only after confirming no references.

## Acceptance Criteria
- No file move breaks imports.
- No screen is responsible for unrelated backend logic.
- No service mixes unrelated domains after obvious splits.
- Tab-only widgets are not pushed as standalone routes without a `Scaffold`.
- `flutter analyze` passes with no unused imports.
- `flutter test` passes.

## Verification Commands
```powershell
dart format lib
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=.env
```

## Manual QA Checklist
- Auth flow.
- Home feed and search.
- Create/edit/delete post.
- Post detail like/save/comment/share/message.
- Public profile to chat.
- Chat list, chat search, self-chat.
- Profile edit and logout.
