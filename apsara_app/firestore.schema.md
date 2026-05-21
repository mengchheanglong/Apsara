# Apsara Firestore Schema

Firestore is schemaless, so this file documents the collection shape expected by the app.

## `schema/apsara`

- `version`: schema version string
- `collections`: list of main collection names
- `updatedAt`: server timestamp

## `users/{userId}`

- `displayName`: public profile name
- `email`: account email
- `bio`: short profile text
- `avatarUrl`: optional profile image URL
- `location`: user location
- `createdAt`: server timestamp
- `updatedAt`: server timestamp

## `users/{userId}/savedPosts/{postId}`

- `postId`: saved post id
- `category`: album/category label
- `savedAt`: server timestamp

## `posts/{postId}`

- `title`: post title
- `description`: post detail text
- `category`: one of the category labels except `All`
- `condition`: New, Like new, Handmade, Vintage, etc.
- `location`: pickup or seller location
- `imageUrls`: list of Firebase Storage or remote image URLs
- `price`: numeric price, nullable
- `currency`: currency code, currently `USD`
- `isForSale`: whether the listing is sellable
- `sellerUid`: Firebase Auth uid of the owner
- `sellerIdHash`: local numeric bridge used by the current Flutter mock chat model
- `sellerName`: denormalized seller display name
- `likeCount`: denormalized count
- `commentCount`: denormalized count
- `shareCount`: denormalized count
- `createdAt`: server timestamp
- `updatedAt`: server timestamp

## `posts/{postId}/comments/{commentId}`

- `userId`: commenter uid
- `userName`: denormalized display name
- `text`: comment body
- `createdAt`: server timestamp

## `posts/{postId}/likes/{userId}`

- `userId`: liker uid
- `postId`: liked post id
- `createdAt`: server timestamp

## `posts/{postId}/shares/{shareId}`

- `userId`: uid of the user who shared
- `postId`: shared post id
- `createdAt`: server timestamp

## `conversations/{conversationId}`

- `participantIds`: list of user ids
- `participantNames`: map of user id to display name
- `postId`: optional related post id
- `postTitle`: optional denormalized title
- `lastMessage`: latest message preview
- `lastMessageAt`: server timestamp
- `createdAt`: server timestamp

## `conversations/{conversationId}/messages/{messageId}`

- `senderId`: message sender uid
- `text`: message body
- `createdAt`: server timestamp
- `readBy`: list of participant ids that have read it
