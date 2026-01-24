/// 引用的帖子信息
class QuotedPost {
  QuotedPost({
    this.pid,
    this.tid,
    this.authorUid,
    this.authorName,
    this.postTime,
    required this.quotedText,
  });

  final int? pid;
  final int? tid;
  final int? authorUid;
  final String? authorName;
  final String? postTime;
  final String quotedText;

  Map<String, Object?> toJson() => {
    'pid': pid,
    'tid': tid,
    'author_uid': authorUid,
    'author_name': authorName,
    'post_time': postTime,
    'quoted_text': quotedText,
  };
}

class ThreadPost {
  ThreadPost({
    this.pid,
    required this.floor,
    required this.author,
    required this.authorUid,
    required this.contentText,
    this.deviceType,
    this.postDate,
    this.quotedPost,
    this.replyContent,
  });

  final int? pid;
  final int? floor;
  final ThreadPostAuthor? author;
  final int? authorUid;
  final String contentText;
  final String? deviceType;
  final String? postDate;

  /// 被引用的帖子（如果这是一个回复帖）
  final QuotedPost? quotedPost;

  /// 回复内容（去掉引用后的纯回复文本）
  final String? replyContent;

  Map<String, Object?> toJson() => {
    'pid': pid,
    'floor': floor,
    'author': author?.toJson(),
    'author_uid': authorUid,
    'content_text': contentText,
    'device_type': deviceType,
    'post_date': postDate,
    'quoted_post': quotedPost?.toJson(),
    'reply_content': replyContent,
  };
}

class ThreadPostAuthor {
  ThreadPostAuthor({
    required this.uid,
    required this.username,
    required this.regdate,
    required this.postnum,
    required this.rvrc,
    required this.money,
    this.avatar,
    this.medal,
    this.reputation,
    this.honor,
    this.signature,
    this.nickname,
    this.wowCharacter,
  });

  final int uid;
  final String username;
  final int regdate;
  final int postnum;
  final double rvrc;
  final int money;
  final String? avatar;
  final String? medal;
  final String? reputation;
  final String? honor;
  final String? signature;
  final String? nickname;
  final WowCharacter? wowCharacter;

  Map<String, Object?> toJson() => {
    'uid': uid,
    'username': username,
    'regdate': regdate,
    'postnum': postnum,
    'rvrc': rvrc,
    'money': money,
    'avatar': avatar,
    'medal': medal,
    'reputation': reputation,
    'honor': honor,
    'signature': signature,
    'nickname': nickname,
    'wow_character': wowCharacter?.toJson(),
  };
}

class WowCharacter {
  WowCharacter({
    required this.name,
    required this.realm,
    required this.race,
    required this.characterClass,
    required this.faction,
    required this.level,
    required this.itemLevel,
    required this.achievementPoints,
    required this.gender,
    required this.classId,
  });

  final String name;
  final String realm;
  final String race;
  final String characterClass;
  final String faction;
  final int level;
  final int itemLevel;
  final int achievementPoints;
  final String gender;
  final String classId;

  Map<String, Object?> toJson() => {
    'name': name,
    'realm': realm,
    'race': race,
    'class': characterClass,
    'faction': faction,
    'level': level,
    'item_level': itemLevel,
    'achievement_points': achievementPoints,
    'gender': gender,
    'class_id': classId,
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
