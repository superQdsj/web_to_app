class ThreadItem {
  ThreadItem({
    required this.tid,
    required this.url,
    required this.title,
    required this.replies,
    required this.author,
    required this.authorUid,
    required this.postTs,
    required this.lastReplyer,
  });

  final int tid;
  final String url;
  final String title;
  final int? replies;
  final String? author;
  final int? authorUid;
  final int? postTs;
  final String? lastReplyer;

  Map<String, Object?> toJson() => {
    'tid': tid,
    'url': url,
    'title': title,
    'replies': replies,
    'author': author,
    'author_uid': authorUid,
    'post_ts': postTs,
    'last_replyer': lastReplyer,
  };
}
