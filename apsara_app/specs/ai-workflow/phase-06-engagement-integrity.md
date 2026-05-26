# Phase 06 - Engagement Integrity

## Goal
Keep likes, saves, comments, and shares accurate, persistent, and responsive while reducing obvious counter drift and abuse risk.

## Current Firestore Shapes
Post document:

```text
posts/{postId}
  likeCount: int
  commentCount: int
  shareCount: int
```

Like documents:

```text
posts/{postId}/likes/{userId}
users/{userId}/likedPosts/{postId}
```

Saved documents:

```text
users/{userId}/savedPosts/{postId}
```

Comments:

```text
posts/{postId}/comments/{commentId}
```

Shares:

```text
posts/{postId}/shares/{shareId}
```

## Scope
Improve:
- Like/unlike state.
- Save/unsave state.
- Comment create and display.
- Share count.
- Counter consistency.
- Firestore rules for engagement paths.

## Non-Goals
- Do not add a moderation dashboard.
- Do not add Cloud Functions unless approved.
- Do not add heavy rate-limiting that blocks normal usage.

## Files To Inspect
- `lib/services/engagement_service.dart`
- `lib/services/saved_post_service.dart`
- `lib/screens/post_detail_screen.dart`
- `lib/screens/comments_screen.dart`
- `lib/app_shell.dart`
- `firestore.rules`
- `firestore.schema.md`

## Required Behavior
1. Likes.
   - One user can like a post once.
   - Tapping again unlikes the post.
   - User can like/unlike repeatedly while the same post detail sheet stays open.
   - Red heart state persists after app restart.
   - Count cannot go below zero.
   - Use explicit target state such as `setLiked(post, liked)` instead of ambiguous toggle behavior.

2. Saves.
   - Save state persists after app restart.
   - Saved tab count updates when saving/unsaving.
   - If a post is deleted, it should disappear from Saved.

3. Comments.
   - Comment author name and avatar should reflect the current user profile where possible.
   - Tapping comment author opens public profile.
   - Empty comments state should be simple.

4. Shares.
   - Share action records a share event.
   - Share count increments only after share intent succeeds enough for app purposes.

5. Rules.
   - Users can only write their own like and saved docs.
   - Post owners and comment authors have appropriate comment permissions.
   - Counter updates must remain non-negative.

## Implementation Guidance
- Prefer Firestore transactions for like count changes.
- Keep a per-user mirror collection for fast startup state:
  - `users/{uid}/likedPosts/{postId}`
  - `users/{uid}/savedPosts/{postId}`
- If legacy docs exist only under `posts/{postId}/likes/{uid}`, add a fallback read so old likes still display.
- Avoid collection group queries if a simpler user-owned mirror exists.

## Acceptance Criteria
- Like count and red heart stay in sync.
- Repeated like/unlike taps work without closing the sheet.
- Liked state is correct after app restart.
- Saved state is correct after app restart.
- Comments show current profile identity where available.
- `flutter analyze` and `flutter test` pass.
- Firestore rules deploy successfully if changed.

## Verification Commands
```powershell
flutter analyze
flutter test
firebase deploy --only firestore:rules
```

## Manual Android QA Checklist
- Like a post, close and reopen post, confirm red heart.
- Kill app, reopen, confirm red heart.
- Unlike, confirm count decreases.
- Like/unlike repeatedly inside the same open sheet.
- Save/unsave repeatedly.
- Delete a post that was saved and confirm Saved tab updates.
- Add comment and tap commenter profile.
