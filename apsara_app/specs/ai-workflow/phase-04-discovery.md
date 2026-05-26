# Phase 04 - Discovery and Search

## Goal
Improve how users find posts and people while keeping the implementation simple enough for the current Firestore-backed app.

## Current Behavior
- Home feed shows posts from `PostService.watchPosts()`.
- Category chips filter the feed locally.
- Search screen receives the current post list and searches post fields.
- Search also has user results inferred from seller data in posts.
- Chat tab has a people search for existing chats and self-chat.

## Scope
Improve:
- Home search quality.
- User search quality.
- Category filtering.
- Empty states for searches and categories.
- Feed ordering and diversity.

## Non-Goals
- Do not build a recommendation engine requiring a backend server.
- Do not use external search services in this phase.
- Do not add complex ML ranking.
- Do not perform expensive Firestore reads on every keystroke.

## Files To Inspect
- `lib/screens/home_screen.dart`
- `lib/screens/search_screen.dart`
- `lib/screens/chat_screen.dart`
- `lib/widgets/post_grids.dart`
- `lib/data/categories.dart`
- `lib/models/art_post.dart`
- `lib/services/post_service.dart`
- `lib/services/profile_service.dart`
- `firestore.indexes.json`
- `firestore.schema.md`

## Search Requirements
Home search should support:
- Post title.
- Post description.
- Category.
- Condition.
- Location.
- Seller name.
- User profile result when seller name matches.

Chat search should support:
- Existing chat peer display name.
- Self-chat when the current user's name matches.
- Live profile name updates where available.

## UX Requirements
- Keep search input compact and consistent with app theme.
- Do not show a large marketing-style search page.
- Show user results before post results when the query matches people.
- Use short empty states:
  - `No matching posts or users found.`
  - `No matching chats`
- Avoid bold text for low-priority metadata.

## Tasks
1. Normalize searchable text.
   - Trim and lowercase query.
   - Search across relevant post fields.
   - Avoid null crashes for optional fields.

2. Improve user results.
   - Deduplicate users by UID.
   - Prefer live `users/{uid}` profile data when available.
   - Fall back to seller name/avatar from post metadata.
   - Tapping a user result opens `PublicUserProfileScreen`.

3. Improve post results.
   - Keep masonry/grid display.
   - Preserve `onOpenPost` behavior.
   - Do not include mock/static posts.

4. Improve category behavior.
   - Category chips should stay visually low emphasis.
   - Empty category state should be simple:
     - icon
     - `No <category> posts yet`
   - Do not add extra card wrappers for empty states.

5. Optional v1 ranking.
   - Keep default feed ordered by Firestore `createdAt` descending unless implementing a clear local sort.
   - If adding ranking, use only local lightweight signals:
     - recency
     - category match
     - liked/saved count
   - Keep ranking deterministic within one refresh.

## Acceptance Criteria
- Home search finds both posts and users.
- Chat search finds existing chat peers and the current user self-chat.
- Empty states are clear and not visually heavy.
- No static mock posts appear in the feed.
- Search does not trigger excessive Firestore reads per keystroke.
- `flutter analyze` and `flutter test` pass.

## Verification Commands
```powershell
flutter analyze
flutter test
```

## Manual Android QA Checklist
- Search by post title.
- Search by seller name.
- Search by category such as `Pottery`.
- Search by description keyword.
- Open a user result.
- Open a post result.
- Search Messages by another user's name.
- Search Messages by your own name and open self-chat.
