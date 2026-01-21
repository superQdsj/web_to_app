part of '../thread_screen.dart';

class _ThreadBody extends StatelessWidget {
  const _ThreadBody({
    required this.loading,
    required this.error,
    required this.posts,
    required this.scrollController,
    required this.loadingMore,
    required this.hasMore,
    required this.loadMoreError,
    required this.onRefresh,
    required this.onLoadMore,
  });

  final bool loading;
  final String? error;
  final List<ThreadPost> posts;
  final ScrollController scrollController;
  final bool loadingMore;
  final bool hasMore;
  final String? loadMoreError;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error!,
                style: TextStyle(color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRefresh, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (posts.isEmpty) {
      return const Center(child: Text('No posts found.'));
    }

    final mainPost = posts.first;
    final replies = posts.length > 1 ? posts.sublist(1) : const <ThreadPost>[];
    final hotReplies = replies.take(2).toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (!scrollController.hasClients) {
            return false;
          }
          final position = scrollController.position;
          if (!position.hasContentDimensions ||
              position.maxScrollExtent <= 0 ||
              position.pixels <= 0) {
            return false;
          }
          const loadMoreThreshold = 200.0;
          if (position.pixels >= position.maxScrollExtent - loadMoreThreshold) {
            onLoadMore();
          }
          return false;
        },
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.only(bottom: 96),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _MainPostHeader(post: mainPost),
            const SizedBox(height: 8),
            const _PostActionsRow(),
            const SizedBox(height: 12),
            const Divider(
              height: 1,
              thickness: 1,
              color: _ThreadPalette.borderLight,
            ),
            if (hotReplies.isNotEmpty) ...[
              const SizedBox(height: 12),
              const _SectionHeader(
                icon: Icons.local_fire_department,
                title: 'Hot Replies',
                iconColor: Colors.red,
              ),
              const SizedBox(height: 12),
              ...hotReplies.map(
                (post) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ReplyCard(post: post),
                ),
              ),
            ],
            if (replies.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(
                height: 1,
                thickness: 1,
                color: _ThreadPalette.borderLight,
              ),
              const SizedBox(height: 8),
              _SectionHeader(title: 'All Replies (${replies.length})'),
              const SizedBox(height: 4),
              ...replies.map((post) => _ReplyTile(post: post)),
            ],
            if (replies.isEmpty) ...[
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'No replies yet.',
                  style: TextStyle(color: _ThreadPalette.textSecondary),
                ),
              ),
            ],
            _buildLoadMoreFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreFooter(BuildContext context) {
    if (posts.isEmpty) {
      return const SizedBox.shrink();
    }

    if (loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loadMoreError!,
              style: TextStyle(color: Colors.red.shade700),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onLoadMore, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (!hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text('没有更多了', style: TextStyle(color: Colors.black54)),
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text('上拉加载更多', style: TextStyle(color: Colors.black54)),
      ),
    );
  }
}
