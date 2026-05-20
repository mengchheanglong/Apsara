import '../models/art_post.dart';
import '../models/conversation.dart';

const categories = <String>[
  'All',
  'Silk & Textiles',
  'Wood Art',
  'Sculpture',
  'Paintings',
  'Jewelry',
  'Pottery',
  'Others',
];

const demoUploadImageUrl =
    'https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?auto=format&fit=crop&w=900&q=80';

final demoPosts = <ArtPost>[
  const ArtPost(
    id: 1,
    title: 'Apsara Wood Carving',
    seller: 'Sokha Woodworks',
    sellerId: 101,
    category: 'Wood Art',
    condition: 'Handmade',
    location: 'Siem Reap',
    imageUrl:
        'https://images.unsplash.com/photo-1606293926075-69a00dbfde81?auto=format&fit=crop&w=900&q=80',
    description:
        'Hand-carved Apsara relief inspired by temple ornamentation. Made from teak wood and finished by hand.',
    price: 120,
    likes: 128,
    comments: 12,
  ),
  const ArtPost(
    id: 2,
    title: 'Earth Motif Vase',
    seller: 'Dara Pottery',
    sellerId: 102,
    category: 'Pottery',
    condition: 'New',
    location: 'Phnom Penh',
    imageUrl:
        'https://images.unsplash.com/photo-1610701596007-11502861dcfa?auto=format&fit=crop&w=900&q=80',
    description:
        'Minimal handmade vase with carved earth motifs. Fired locally and designed for everyday home display.',
    price: 35,
    likes: 74,
    comments: 5,
  ),
  const ArtPost(
    id: 3,
    title: 'Golden Silk Scarf',
    seller: 'Bopha Silk Creations',
    sellerId: 103,
    category: 'Silk & Textiles',
    condition: 'Handmade',
    location: 'Takeo',
    imageUrl:
        'https://images.unsplash.com/photo-1523398002811-999ca8dec234?auto=format&fit=crop&w=900&q=80',
    description:
        'Soft silk scarf woven with warm red and gold tones. Lightweight, elegant, and made by local artisans.',
    price: 45,
    likes: 205,
    comments: 18,
  ),
  const ArtPost(
    id: 4,
    title: 'Silver Betel Box',
    seller: 'Channary Craft',
    sellerId: 104,
    category: 'Jewelry',
    condition: 'Vintage',
    location: 'Battambang',
    imageUrl:
        'https://images.unsplash.com/photo-1617038220319-276d3cfab638?auto=format&fit=crop&w=900&q=80',
    description:
        'Vintage-inspired silver container with detailed floral engraving. Suitable as decor or keepsake storage.',
    price: 210,
    likes: 166,
    comments: 9,
  ),
  const ArtPost(
    id: 5,
    title: 'Gold Leaf Lacquer Bowl',
    seller: 'Vanna Studio',
    sellerId: 105,
    category: 'Wood Art',
    condition: 'Handmade',
    location: 'Phnom Penh',
    imageUrl:
        'https://images.unsplash.com/photo-1612196808214-b8e1d6145a8c?auto=format&fit=crop&w=900&q=80',
    description:
        'Lacquer bowl with gold leaf details. A refined accent piece for dining rooms, shelves, or gift sets.',
    price: 85,
    likes: 91,
    comments: 4,
  ),
  const ArtPost(
    id: 6,
    title: 'Handwoven Krama Silk Scarf',
    seller: 'Sophea N.',
    sellerId: 106,
    category: 'Silk & Textiles',
    condition: 'New condition',
    location: 'Takeo',
    imageUrl:
        'https://images.unsplash.com/photo-1606760227091-3dd870d97f1d?auto=format&fit=crop&w=900&q=80',
    description:
        'Authentic, handcrafted silk Krama sourced directly from artisans. Woven using traditional techniques.',
    price: 45,
    likes: 242,
    comments: 16,
  ),
];

final demoConversations = <Conversation>[
  Conversation(
    sellerId: 101,
    sellerName: 'Sokha Woodworks',
    online: true,
    messages: const [
      ChatMessage(
        text:
            'Hello! I saw your interest in the hand-carved Apsara relief. Would you like to know more about the teak wood we use?',
        time: '10:42 AM',
        isMe: false,
      ),
      ChatMessage(
        text:
            "Yes, please! I'm curious about the aging process of the wood. Does it darken over time?",
        time: '10:43 AM',
        isMe: true,
      ),
      ChatMessage(
        text:
            'It does. It develops a beautiful deep golden patina after about 2 years.',
        time: '10:45 AM',
        isMe: false,
      ),
    ],
  ),
  Conversation(
    sellerId: 103,
    sellerName: 'Bopha Silk Creations',
    online: false,
    messages: const [
      ChatMessage(
        text: 'Thank you for your order! It has shipped.',
        time: 'Yesterday',
        isMe: false,
      ),
    ],
  ),
  Conversation(
    sellerId: 102,
    sellerName: 'Dara Pottery',
    online: true,
    messages: const [
      ChatMessage(
        text: 'Can we negotiate the price for bulk order?',
        time: 'Monday',
        isMe: true,
      ),
    ],
  ),
];
