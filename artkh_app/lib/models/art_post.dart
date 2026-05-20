class ArtPost {
  const ArtPost({
    required this.id,
    required this.title,
    required this.seller,
    required this.sellerId,
    required this.category,
    required this.condition,
    required this.location,
    required this.imageUrl,
    required this.description,
    this.price,
    this.likes = 0,
    this.comments = 0,
  });

  final int id;
  final String title;
  final String seller;
  final int sellerId;
  final String category;
  final String condition;
  final String location;
  final String imageUrl;
  final String description;
  final double? price;
  final int likes;
  final int comments;

  bool get isForSale => price != null && price! > 0;

  String get priceLabel => isForSale ? '\$${price!.toStringAsFixed(0)}' : 'Not for sale';

  ArtPost copyWith({
    int? id,
    String? title,
    String? seller,
    int? sellerId,
    String? category,
    String? condition,
    String? location,
    String? imageUrl,
    String? description,
    double? price,
    int? likes,
    int? comments,
  }) {
    return ArtPost(
      id: id ?? this.id,
      title: title ?? this.title,
      seller: seller ?? this.seller,
      sellerId: sellerId ?? this.sellerId,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      price: price ?? this.price,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
    );
  }
}
