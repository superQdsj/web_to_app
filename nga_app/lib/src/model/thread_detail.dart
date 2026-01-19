class ThreadPost {
  ThreadPost({
    required this.floor,
    required this.author,
    required this.authorUid,
    required this.contentText,
    this.deviceType,
  });

  final int? floor;
  final ThreadPostAuthor? author;
  final int? authorUid;
  final String contentText;
  final String? deviceType;

  Map<String, Object?> toJson() => {
        'floor': floor,
    'author': author?.toJson(),
        'author_uid': authorUid,
        'content_text': contentText,
    'device_type': deviceType,
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
