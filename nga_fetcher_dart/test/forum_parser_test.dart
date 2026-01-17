import 'package:nga_fetcher_dart/nga_fetcher_dart.dart';
import 'package:test/test.dart';

void main() {
  test('parses thread list rows', () {
    const html = """
<!doctype html>
<html>
  <body>
    <table id='topicrows'>
      <tr class='row1 topicrow'>
        <td class='c1'><a class='replies' href='/read.php?tid=123'>10</a></td>
        <td class='c2'><a class='topic' href='/read.php?tid=123'>Hello</a></td>
        <td class='c3'><a class='author' href='/nuke.php?func=ucp&uid=42'>alice</a>
          <span class='silver postdate'>1700000000</span>
        </td>
        <td class='c4'><span class='replyer'>bob</span></td>
      </tr>
    </table>
  </body>
</html>
""";

    final items = ForumParser().parseForumThreadList(html);
    expect(items, hasLength(1));
    expect(items.first.tid, 123);
    expect(items.first.title, 'Hello');
    expect(items.first.replies, 10);
    expect(items.first.author, 'alice');
    expect(items.first.authorUid, 42);
    expect(items.first.postTs, 1700000000);
    expect(items.first.lastReplyer, 'bob');
  });
}
