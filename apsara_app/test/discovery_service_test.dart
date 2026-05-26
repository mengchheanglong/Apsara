import 'package:apsara_app/models/art_post.dart';
import 'package:apsara_app/services/discovery_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const pottery = ArtPost(
    id: 1,
    documentId: 'pottery_1',
    title: 'Clay Jar',
    seller: 'Seller A',
    sellerId: 1,
    category: 'Pottery',
    condition: 'Handmade',
    location: 'Phnom Penh',
    imageUrl: 'https://example.com/jar.jpg',
    description: 'Jar',
    price: 15,
    likes: 5,
    comments: 2,
    shares: 1,
  );

  const silk = ArtPost(
    id: 2,
    documentId: 'silk_1',
    title: 'Silk Scarf',
    seller: 'Seller B',
    sellerId: 2,
    category: 'Silk & Textiles',
    condition: 'New',
    location: 'Siem Reap',
    imageUrl: 'https://example.com/scarf.jpg',
    description: 'Scarf',
    price: 12,
    likes: 1,
    comments: 0,
    shares: 0,
  );

  const wood = ArtPost(
    id: 3,
    documentId: 'wood_1',
    title: 'Wood Carving',
    seller: 'Seller C',
    sellerId: 3,
    category: 'Wood Art',
    condition: 'Vintage',
    location: '',
    imageUrl: 'https://example.com/wood.jpg',
    description: 'Carving',
    price: null,
    likes: 2,
    comments: 1,
    shares: 0,
  );

  test('rankPosts boosts categories the user already liked or saved', () {
    final ranked = DiscoveryService.rankPosts(
      posts: const [silk, wood, pottery],
      likedPostIds: const {'pottery_1'},
      savedPostIds: const {'pottery_1'},
    );

    expect(ranked.first.storageId, 'pottery_1');
  });
}
