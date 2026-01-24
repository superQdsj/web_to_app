import 'thread_detail.dart';

sealed class ThreadContentBlock {
  const ThreadContentBlock();
}

class ThreadParagraphBlock extends ThreadContentBlock {
  const ThreadParagraphBlock({required this.spans});

  final List<ThreadInlineNode> spans;
}

class ThreadQuoteBlock extends ThreadContentBlock {
  const ThreadQuoteBlock({required this.spans});

  final List<ThreadInlineNode> spans;
}

class ThreadImageBlock extends ThreadContentBlock {
  const ThreadImageBlock({required this.url});

  final String url;
}

sealed class ThreadInlineNode {
  const ThreadInlineNode();
}

class ThreadTextNode extends ThreadInlineNode {
  const ThreadTextNode({
    required this.text,
    this.bold = false,
    this.deleted = false,
  });

  final String text;
  final bool bold;
  final bool deleted;
}

class ThreadEmoteNode extends ThreadInlineNode {
  const ThreadEmoteNode({required this.code});

  final String code;
}

class ThreadRichPost {
  ThreadRichPost({
    this.pid,
    required this.floor,
    required this.author,
    required this.authorUid,
    required this.contentBlocks,
    required this.rawContent,
    this.deviceType,
    this.postDate,
  });

  final int? pid;
  final int? floor;
  final ThreadPostAuthor? author;
  final int? authorUid;
  final List<ThreadContentBlock> contentBlocks;
  final String rawContent;
  final String? deviceType;
  final String? postDate;
}

class ThreadRichDetail {
  ThreadRichDetail({
    required this.tid,
    required this.url,
    required this.fetchedAt,
    required this.posts,
  });

  final int tid;
  final String url;
  final int fetchedAt;
  final List<ThreadRichPost> posts;
}
