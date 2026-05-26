import 'package:apsara_app/models/art_post.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('priceLabel reflects sale state', () {
    const forSale = ArtPost(
      id: 1,
      title: 'Vase',
      seller: 'Maker',
      sellerId: 7,
      category: 'Pottery',
      condition: 'Handmade',
      location: '',
      imageUrl: 'https://example.com/post.jpg',
      description: 'Clay vase',
      price: 24,
    );

    const notForSale = ArtPost(
      id: 2,
      title: 'Sketch',
      seller: 'Maker',
      sellerId: 7,
      category: 'Painting',
      condition: 'Handmade',
      location: '',
      imageUrl: 'https://example.com/post.jpg',
      description: 'Ink sketch',
      price: null,
    );

    expect(forSale.isForSale, isTrue);
    expect(forSale.priceLabel, '\$24');
    expect(notForSale.isForSale, isFalse);
    expect(notForSale.priceLabel, 'Not for sale');
  });

  test('copyWith preserves existing fields and applies overrides', () {
    const original = ArtPost(
      id: 3,
      documentId: 'post_3',
      title: 'Original title',
      seller: 'Seller',
      sellerId: 8,
      sellerUid: 'user_8',
      category: 'Jewelry',
      condition: 'Vintage',
      location: 'Siem Reap',
      imageUrl: 'https://example.com/original.jpg',
      description: 'Original description',
      price: 42,
      likes: 5,
      comments: 2,
      shares: 1,
    );

    final updated = original.copyWith(
      title: 'Updated title',
      location: '',
      likes: 6,
    );

    expect(updated.id, original.id);
    expect(updated.documentId, original.documentId);
    expect(updated.title, 'Updated title');
    expect(updated.location, '');
    expect(updated.likes, 6);
    expect(updated.comments, original.comments);
    expect(updated.imageUrl, original.imageUrl);
  });
}
