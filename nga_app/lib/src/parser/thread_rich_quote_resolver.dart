import '../model/thread_rich_detail.dart';

class ThreadRichQuoteResolver {
  static List<ThreadRichPost> resolve(List<ThreadRichPost> posts) {
    final pidToBlocks = <int, List<ThreadContentBlock>>{};
    for (final post in posts) {
      final pid = post.pid;
      if (pid == null) continue;

      final blocks = _extractQuoteSourceBlocks(post.contentBlocks);
      if (blocks.isNotEmpty) {
        pidToBlocks[pid] = blocks;
      }
    }

    return posts
        .map((post) {
          final (updatedBlocks, changed) = _resolveBlocks(
            post.contentBlocks,
            pidToBlocks,
          );

          if (!changed) return post;
          return ThreadRichPost(
            pid: post.pid,
            floor: post.floor,
            author: post.author,
            authorUid: post.authorUid,
            contentBlocks: updatedBlocks,
            rawContent: post.rawContent,
            deviceType: post.deviceType,
            postDate: post.postDate,
          );
        })
        .toList(growable: false);
  }

  static List<ThreadContentBlock> _extractQuoteSourceBlocks(
    List<ThreadContentBlock> blocks,
  ) {
    final filtered = <ThreadContentBlock>[];
    for (final block in blocks) {
      if (block is ThreadQuoteBlock && block.blocks.isEmpty) {
        continue;
      }
      filtered.add(block);
    }
    return filtered;
  }

  static (List<ThreadContentBlock>, bool) _resolveBlocks(
    List<ThreadContentBlock> blocks,
    Map<int, List<ThreadContentBlock>> pidToBlocks,
  ) {
    var changed = false;
    final updated = <ThreadContentBlock>[];

    for (final block in blocks) {
      if (block is ThreadQuoteBlock) {
        final (resolvedChildren, childChanged) = _resolveBlocks(
          block.blocks,
          pidToBlocks,
        );
        var workingBlock = childChanged
            ? ThreadQuoteBlock(blocks: resolvedChildren, header: block.header)
            : block;

        final headerPid = workingBlock.header?.pid;
        if (headerPid != null) {
          final sourceBlocks = pidToBlocks[headerPid];
          if (sourceBlocks != null && sourceBlocks.isNotEmpty) {
            final shouldReplace =
                workingBlock.blocks.isEmpty ||
                (_hasUnbalancedUrlTags(workingBlock.blocks) &&
                    !_hasUnbalancedUrlTags(sourceBlocks));
            if (shouldReplace) {
              workingBlock = ThreadQuoteBlock(
                blocks: List<ThreadContentBlock>.from(sourceBlocks),
                header: workingBlock.header,
              );
            }
          }
        }

        if (!identical(workingBlock, block) || childChanged) {
          changed = true;
        }
        updated.add(workingBlock);
        continue;
      }

      updated.add(block);
    }

    return (updated.toList(growable: false), changed);
  }

  static bool _hasUnbalancedUrlTags(List<ThreadContentBlock> blocks) {
    final text = _flattenText(blocks);
    if (text.isEmpty) return false;

    final openCount = RegExp(
      r'\[url(?:=[^\]]+)?\]',
      caseSensitive: false,
    ).allMatches(text).length;
    final closeCount = RegExp(
      r'\[/url\]',
      caseSensitive: false,
    ).allMatches(text).length;
    return openCount > closeCount;
  }

  static String _flattenText(List<ThreadContentBlock> blocks) {
    final buffer = StringBuffer();

    void visitBlock(ThreadContentBlock block) {
      if (block is ThreadParagraphBlock) {
        for (final node in block.spans) {
          if (node is ThreadTextNode) {
            buffer.write(node.text);
          }
        }
        buffer.write('\n');
        return;
      }

      if (block is ThreadQuoteBlock) {
        for (final child in block.blocks) {
          visitBlock(child);
        }
      }
    }

    for (final block in blocks) {
      visitBlock(block);
    }

    return buffer.toString();
  }
}
