import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nga_app/src/parser/thread_parser.dart';

void main() {
  test('Hybrid Parser should extract rich metadata from nga_debug.html', () {
    final file = File('../private/nga_debug.html');
    if (!file.existsSync()) {
      throw Exception(' nga_debug.html not found, skipping test.');
    }
    final html = file.readAsStringSync();

    final parser = ThreadParser();
    final detail = parser.parseThreadPage(
      html,
      tid: 46023232,
      url: 'https://bbs.nga.cn/read.php?tid=46023232',
      fetchedAt: DateTime.now().millisecondsSinceEpoch,
    );

    expect(detail.posts.isNotEmpty, isTrue);

    // Floor 0
    final p0 = detail.posts[0];
    expect(p0.author?.username, 'yhm31');
    expect(p0.author?.uid, 39748236);
    expect(p0.deviceType, '7 iOS');
    expect(p0.author?.wowCharacter?.name, '玛拉吉斯');
    expect(p0.author?.wowCharacter?.realm, '主宰之剑');

    // Floor 1
    final p1 = detail.posts[1];
    expect(p1.author?.username, '自挂东北枝');
    expect(p1.deviceType, '0 /'); 
  });
}
