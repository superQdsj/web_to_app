class ThreadPost {
  ThreadPost({
    required this.floor,
    required this.author,
    required this.authorUid,
    required this.contentText,
  });

  final int? floor;
  final String? author;
  final int? authorUid;
  final String contentText;

  Map<String, Object?> toJson() => {
        'floor': floor,
        'author': author,
        'author_uid': authorUid,
        'content_text': contentText,
      };
}

class ThreadDetail {
  ThreadDetail({
    required this.tid,
    required this.url,
    required this.fetchedAt,
    required this.posts,
  });

  final int tid;
  final String url;
  final int fetchedAt;
  final List<ThreadPost> posts;

  Map<String, Object?> toJson() => {
        'tid': tid,
        'url': url,
        'fetched_at': fetchedAt,
        'posts': posts.map((p) => p.toJson()).toList(),
      };
}
