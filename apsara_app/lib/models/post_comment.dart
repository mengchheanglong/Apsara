class PostComment {
  const PostComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.timeLabel,
  });

  final String id;
  final String userId;
  final String userName;
  final String text;
  final String timeLabel;
}
