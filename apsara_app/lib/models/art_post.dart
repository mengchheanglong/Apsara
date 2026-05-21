class ArtPost {
  const ArtPost({
    required this.id,
    this.documentId,
    required this.title,
    required this.seller,
    required this.sellerId,
    this.sellerUid,
    required this.category,
    required this.condition,
    required this.location,
    required this.imageUrl,
    required this.description,
    this.price,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
  });

  final int id;
  final String? documentId;
  final String title;
  final String seller;
  final int sellerId;
  final String? sellerUid;
  final String category;
  final String condition;
  final String location;
  final String imageUrl;
  final String description;
  final double? price;
  final int likes;
  final int comments;
  final int shares;

  String get storageId => documentId ?? id.toString();

  bool get isForSale => price != null && price! > 0;

  String get priceLabel =>
      isForSale ? '\$${price!.toStringAsFixed(0)}' : 'Not for sale';

  ArtPost copyWith({
    int? id,
    String? documentId,
    String? title,
    String? seller,
    int? sellerId,
    String? sellerUid,
    String? category,
    String? condition,
    String? location,
    String? imageUrl,
    String? description,
    double? price,
    int? likes,
    int? comments,
    int? shares,
  }) {
    return ArtPost(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      title: title ?? this.title,
      seller: seller ?? this.seller,
      sellerId: sellerId ?? this.sellerId,
      sellerUid: sellerUid ?? this.sellerUid,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      price: price ?? this.price,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
    );
  }
}
